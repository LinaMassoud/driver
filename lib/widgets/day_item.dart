import 'package:flutter/material.dart';

class DayItem extends StatelessWidget {
  final String day;
  final String date;
  final bool selected;

  const DayItem({
    super.key,
    required this.day,
    required this.date,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          day,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF05ABD7) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(8),
          child: Text(
            date,
            style: TextStyle(
              fontSize: 12,
              color: selected ? Colors.white : Color(0xFF9EA5A6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
