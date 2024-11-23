import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class CustomTextField1 extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData icon;
  final bool isNumeric;
  final bool isEmail;
  final int maxLines;
  final VoidCallback onIconPressed;
  final bool readOnly;
  final String? Function(String?)? validator;
  final bool enabled;

  const CustomTextField1({
    super.key,
    required this.controller,
    required this.labelText,
    required this.icon,
    this.isNumeric = false,
    this.isEmail = false,
    this.maxLines = 1,
    required this.onIconPressed,
    this.readOnly = false,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: GoogleFonts.poppins(
            color: const Color(0xFF1C59D2).withOpacity(0.7),
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF1C59D2),
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: const Color(0xFF1C59D2).withOpacity(0.5),
                  ),
                  onPressed: () => controller.clear(),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: const Color(0xFF1C59D2).withOpacity(0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: const Color(0xFF1C59D2).withOpacity(0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF1C59D2),
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Colors.red,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 2,
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        ),
        style: GoogleFonts.poppins(
          color: Colors.black,
        ),
        keyboardType: isNumeric
            ? TextInputType.phone
            : (isEmail ? TextInputType.emailAddress : TextInputType.text),
        inputFormatters: isNumeric
            ? [
                LengthLimitingTextInputFormatter(13),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  if (!newValue.text.startsWith('+63')) {
                    return const TextEditingValue(
                      text: '+63',
                      selection: TextSelection.collapsed(offset: 3),
                    );
                  }

                  final numberOnly = newValue.text.substring(3);
                  if (numberOnly.isNotEmpty &&
                      !RegExp(r'^\d+$').hasMatch(numberOnly)) {
                    return oldValue;
                  }

                  if (numberOnly.length > 10) {
                    return oldValue;
                  }

                  return newValue;
                }),
              ]
            : null,
        maxLines: maxLines,
        validator: (value) {
          if (isNumeric) {
            if (value == null || value.isEmpty || value == '+63') {
              return 'Please enter your contact number';
            }
            final numberOnly = value.replaceAll('+63', '').trim();
            if (numberOnly.length < 10) {
              return 'Please enter 10 digits after +63';
            }
          }
          return null;
        },
        readOnly: readOnly,
      ),
    );
  }
}
