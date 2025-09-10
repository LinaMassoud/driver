import 'package:driver/models/selected_date_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectedDateShiftNotifier extends StateNotifier<SelectedDateShift> {
  SelectedDateShiftNotifier() : super(SelectedDateShift());

  void setDate(DateTime date) {
    state = state.copyWith(date: date);
  }

  void setShift(String shift) {
    state = state.copyWith(shift: shift);
  }

  void reset() {
    state = SelectedDateShift();
  }
}

final selectedDateShiftProvider =
    StateNotifierProvider<SelectedDateShiftNotifier, SelectedDateShift>(
      (ref) => SelectedDateShiftNotifier(),
    );
