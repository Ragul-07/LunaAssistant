import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'setup_screen.dart';
import 'home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(LunaAssistant());
}

class LunaAssistant extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        bool isFirstTime = snapshot.data?.getBool('isFirstTime') ?? true;

        return MaterialApp(
          title: 'Luna Assistant',
          debugShowCheckedModeBanner: false,
          home: isFirstTime ? SetupScreen() : HomeScreen(),
        );
      },
    );
  }
}
