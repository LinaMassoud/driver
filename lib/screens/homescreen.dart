import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import 'package:driver/widgets/date_card.dart';
import 'package:driver/widgets/day_item.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final dateFormatter = DateFormat("dd-MM-yyyy");

    return Scaffold(
      backgroundColor: const Color(0xfff5f8fe),
      drawer: _buildDrawer(context), // 🔹 Drawer added
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
                    mainAxisSize:
                        MainAxisSize.min, // important to avoid overflow
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
                            DateFormat("MMMM").format(today),
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
                            final dayLabel = DateFormat(
                              'E',
                            ).format(date).substring(0, 1);
                            return DayItem(
                              day: dayLabel,
                              date: DateFormat('d').format(date),
                              selected: index == 0,
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),

                // Header floating on top remains the same
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
                        const Text(
                          "Home",
                          style: TextStyle(
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
              alignment: Alignment.centerLeft,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: const Text(
                "Choose Day",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),

            const SizedBox(height: 10),

            // Today Card
            DateCard(
              label: "Today",
              day: DateFormat("dd").format(today),
              date: dateFormatter.format(today),
            ),

            // Tomorrow Card
            DateCard(
              label: "Tomorrow",
              day: DateFormat("dd").format(tomorrow),
              date: dateFormatter.format(tomorrow),
            ),
            const SizedBox(height: 20),

            // Custom Date Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 80,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Implement custom date action
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF05ABD7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Custom Date",
                    style: TextStyle(
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
  Drawer _buildDrawer(BuildContext context) {
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
          const Text(
            "Lina Massoud",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          _drawerItem("Home", "assets/icons/home.svg"),
          _drawerItem("App Permission", "assets/icons/permission.svg"),
          _drawerItem(
            "Language",
            "assets/icons/language.svg",
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/language');
            },
          ),
          _drawerItem("Logout", "assets/icons/logout.svg"),
          const Spacer(),
          _drawerItem(
            "Delete Account",
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
    String title,
    String iconPath, {
    Color textColor = Colors.black,
    double iconSize = 21,
    Color? iconColor,
    VoidCallback? onTap, // you can adjust between 20 or 21
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20), // optional
      leading: Padding(
        padding: const EdgeInsets.only(bottom: 2), // slightly lower
        child: SvgPicture.asset(
          iconPath,
          height: iconSize,
          color:
              iconColor ??
              const Color.fromRGBO(5, 171, 215, 1), // your RGBA color
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
}
