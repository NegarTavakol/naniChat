import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/userAuth.dart';


class SignUpTab extends StatefulWidget {
  const SignUpTab({Key? key}) : super(key: key);

  @override
  State<SignUpTab> createState() => _SignUpTabState();
}

class _SignUpTabState extends State<SignUpTab> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _birthYearController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();

  bool shouldShowResend = false;



  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserAuth, UserAuthState>(
      listener: (context, state) {
        if (state.isLoggedIn) {
          Navigator.pushReplacementNamed(context, '/chatScreen');
        } else if (state.error.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error)),
          );
        }
      },
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nicknameController,
                decoration: const InputDecoration(labelText: 'Nickname'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _birthYearController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Birth Year'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final email = _emailController.text.trim();
                  final password = _passwordController.text.trim();
                  final birthYear = int.tryParse(_birthYearController.text.trim()) ?? 0;
                  final nickname = _nicknameController.text.trim();


                  context.read<UserAuth>().signUp(
                    email :email,
                    password :password,
                    birthYear :birthYear,
                    nickname : nickname,
                  );
                  setState(() {
                    shouldShowResend = true;
                  });
                },
                child: const Text('Sign Up'),
              ),
              if (shouldShowResend)
                TextButton(
                  onPressed: () async {
                    final user = context.read<UserAuth>().firebaseAuth.currentUser;
                    if (user != null && !user.emailVerified) {
                      await user.sendEmailVerification();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Verification email re-sent. Please check your inbox."),
                      ));
                    }
                  },
                  child: const Text("Resend Verification Email"),
                ),
              const SizedBox(height: 16),
              if (state.isLoading) const CircularProgressIndicator(),
            ],
          ),
        );
      },
    );
  }
}
