import 'package:flutter/material.dart';

class CreateAdminScreen extends StatelessWidget {
  const CreateAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Admin Account')),
      body: const Center(child: Text('Create Admin Form Here')),
    );
  }
}

