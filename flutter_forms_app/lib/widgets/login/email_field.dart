import 'package:flutter/material.dart';
import '../../utils/validators.dart';

class EmailField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;

  const EmailField({
    Key? key,
    required this.controller,
    this.focusNode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'Email',
        prefixIcon: Icon(Icons.email),
        border: OutlineInputBorder(),
      ),
      validator: Validators.validateEmail,
    );
  }
}