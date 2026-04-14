import 'package:flutter/material.dart';

class CreditsScreen extends StatelessWidget {
  static const routeName = '/credits';
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Credits')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Illustrations by Storyset (Freepik)\nhttps://storyset.com',
        ),
      ),
    );
  }
}
