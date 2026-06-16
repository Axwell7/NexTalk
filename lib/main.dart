import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'controllers/theme_controller.dart';

final ThemeController themeController =
    ThemeController();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options:
        DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const NexTalkApp());
}

class NexTalkApp extends StatelessWidget {
  const NexTalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (_, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'NexTalk',

          themeMode:
              themeController.themeMode,

          theme: ThemeData(
            brightness: Brightness.light,

            primaryColor:
                const Color(0xFF3CCB6C),

            scaffoldBackgroundColor:
                Colors.white,

            appBarTheme:
                const AppBarTheme(
              backgroundColor:
                  Color(0xFF3CCB6C),
              foregroundColor:
                  Colors.white,
            ),
          ),

          darkTheme: ThemeData(
            brightness: Brightness.dark,

            scaffoldBackgroundColor:
                const Color(0xFF121212),

            cardColor:
                const Color(0xFF1E1E1E),

            appBarTheme:
                const AppBarTheme(
              backgroundColor:
                  Color(0xFF1E1E1E),
              foregroundColor:
                  Colors.white,
            ),
          ),

          home: const AuthGate(),
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream:
          FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child:
                  CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}