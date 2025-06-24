import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';




import 'cubit/userAuth.dart';
import 'firebase_options.dart';
import 'helper/content_filter.dart';
import 'src/loginScreen.dart';
import 'welcomeScreen.dart';


void main() async{

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
  );
  print("Firebase initialized");
  await ContentFilter.loadBannedWordsFromJson();
  runApp(
      BlocProvider(
        create:(_) => UserAuth(),
          child: NaniChat()));
}

class NaniChat extends StatelessWidget {


  const NaniChat({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      supportedLocales: const [
        Locale('en'),   // English
        Locale('fa'),   // Farsi
        Locale('tr'),   // Turkish
        Locale('ar'),   // Arabic
        Locale('ru'),   // Russian
        Locale('fr'),   // French
        Locale('es'),   // Spanish
        Locale('it'),   // Italian
        Locale('de'),   // German
      ],

      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/auth': (context) => const LoginScreen(),
      },
    );
  }
}