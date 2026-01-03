import 'package:flutter/material.dart';

class Note extends StatelessWidget {
  const Note({super.key, required this.text});
  final String text;
  @override
  build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 30),
      child: Text(text),
    );
  }
}
