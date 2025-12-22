import 'package:flutter/material.dart';

class RememberMeCheckbox extends StatefulWidget {
  final ValueChanged<bool> onChanged;
  final bool initialValue;

  const RememberMeCheckbox({
    Key? key,
    required this.onChanged,
    this.initialValue = false,
  }) : super(key: key);

  @override
  _RememberMeCheckboxState createState() => _RememberMeCheckboxState();
}

class _RememberMeCheckboxState extends State<RememberMeCheckbox> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: _value,
          onChanged: (bool? newValue) {
            setState(() {
              _value = newValue!;
              widget.onChanged(_value);
            });
          },
        ),
        Text('Remember me'),
      ],
    );
  }
}