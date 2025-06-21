import 'package:flutter/material.dart';
import 'package:nanichat/helper/signUp_Tab.dart';

import '../helper/signIn_Tab.dart';


class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Welcome"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Sign In"),
              Tab(text: "Sign Up"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            SignInTab(),
            SignUpTab(),
          ],
        ),
      ),
    );
  }
}

