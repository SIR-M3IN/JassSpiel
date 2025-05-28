import 'package:flutter/material.dart';

class CreatePage extends StatelessWidget {
  const CreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create'),
      ),
      body: Center(
        child: Text(
          'Create Page',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}