import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Profil Mahasiswa')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.account_circle, size: 72),
              SizedBox(height: 16),
              Text('Fadhil Taufiqurrachman', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), 
              SizedBox(height: 8),
              Text('NIM : 244107020090', style: TextStyle(fontSize: 14, decoration: TextDecoration.underline)),
              SizedBox(height: 4),
              Text('Email : fadhiltaufiqurrachman08@gmail.com', style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey)),
              SizedBox(height: 16),
              Text('Pemrograman Mobile – Minggu 1', style: TextStyle(fontSize: 16)),
          ]),
        ),
      ),
    );
  }
}