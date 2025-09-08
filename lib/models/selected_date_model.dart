import 'package:flutter/material.dart';

class SelectedDateShift {
  final DateTime? date;
  final String? shift;

  SelectedDateShift({this.date, this.shift});

  SelectedDateShift copyWith({DateTime? date, String? shift}) {
    return SelectedDateShift(
      date: date ?? this.date,
      shift: shift ?? this.shift,
    );
  }
}
