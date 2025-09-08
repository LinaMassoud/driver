// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get home => 'الرئيسية';

  @override
  String get chooseDay => 'اختر اليوم';

  @override
  String get today => 'اليوم';

  @override
  String get tomorrow => 'غدًا';

  @override
  String get customDate => 'تاريخ مخصص';

  @override
  String get languageTitle => 'اللغة';

  @override
  String get save => 'حفظ';

  @override
  String get languageSaved => 'تم حفظ اللغة';

  @override
  String get appPermission => 'صلاحيات التطبيق';

  @override
  String get language => 'اللغة';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get chooseShiftType => 'اختر نوع الشيفت';

  @override
  String get go => 'اذهب';

  @override
  String get back => 'عودة';

  @override
  String get failedToFetchShifts => 'فشل في جلب الشيفتات';
}
