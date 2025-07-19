import 'package:flutter/material.dart';

class DropdownFormMenuField<T> extends StatefulWidget {
  final List<DropdownMenuItem<T>>? dItems;
  final BorderSide? border;
  final String iHint;
  final Widget? isuffixIcon;
  final Widget? iprefix;
  final T? value;
  final void Function(T?)? onChanged;

  const DropdownFormMenuField({
    super.key,
    this.dItems,
    this.border,
    required this.iHint,
    this.isuffixIcon,
    this.iprefix,
    this.value,
    this.onChanged,
  });

  @override
  State<DropdownFormMenuField<T>> createState() => _DropdownFormMenuFieldState<T>();
}

class _DropdownFormMenuFieldState<T> extends State<DropdownFormMenuField<T>> {
  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: widget.value,
      items: widget.dItems,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderSide: widget.border ?? BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: widget.border ?? BorderSide.none,
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: widget.border ?? BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: widget.border ?? BorderSide.none,
        ),
        counterText: "",
        hintText: widget.iHint,
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        suffixIcon: widget.isuffixIcon,
        prefixIcon: widget.iprefix,
      ),
    );
  }
}



