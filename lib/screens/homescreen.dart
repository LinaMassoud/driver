import 'package:driver/l10n/app_localizations.dart';
import 'package:driver/providers/driver_info_provider.dart';
import 'package:driver/providers/language_provider.dart';
import 'package:driver/widgets/date_card.dart';
import 'package:driver/widgets/day_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

// For Arabic
const Map<int, String> arabicDayInitials = {
  1: "إ", // Monday -> الإثنين
  2: "ث", // Tuesday -> الثلاثاء
  3: "ر", // Wednesday -> الأربعاء
  4: "خ", // Thursday -> الخميس
  5: "ج", // Friday -> الجمعة
  6: "س", // Saturday -> السبت
  7: "أ", // Sunday -> الأحد
};

// For English
const Map<int, String> englishDayInitials = {
  1: "M",
  2: "T",
  3: "W",
  4: "T",
  5: "F",
  6: "S",
  7: "S",
};

// For Urdu (example)
const Map<int, String> urduDayInitials = {
  1: "پ", // Monday - پیر
  2: "ا", // Tuesday - منگل
  3: "ب", // Wednesday - بدھ
  4: "ج", // Thursday - جمعرات
  5: "و", // Friday - جمعہ
  6: "ہ", // Saturday - ہفتہ
  7: "ات", // Sunday - اتوار
};

class HomePage extends ConsumerWidget {
  const HomePage({super.key});
  String getDayInitial(DateTime date, String localeCode) {
    final weekday = date.weekday; // 1 = Monday, 7 = Sunday
    switch (localeCode) {
      case 'ar':
        return arabicDayInitials[weekday]!;
      case 'ur':
        return urduDayInitials[weekday]!;
      default:
        return englishDayInitials[weekday]!;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider); // 🔹 watch selected language
    final loc = AppLocalizations.of(context)!; // 🔹 get localized strings

    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final dateFormatter = DateFormat("dd-MM-yyyy", locale.languageCode);

    return Scaffold(
      backgroundColor: const Color(0xfff5f8fe),
      drawer: _buildDrawer(context, loc),
      body: SafeArea(
        child: Column(
          children: [
            Stack(
              children: [
                // Calendar background
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromRGBO(30, 73, 160, 0.2),
                        offset: const Offset(0, 4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.only(
                    top: 80,
                    bottom: 16,
                    left: 16,
                    right: 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Month row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_left),
                            onPressed: () {},
                            iconSize: 24,
                          ),
                          Text(
                            DateFormat(
                              "MMMM",
                              locale.languageCode,
                            ).format(today), // 🔹 localized month
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_right),
                            onPressed: () {},
                            iconSize: 24,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Week row
                      Flexible(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: List.generate(7, (index) {
                            final date = today.add(Duration(days: index));
                            final dayLabel = getDayInitial(
                              date,
                              locale.languageCode,
                            );

                            return DayItem(
                              day: dayLabel,
                              date: DateFormat(
                                'd',
                                locale.languageCode,
                              ).format(date),
                              selected: index == 0,
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),

                // Header floating on top
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFF05ABD7),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(
                              Icons.menu,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                        ),
                        Text(
                          loc.home, // 🔹 localized "Home"
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 28),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Choose Day Title
            Container(
              alignment: locale.languageCode == 'ar'
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                loc.chooseDay, // localized label
                textAlign: locale.languageCode == 'ar'
                    ? TextAlign.right
                    : TextAlign.left,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Today Card
            DateCard(
              label: loc.today, // 🔹 localized "Today"
              day: DateFormat("dd", locale.languageCode).format(today),
              date: dateFormatter.format(today),
              onTap: () => showShiftPopup(context, today),
            ),

            // Tomorrow Card
            DateCard(
              label: loc.tomorrow, // 🔹 localized "Tomorrow"
              day: DateFormat("dd", locale.languageCode).format(tomorrow),
              date: dateFormatter.format(tomorrow),
              onTap: () => showShiftPopup(context, today),
            ),
            const SizedBox(height: 20),

            // Custom Date Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 80,
                child: ElevatedButton(
                  onPressed: () async {
                    final selectedDate = await showCustomCalendarPopup(
                      context,
                      ref,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF05ABD7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    loc.customDate, // 🔹 localized "Custom Date"
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Drawer Widget
  Drawer _buildDrawer(BuildContext context, AppLocalizations loc) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Consumer(
            builder: (context, ref, _) {
              final driverInfoAsync = ref.watch(driverInfoProvider);
              return driverInfoAsync.when(
                data: (driverInfo) => Text(
                  driverInfo.driverUsername ?? 'Driver',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('Driver'),
              );
            },
          ),
          const SizedBox(height: 20),
          _drawerItem(context, loc.home, "assets/icons/home.svg"),
          _drawerItem(
            context,
            loc.appPermission,
            "assets/icons/permission.svg",
          ),
          _drawerItem(
            context,
            loc.language, // 🔹 localized "Language"
            "assets/icons/language.svg",
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/language');
            },
          ),
          _drawerItem(context, loc.logout, "assets/icons/logout.svg"),
          const Spacer(),
          _drawerItem(
            context,
            loc.deleteAccount,
            "assets/icons/delete.svg",
            textColor: Colors.red,
            iconColor: Colors.red,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context,
    String title,
    String iconPath, {
    Color textColor = Colors.black,
    double iconSize = 21,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: SvgPicture.asset(
          iconPath,
          height: iconSize,
          color: iconColor ?? const Color.fromRGBO(5, 171, 215, 1),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  Future<void> showCustomCalendarPopup(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final locale = ref.watch(languageProvider);
    DateTime? selectedDate;

    await showDialog(
      context: context,
      builder: (context) {
        final today = DateTime.now();
        final daysToShow = List.generate(
          30,
          (index) => today.add(Duration(days: index)),
        );

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(0),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF05ABD7),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "Choose Date",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Flexible(
                  child: GridView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                        ),
                    itemCount: daysToShow.length,
                    itemBuilder: (context, index) {
                      final day = daysToShow[index];
                      return GestureDetector(
                        onTap: () {
                          selectedDate = day;
                          Navigator.pop(context);
                          showShiftPopup(context, selectedDate!);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF05ABD7),
                              width: 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                DateFormat(
                                  'd',
                                  locale.languageCode,
                                ).format(day),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                DateFormat('E', locale.languageCode)
                                    .format(day)
                                    .substring(0, 1), // or use initials map
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> showShiftPopup(BuildContext context, DateTime date) async {
    String selectedShift = "Morning";

    // Map each shift to its corresponding SVG
    final shiftIcons = {
      "Morning": "assets/icons/1.svg",
      "Evening": "assets/icons/2.svg",
      "Full Day": "assets/icons/3.svg",
    };

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Choose Shift Type",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              ...["Morning", "Evening", "Full Day"].map((shift) {
                final isSelected = selectedShift == shift;
                return GestureDetector(
                  onTap: () => selectedShift = shift,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF80D9F2)
                          : Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF05ABD7)
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SvgPicture.asset(
                              shiftIcons[shift]!,
                              width: 24,
                              height: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              shift,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        // Custom radio button
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: Colors.grey.shade400,
                              width: .5,
                            ),
                          ),
                          child: Center(
                            child: isSelected
                                ? Container(
                                    width: 18, // smaller inner circle
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF05ABD7),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: .5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 10,
                                    ),
                                  )
                                : Container(
                                    width: 14, // smaller gray inner circle
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: Handle Go action with selectedDate & selectedShift
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF05ABD7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text("Go"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text("Back"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
