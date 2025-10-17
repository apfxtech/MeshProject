// lib/widgets/search.dart
import 'package:flutter/material.dart';

class SearchWidget extends StatelessWidget {
  final String labelText;
  final ValueChanged<String> onChanged;

  const SearchWidget({
    super.key,
    required this.labelText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8, left: 16, right: 16),
      child: TextField(
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
          prefixIcon: const Icon(Icons.search),
        ),
        onChanged: onChanged,
      ),
    );
  }
}