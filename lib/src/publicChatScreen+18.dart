import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../helper/content_filter.dart';
import '../helper/device_info.dart';

class PublicChatScreenUpper18 extends StatefulWidget {
  final bool isUnder18;
  const PublicChatScreenUpper18({super.key, required this.isUnder18});

  @override
  State<PublicChatScreenUpper18> createState() => _PublicChatScreenUpper18State();
}

class _PublicChatScreenUpper18State extends State<PublicChatScreenUpper18> {
  final TextEditingController _messageControllerPublicUpper18 = TextEditingController();
  final userId = FirebaseAuth.instance.currentUser!.uid;
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final statusRef = FirebaseDatabase.instance.ref('status/upper18/');
  final publicChatUpper18 = FirebaseDatabase.instance.ref('chatMessages/publicUpper18/');
  final ScrollController _scrollControllerUpper18 = ScrollController();

  //making ban wrongdoer user
  Future<void> banUser(String userId) async {
    print("🔍 banning user: $userId");

    final banRef = FirebaseDatabase.instance.ref('bannedUsers/$userId');
    final snapshot = await banRef.get();

    int newStrikeCount = 1;
    int banDurationMillis = 5 * 60 * 1000; // default: 5 min

    if (snapshot.exists && snapshot.value != null) {
      try {
        final data = Map<String, dynamic>.from((snapshot.value as Map<dynamic, dynamic>));
        final currentStrikeCount = int.tryParse(data['strikeCount'].toString()) ?? 0;
        print("Current strike: $currentStrikeCount");

        newStrikeCount = currentStrikeCount + 1;

        if (newStrikeCount == 2) {
          banDurationMillis = 12 * 60 * 60 * 1000; // 12 hours
        } else if (newStrikeCount >= 3) {
          banDurationMillis = 999 * 365 * 24 * 60 * 60 * 1000; // Permanent
        }
      } catch (e) {
        print("⚠️ Error parsing strikeCount: $e");
      }
    }

    final bannedUntil = DateTime.now().millisecondsSinceEpoch + banDurationMillis;

    await banRef.set({
      'strikeCount': newStrikeCount,
      'bannedUntil': bannedUntil,
    });

    print("✅ banned set: strike $newStrikeCount");
  }



  void _sendPublicMessageUpper18() async {
    final publicTextUpper18 = _messageControllerPublicUpper18.text.trim();
    if (publicTextUpper18.isEmpty) return;

    // ✅ 1 -control ban user
    final banSnap = await FirebaseDatabase.instance.ref('bannedUsers/$userId').get();
    if (banSnap.exists) {
      final banData = Map<String, dynamic>.from(banSnap.value as Map);
      final bannedUntil = banData['bannedUntil'] ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (now < bannedUntil) {
        final remainingSeconds = ((bannedUntil - now) / 1000).round();
        final minutes = (remainingSeconds / 60).floor();
        final seconds = remainingSeconds % 60;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🚫 You are banned for $minutes min $seconds sec.')),
        );
        return;
      } else {
        await FirebaseDatabase.instance.ref('bannedUsers/$userId').remove();
      }
    }

    await ContentFilter.loadBannedWordsFromJson();

    // ✅ 2. control forbidden words on the message
    if (ContentFilter.hasBadWords(publicTextUpper18)) {
      await banUser(userId);
      final found = ContentFilter.findBannedWords(publicTextUpper18).join(', ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🚫 Message contains banned word(s): "$found". You are now banned.')),
      );
      return;
    }

    // ✅ 3.getting nickname and sending message
    final nicknameSnap = await FirebaseDatabase.instance.ref('users/$userId/nickname').get();
    final nickname = nicknameSnap.value ?? 'Unknown';

    final refPublicTextUpper18 = FirebaseDatabase.instance.ref('chatMessages/publicUpper18');
    refPublicTextUpper18.push().set({
      'userId': userId,
      'nickname': nickname,
      'text': publicTextUpper18,
      'timestamp': ServerValue.timestamp,
    });

    _messageControllerPublicUpper18.clear();
  }




  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor:Colors.transparent,
          elevation: 0,
          title: const Text("🌐 Public Chat", style: TextStyle(color: Colors.white)),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF37474F), Color(0xFF263238)],
            ),
          ),
          child: Column(
            children: [
              // Online users and messages row
              Expanded(
                child: Row(
                  children: [
                    // Online users
                    SizedBox(
                      width: 120,
                      child: StreamBuilder(
                        stream: statusRef.onValue,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                            return const Center(child: Text("Loading..."));
                          }

                          final raw = snapshot.data!.snapshot.value;
                          if (raw is! Map) {
                            return const Center(child: Text("Invalid status data"));
                          }

                          final statusMap = raw as Map;
                          final onlineUsers = statusMap.entries
                              .where((entry) {
                            final userData = entry.value;
                            return userData is Map &&
                                userData['status'] == 'online' &&
                                entry.key.toString() != currentUserId;
                          })
                              .toList(); // List<MapEntry>

                          if (onlineUsers.isEmpty) {
                            return const Center(child: Text("No one is online"));
                          }

                          return ListView.builder(

                            itemCount: onlineUsers.length,
                            itemBuilder: (context, index) {
                              final entry = onlineUsers[index]; // MapEntry
                              final userId = entry.key.toString();
                              final nickname = (entry.value as Map)['nickname'] ?? 'User';

                              return ListTile(
                                dense: true,
                                title: Text(
                                  nickname,
                                  style: const TextStyle(fontSize: 12 , color: Colors.white),
                                ),
                                leading: const Icon(Icons.circle, color: Colors.green),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    // Chat messages
                    Expanded(
                      child: StreamBuilder(
                        stream: publicChatUpper18.orderByChild('timestamp').onValue,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                            return const Center(child: Text("No messages yet..."));
                          }
                          final data = snapshot.data!.snapshot.value as Map;
                          final messages = data.entries.toList()
                            ..sort((a, b) => (a.value['timestamp'] as int)
                                .compareTo(b.value['timestamp'] as int));

                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_scrollControllerUpper18.hasClients) {
                              _scrollControllerUpper18.animateTo(
                                _scrollControllerUpper18.position.maxScrollExtent,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            }
                          });

                          return ListView.builder(
                            controller:  _scrollControllerUpper18 ,
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final msg = messages[index].value;
                              final senderId = msg['userId'];
                              final nickname = msg['nickname'] ?? senderId.toString().substring(0, 6); // fallback
                              final text = msg['text'];
                              final isCurrentUser = senderId == currentUserId;
                              final displayName = isCurrentUser ? 'you' : nickname;

                              return Align(
                                alignment: isCurrentUser
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isCurrentUser ? Colors.indigoAccent : Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                            boxShadow: [
                                                BoxShadow(
                                                   color: Colors.black26,
                                                   blurRadius: 4,
                                                   offset: Offset(1, 2),
                                      )
                                 ]
                              ),
                                  child: Text(
                                    "$displayName: $text",
                                    style: TextStyle(
                                      color: isCurrentUser
                                          ? Colors.white
                                          : Colors.black,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Message input
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageControllerPublicUpper18,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: "Type your message...",
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    //button for writing message and sending
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(14),
                      ),
                      onPressed: widget.isUnder18 ? null : _sendPublicMessageUpper18,
                      child: const Text("Send"),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
