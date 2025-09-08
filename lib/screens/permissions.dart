import 'package:flutter/material.dart';

class PermissionStepsScreen extends StatefulWidget {
  const PermissionStepsScreen({super.key});

  @override
  State<PermissionStepsScreen> createState() => _PermissionStepsScreenState();
}

class _PermissionStepsScreenState extends State<PermissionStepsScreen> {
  int _currentStep = 0;

  final List<Map<String, String>> _steps = [
    {
      "title": "Access Location Permission",
      "description":
          "Choose the domestic solution that matches your lifestyle and personalized requirements",
    },
    {
      "title": "Access Camera Permission",
      "description": "We need camera access so you can scan QR codes easily.",
    },
    {
      "title": "Enable Notifications",
      "description":
          "Stay updated with important alerts and notifications instantly.",
    },
  ];

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("All steps completed!")));
    }
  }

  Widget _buildStepIndicator(BuildContext context) {
    double width = MediaQuery.of(context).size.width * 0.9;
    double circleRadius = 12;
    double stepSpacing = (width - 2 * circleRadius) / (_steps.length - 1);

    return SizedBox(
      width: width,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Grey full bar goes all the way across
          Positioned.fill(
            top: 16,
            bottom: 16,
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // Cyan progress bar (filled behind circles)
          Positioned(
            left: 0,
            right: width - (circleRadius * 2 + stepSpacing * _currentStep),
            top: 16,
            bottom: 16,
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: Color(0xFF05ABD7),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // Circles on top
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_steps.length, (index) {
              final isActive = index <= _currentStep;
              // Add a small left offset for the first circle
              double leftOffset = index == 0 ? circleRadius * 0.5 : 0;

              return Transform.translate(
                offset: Offset(leftOffset, 0),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10295C).withOpacity(0.4),
                        blurRadius: 3,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: circleRadius,
                    backgroundColor: isActive
                        ? Color(0xFF05ABD7)
                        : Colors.grey.shade300,
                    child: Text(
                      "${index + 1}",
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity, // full width
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 36),
              decoration: const BoxDecoration(
                color: Color(0xFF00BCD4),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Text(
                    "App Permission",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Step indicator
            Center(child: _buildStepIndicator(context)),

            const Spacer(),

            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Text(
                    step["title"]!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    step["description"]!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(55),
                  backgroundColor: Color(0xFF05ABD7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  _currentStep == _steps.length - 1 ? "Finish" : "Next",
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
