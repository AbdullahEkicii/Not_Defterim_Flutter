import 'dart:async';

import 'package:flutter/material.dart';
import 'package:not_defteri/screens/main_screen.dart';
import 'package:not_defteri/screens/note_list_screen.dart';
import 'package:not_defteri/database/database_helper.dart';
import 'package:not_defteri/screens/timer_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper().database;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Not Defteri',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
