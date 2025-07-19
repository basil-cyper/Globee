import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InputWidget extends StatefulWidget {
  final TextEditingController? icontroller;
  final TextInputFormatter? iformatter;
  final Function(String)? ichanged;
  final TextInputType? ikeyboardType;
  final Widget? isuffixIcon;
  final int? iMaxLength;
  final bool? isDisabled;
  final String? iInit;
  final String? iHint;
  final String? Function(String?)? iValid;
  final Widget? iprefix;
  final bool? isRead;
  final Function()? iTap;
  final FocusNode? focusNode;
  final TextAlign? iAlign;
  final BorderSide? border;
  final EdgeInsetsGeometry? iPad;
  const InputWidget({
    super.key,
    this.icontroller,
    this.iformatter,
    this.ichanged,
    this.ikeyboardType,
    this.isuffixIcon,
    this.iMaxLength,
    this.isDisabled,
    this.iInit,
    this.iValid,
    this.iHint,
    this.iprefix,
    this.isRead,
    this.iTap,
    this.focusNode,
    this.iAlign,
    this.border,
    this.iPad,
  });

  @override
  State<InputWidget> createState() => _InputWidgetState();
}

class _InputWidgetState extends State<InputWidget> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      focusNode: widget.focusNode,
      onTap: widget.iTap,
      readOnly: widget.isRead ?? false,
      initialValue: widget.iInit,
      // inputFormatters: [widget.iformatter],
      validator: widget.iValid,
      enabled: widget.isDisabled,
      keyboardType: widget.ikeyboardType,
      maxLength: widget.iMaxLength,
      onChanged: widget.ichanged,
      cursorColor: Color(0xFF4F67FF),
      controller: widget.icontroller,
      textAlign: widget.iAlign ?? TextAlign.start,
      decoration: InputDecoration(
        contentPadding: widget.iPad,
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
        fillColor: Color(0xFFF7F7F7),
        suffixIcon: widget.isuffixIcon,
        prefixIcon: widget.iprefix,
      ),
    );
  }
}
