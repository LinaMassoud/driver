import 'package:driver/widgets/date_card.dart';
import 'package:driver/widgets/day_item.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final dateFormatter = DateFormat("dd-MM-yyyy");

    return Scaffold(
      backgroundColor: const Color(0xfff5f8fe),
      body: SafeArea(
        child: Column(
          children: [
            // Header + Calendar unified
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF05ABD7),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Icon(Icons.menu, color: Colors.white, size: 28),
                        Text(
                          "Home",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 28),
                      ],
                    ),
                  ),

                  // Calendar section
                  // Calendar section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ), // horizontal padding
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
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Month row with arrows
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_left),
                              onPressed: () {
                                // TODO: Implement previous month action
                              },
                            ),
                            Text(
                              DateFormat("MMMM").format(today), // current month
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_right),
                              onPressed: () {
                                // TODO: Implement next month action
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // 🔥 Dynamic week row
                        SizedBox(
                          height: 80,
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
                                selected: index == 0, // today selected
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
                width: double.infinity, // match DateCard width
                height: 80, // match DateCard height
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Implement custom date action
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF05ABD7,
                    ), // same blue as header
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        16,
                      ), // similar to DateCard
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
}
