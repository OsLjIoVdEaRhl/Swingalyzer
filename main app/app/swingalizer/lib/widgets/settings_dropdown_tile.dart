import 'package:flutter/material.dart';

class SettingsDropdownTile<T> extends StatelessWidget {
  final String title;
  final T value;
  final List<T> options;
  final ValueChanged<T?> onChanged;
  final IconData? icon;
  final Color? panelColor;

  const SettingsDropdownTile({
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
    this.icon,
    this.panelColor,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bgColor = panelColor ?? const Color(0xFF0D2F22);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            if (icon != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(icon, color: const Color(0xFF7BE39A), size: 28),
              ),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            DropdownButton<T>(
              value: value,
              items: options
                  .map((o) => DropdownMenuItem<T>(
                        value: o,
                        child: Text(
                          o.toString(),
                          style: const TextStyle(color: Colors.black),
                        ),
                      ))
                  .toList(),
              onChanged: onChanged,
              underline: const SizedBox(),
              dropdownColor: Colors.grey[800],
              iconEnabledColor: const Color(0xFF7BE39A),
            ),
          ],
        ),
      ),
    );
  }
}