import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_svg/flutter_svg.dart';

class VisitDetailsScreen extends StatefulWidget {
  const VisitDetailsScreen({Key? key}) : super(key: key);

  @override
  State<VisitDetailsScreen> createState() => _VisitDetailsScreenState();
}

class _VisitDetailsScreenState extends State<VisitDetailsScreen> {
  
  // Sample data for the visit details
  final Map<String, dynamic> _visitData = {
    'timeFrom': '08:00 AM',
    'timeTo': '12:00 PM',
    'contractNumber': 'H536846',
    'customerName': 'علي ابراهيم قريخ',
    'residencyNumber': '77692046',
    'statusType': 'New',
    'laborName': 'Name Name',
    'serviceName': 'Fawran 4 hours',
    'nationality': 'East Asia',
    'houseType': 'Building',
    'houseNumber': '1',
    'stageNumber': '3',
    'apartmentNumber': '6',
    'notes': 'Note it\'s says',
  };

  // Controllers for the new fields
  final TextEditingController _numberController = TextEditingController(text: '6489864902');
  final TextEditingController _notesController = TextEditingController();

  // State for visit status dropdown
  String? _selectedVisitStatus;
  final List<String> _visitStatuses = [
    'All',
    'New',
    'Arrived',
    'Arrived to deliver',
    'Start',
    'Finished - Done',
    'Finished - Notfound',
    'Free visit cancelled',
    'Not finished - Internal problem',
    'Reparation',
  ];

  @override
  void dispose() {
    _numberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showVisitStatusDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return Stack(
          children: [
            Center(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
                child: Dialog(
                  backgroundColor: Colors.white,
                  insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.8,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Choose Visit Status',
                          style: TextStyle(
                            color: Color(0xFF05ABD7),
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              children: _visitStatuses.map((option) => Column(
                                children: [
                                  _buildDialogOption(
                                    option, 
                                    _selectedVisitStatus, 
                                    (value) {
                                      setState(() {
                                        _selectedVisitStatus = value;
                                      });
                                      Navigator.of(context).pop();
                                    },
                                    isSelected: option == 'All' && _selectedVisitStatus == null,
                                    isAllOption: option == 'All',
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              )).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogOption(String text, String? selectedValue, Function(String) onTap, {bool isSelected = false, bool isAllOption = false}) {
    final bool selected = isSelected || selectedValue == text;
    
    return GestureDetector(
      onTap: () => onTap(text),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF80D9F2) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected ? const Color(0xFF05ABD7) : const Color(0xFFE0E0E0),
            width: selected ? 0.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  color: selected ? Colors.white : const Color(0xFF091735),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            ),
            
            Container(
              width: 24,
              height: 24,
              child: Stack(
                children: [
                  // Background circle SVG
                  SvgPicture.asset(
                    selected ? 'assets/icons/selected_circle.svg' : 'assets/icons/unselected_option.svg',
                    width: 24,
                    height: 24,
                  ),
                  // Check icon on top for selected state
                  if (selected)
                    Positioned.fill(
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Map<String, String>> items, {Color backgroundColor = Colors.white}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00BCD4), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Color(0xFF3CC4E9),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(11),
              bottomRight: Radius.circular(11),
            ),
            child: Column(
              children: [
                for (int index = 0; index < items.length; index++) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: index % 2 == 0 ? const Color(0xFFE0F8FE) : Colors.transparent,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 160,
                          child: Text(
                            items[index]['label'] ?? '',
                            style: const TextStyle(
                              color: Color(0xFF091735),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            items[index]['value'] ?? '',
                            style: const TextStyle(
                              color: Color(0xFF091735),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (index < items.length - 1)
                    Container(
                      height: 1,
                      color: Color(0xFF05ABD7),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlot(String time, String label, Color backgroundColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              time,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String hintText,
    required TextEditingController controller,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        readOnly: readOnly,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF90A3B2),
            fontSize: 16,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF05ABD7),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF05ABD7),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF05ABD7),
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: const TextStyle(
          color: Color(0xFF091735),
          fontSize: 16,
          fontWeight: FontWeight.w600
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? selectedValue,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selectedValue != null ? const Color(0xFF05ABD7) : const Color(0xFFD8DBDB),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedValue ?? label,
                style: TextStyle(
                  color: selectedValue != null ? const Color(0xFF091735) : const Color(0xFF091735),
                  fontSize: 16,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFF666666),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Header
          Container(
            height: 120,
            decoration: const BoxDecoration(
              color: Color(0xFF05ABD7),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            child: Stack(
              children: [
                // Menu icon
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: SvgPicture.asset(
                      'assets/icons/menu.svg',
                      width: 16,
                      height: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Title
                const Center(
                  child: Text(
                    'Update Location',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 24,
                    ),
                  ),
                ),
                // Arrow icon
                const Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 100),
              children: [
                // Time slots
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      _buildTimeSlot(
                        _visitData['timeFrom'],
                        'From',
                        const Color(0xFFFFA200),
                      ),
                      const SizedBox(width: 12),
                      _buildTimeSlot(
                        _visitData['timeTo'],
                        'TO',
                        const Color(0xFFFFA200),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Visit Details Card
                _buildInfoCard(
                  'Visit Details',
                  [
                    {'label': 'Contract number', 'value': _visitData['contractNumber']},
                    {'label': 'Customer Name', 'value': _visitData['customerName']},
                    {'label': 'Residency number', 'value': _visitData['residencyNumber']},
                    {'label': 'Status type', 'value': _visitData['statusType']},
                    {'label': 'Labor name', 'value': _visitData['laborName']},
                    {'label': 'Service name', 'value': _visitData['serviceName']},
                    {'label': 'Nationality', 'value': _visitData['nationality']},
                  ],
                ),

                const SizedBox(height: 8),

                // Address Card
                _buildInfoCard(
                  'Address',
                  [
                    {'label': 'House Type', 'value': _visitData['houseType']},
                    {'label': 'House Number', 'value': _visitData['houseNumber']},
                    {'label': 'Stage Number', 'value': _visitData['stageNumber']},
                    {'label': 'Apartment Number', 'value': _visitData['apartmentNumber']},
                    {'label': 'Notes', 'value': _visitData['notes']},
                  ],
                ),

                const SizedBox(height: 24),

                // Update Location Button
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle update location action
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF05ABD7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Update Location',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Choose Visit Status Dropdown
                _buildDropdownField(
                  label: 'Choose visit status',
                  selectedValue: _selectedVisitStatus,
                  onTap: () => _showVisitStatusDialog(context),
                ),

                // Number Input Field
                _buildInputField(
                  hintText: '6489864902',
                  controller: _numberController,
                  readOnly: true,
                ),

                // Notes Input Field
                _buildInputField(
                  hintText: 'Notes',
                  controller: _notesController,
                  maxLines: 8,
                ),

                const SizedBox(height: 24),

                // Update Button
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle update action
                      print('Visit Status: $_selectedVisitStatus');
                      print('Number: ${_numberController.text}');
                      print('Notes: ${_notesController.text}');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF05ABD7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Update',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}