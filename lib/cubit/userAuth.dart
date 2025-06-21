import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


import '../helper/device_info.dart';




class UserAuthState {

final bool isLoading ;
final bool isLoggedIn;
final String email;
final int birthYear;
final String deviceId;
final String error;
final String nickname;

const UserAuthState({
  this.birthYear = 2000,
  this.email = '',
  this.nickname = '',
  this.error = '',
  this.deviceId = '',
  this.isLoading = false,
  this.isLoggedIn = false,
});

UserAuthState copyWith({
  bool? isLoading,
  bool? isLoggedIn,
  String? email,
  String? nickname,
  int? birthYear ,
  String? deviceId,
  String? error,
}) {
  return UserAuthState(
    isLoading: isLoading ?? this.isLoading,
    isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    email: email ?? this.email,
    nickname: nickname ?? this.nickname,
    birthYear: birthYear?? this.birthYear,
    deviceId: deviceId?? this.deviceId,
    error: error?? this.error,
  );
}
}

class UserAuth extends Cubit<UserAuthState>{

  UserAuth() : super(const UserAuthState());

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  FirebaseAuth get firebaseAuth => _auth;




  Future<void> setUserOnlineStatus(String userId, int birthYear, String nickname) async {
    final currentYear = DateTime.now().year;
    final isUnder18 = currentYear - birthYear < 18;

    final statusPath = isUnder18 ? 'status/under18/$userId' : 'status/upper18/$userId';

    final statusRef = _db.child(statusPath);

    await statusRef.onDisconnect().set({
      'status': 'offline',
      'last_changed': ServerValue.timestamp,
    });

    await statusRef.set({
      'status': 'online',
      'last_changed': ServerValue.timestamp,
      'nickname': nickname,
    });
  }


  Future<void> signUp({
    required String email,
    required String password,
    required String nickname,
    int? birthYear,
  }) async {
    emit(state.copyWith(isLoading: true, error: ''));

    try {
      // Get current device's ID and encode it
      final rawDeviceId = await getDeviceId();
      final encodedDeviceId = encodeDeviceId(rawDeviceId);

      // Check if device is already blocked
      final blockedSnapshot = await _db.child('blockedIps/$encodedDeviceId').get();
      if (blockedSnapshot.exists) {
        emit(state.copyWith(
          isLoading: false,
          error: 'You are not allowed to create an account from this device.',
        ));
        return;
      }

      // Check user's age
      final currentYear = DateTime.now().year;
      if (birthYear != null && (currentYear - birthYear) < 13) {
        // Block device if underage
        await _db.child('blockedIps/$encodedDeviceId').set(true);

        emit(state.copyWith(
          isLoading: false,
          error: 'You must be at least 13 years old to sign up.',
        ));
        return;
      }

      // Register user
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final user = userCredential.user!;
      final userId = user.uid;

      // Send email verification
      await user.sendEmailVerification();

      // Save user data in Realtime Database
      await _db.child('users/$userId').set({
        'email': email,
        'birthYear': birthYear,
        'deviceId': encodedDeviceId,
        'nickname': nickname,
      });

      emit(state.copyWith(
        isLoading: false,
        isLoggedIn: false, // Still false because user hasn't verified email
        email: email,
        birthYear: birthYear,
        deviceId: encodedDeviceId,
        error: 'Verification email sent. Please confirm your email.',
      ));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        emit(state.copyWith(isLoading: false, error: 'This email is already registered.'));
      } else {
        emit(state.copyWith(isLoading: false, error: 'Auth Error: ${e.message}'));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Unexpected error: ${e.toString()}'));
    }
  }




  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(isLoading: true, error: ''));

    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user!;
      if (!user.emailVerified) {
        emit(state.copyWith(
          isLoading: false,
          error: 'Please verify your email before signing in.',
        ));
        return;
      }

      var userId = user.uid;

      final snapshot = await _db.child('users/$userId').get();
      final userData = snapshot.value as Map;

      // step1: find current device's ip
      final rawDeviceId = await getDeviceId();
      final currentDeviceId = encodeDeviceId(rawDeviceId);
      final savedDeviceId = userData['deviceId'];
      print(("currentDeviceId : $currentDeviceId , savedDeviceId : $savedDeviceId"));


      // step2: compare between 2 id
      if (savedDeviceId != null && savedDeviceId != currentDeviceId) {
        emit(state.copyWith(
          isLoading: false,
          error: 'This account is already active on another device.',
        ));
        return;
      }
      // set online status for current user
      print("userId : $userId");

      await setUserOnlineStatus(
        userId,
        userData['birthYear'] ?? 2000,
        userData['nickname'] ?? 'Anonymous',
      );


      emit(state.copyWith(
        isLoading: false,
        isLoggedIn: true,
        email: email,
        nickname: userData['nickname'] ?? '',
        birthYear: userData['birthYear'] ?? 2000,
        deviceId: userData['deviceId'] ?? '',
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}


