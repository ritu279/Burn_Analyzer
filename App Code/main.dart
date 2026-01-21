import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const BurnAId());
}

class BurnAId extends StatelessWidget {
  const BurnAId({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'burnAId',
        theme: ThemeData(
          primarySwatch: Colors.teal,
          scaffoldBackgroundColor: const Color(0xFFF5F5F5),
          textTheme: Theme.of(context).textTheme.apply(
            bodyColor: Colors.teal[900],
            displayColor: Colors.teal[900],
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        debugShowCheckedModeBanner: false,
        home: const HomeScreen(),
    );
  }
}
