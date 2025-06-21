import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


import '../cubit/userAuth.dart';
import '../src/publicChatScreen+18.dart';
import '../src/publicChatScreen-18.dart';

class SignInTab extends StatefulWidget {
  const SignInTab({super.key});

  @override
  State<SignInTab> createState() => _SignInTabState();
}

class _SignInTabState extends State<SignInTab> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserAuth, UserAuthState>(
        listener: (context, state) {
          if (state.isLoggedIn) {
            final currentYear = DateTime.now().year;
            final isUnder18 = currentYear - state.birthYear < 18;



            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => isUnder18
                    ? PublicChatScreenUnder18(isUnder18: isUnder18)
                    : PublicChatScreenUpper18(isUnder18: isUnder18),
              ),
            );
          } else if (state.error.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("❌ ${state.error}")),
            );
          }
        },

      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _resetPassword,
                  child: const Text("Forgot Password?"),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  context.read<UserAuth>().signIn(
                    email: _emailController.text.trim(),
                    password: _passwordController.text.trim(),
                  );
                },
                child: const Text("Sign In"),
              ),
              const SizedBox(height: 16),
              if (state.isLoading) const CircularProgressIndicator(),
            ],
          ),
        );
      },
    );
  }

  void _resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your email first.")),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset email sent. Check your inbox.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ ${e.toString()}")),
      );
    }
  }
}
