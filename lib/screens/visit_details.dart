import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_svg/flutter_svg.dart';
import '../models/visit_model.dart';
import '../services/api_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:driver/providers/language_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VisitDetailsScreen extends ConsumerStatefulWidget {
  final Visit visit;

  const VisitDetailsScreen({Key? key, required this.visit}) : super(key: key);

  @override
  ConsumerState<VisitDetailsScreen> createState() => _VisitDetailsScreenState();
}

class _VisitDetailsScreenState extends ConsumerState<VisitDetailsScreen> {
  
  late Map<String, dynamic> _visitData;

  // Controllers for the new fields
  late final TextEditingController _numberController;
  final TextEditingController _notesController = TextEditingController();

  Map<String, dynamic>? _addressDetails;
bool _isLoadingAddress = false;
List<Map<String, dynamic>> _visitStatuses = [];
bool _isLoadingStatuses = false;
bool _isUpdating = false;

  // State for visit status dropdown
  String? _selectedVisitStatus;
  int? _selectedVisitStatusId;


  @override
void initState() {
  super.initState();

  _numberController = TextEditingController(text: widget.visit.residencyNumber);
  // Format the appointment date/time
  String timeFrom = '08:00 AM';
  String timeTo = '12:00 PM';

  if (widget.visit.shiftDescription != null) {
    final description = widget.visit.shiftDescription!;
    // Parse descriptions like "7:30-10:00 AM", "3:30-6:00 PM", "7:30 AM -10:00 PM"
    
    if (description.contains('-')) {
      final parts = description.split('-');
      if (parts.length == 2) {
        timeFrom = parts[0].trim();
        timeTo = parts[1].trim();
      }
    }
  }

  _visitData = {
    'timeFrom': timeFrom,
    'timeTo': timeTo,
    'contractNumber': widget.visit.contractNumber,
    'customerName': widget.visit.customerName,
    'residencyNumber': widget.visit.residencyNumber,
    'statusType': widget.visit.statusType,
    'laborName': widget.visit.workers.isNotEmpty ? widget.visit.workers.first : 'N/A',
    'serviceName': widget.visit.serviceName,
    'nationality': widget.visit.groupName,
  };
  
  // Load address details
  _loadAddressDetails();
  _loadVisitStatuses();
}

Future<void> _loadAddressDetails() async {
  setState(() {
    _isLoadingAddress = true;
  });

  try {
    final addressDetails = await ApiService.getCustomerAddressDetails(widget.visit.addressId);
    if (addressDetails != null) {
      setState(() {
        _addressDetails = addressDetails;
      });
    }
  } catch (e) {
    print('Error loading address details: $e');
  } finally {
    setState(() {
      _isLoadingAddress = false;
    });
  }
}

Future<void> _loadVisitStatuses() async {
  setState(() {
    _isLoadingStatuses = true;
  });

  try {
    final visitStatusesResult = await ApiService.getVisitStatuses();
    setState(() {
      _visitStatuses = visitStatusesResult ?? [];
    });
  } catch (e) {
    print('Error loading visit statuses: $e');
    // Optionally show error to user
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load visit statuses'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    setState(() {
      _isLoadingStatuses = false;
    });
  }
}

  @override
  void dispose() {
    _numberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showVisitStatusDialog(BuildContext context) {
  final loc = AppLocalizations.of(context)!;
  if (_visitStatuses.isEmpty && !_isLoadingStatuses) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.visitStatusesNotLoaded ?? 'Visit statuses not loaded yet. Please try again.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

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
                      Text(
                        loc.chooseVisitStatus,
                        style: const TextStyle(
                          color: Color(0xFF05ABD7),
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      if (_isLoadingStatuses)
                        const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF05ABD7),
                          ),
                        )
                      else
                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                // "All" option
                                _buildDialogOption(
                                  loc.all, 
                                  _selectedVisitStatus, 
                                  (value) {
                                    setState(() {
                                      _selectedVisitStatus = null;
                                      _selectedVisitStatusId = null;
                                    });
                                    Navigator.of(context).pop();
                                  },
                                  isSelected: _selectedVisitStatus == null,
                                  isAllOption: true,
                                ),
                                const SizedBox(height: 12),
                                
                                // Dynamic visit status options from API
                                ..._visitStatuses.map((status) => Column(
                                  children: [
                                    _buildDialogOption(
                                      status['status_name'] ?? 'Unknown Status',
                                      _selectedVisitStatus,
                                      (value) {
                                        setState(() {
                                          _selectedVisitStatus = value;
                                          _selectedVisitStatusId = status['id'];
                                        });
                                        Navigator.of(context).pop();
                                      },
                                      isSelected: _selectedVisitStatus == status['status_name'],
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                )).toList(),
                              ],
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

Future<void> _handleUpdate() async {
  final loc = AppLocalizations.of(context)!;
  // Validate that at least visit status or notes is provided
  if (_selectedVisitStatusId == null && _notesController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.pleaseSelectStatusOrNotes ?? 'Please select a visit status or enter notes'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  setState(() {
    _isUpdating = true;
  });

  try {
    final result = await ApiService.updateAppointment(
      appointmentId: widget.visit.appointmentId,
      visitStatusId: _selectedVisitStatusId,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    if (result['success']) {
      // Use the message from API response
      final message = result['data']?['message'] ?? 'Update completed successfully';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate back and trigger refresh
      Navigator.of(context).pop(true); // Return true to indicate successful update
      
    } else {
      // Use the error message from API response
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error']),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('An error occurred: $e'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    setState(() {
      _isUpdating = false;
    });
  }
}

Future<void> _handleUpdateLocation() async {
  setState(() {
    _isUpdating = true;
  });

  try {
    // Get current location
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showErrorSnackBar('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showErrorSnackBar('Location permissions are permanently denied');
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Format location as JSON string with reduced precision to avoid buffer overflow
    final longitude = double.parse(position.longitude.toStringAsFixed(6));
    final latitude = double.parse(position.latitude.toStringAsFixed(6));
    String locationJson = '{"longitude": $longitude, "latitude": $latitude}';

    // Call the update appointment API with location only
    final result = await ApiService.updateAppointment(
      appointmentId: widget.visit.appointmentId,
      location: locationJson,
    );

    if (result['success']) {
      final message = result['data']?['message'] ?? 'Location updated successfully';
      _showSuccessSnackBar(message);
    } else {
      _showErrorSnackBar(result['error']);
    }
  } catch (e) {
    print('Error updating location: $e');
    _showErrorSnackBar('Failed to update location. Please try again.');
  } finally {
    setState(() {
      _isUpdating = false;
    });
  }
}

// Add these helper methods for showing messages
void _showErrorSnackBar(String message) {
  final locale = ref.watch(languageProvider);
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: locale.languageCode == 'ar' || locale.languageCode == 'ur'
              ? TextAlign.right
              : TextAlign.left,
        ),
        backgroundColor: Colors.red,
      ),
    );
  }
}

void _showSuccessSnackBar(String message) {
  final locale = ref.watch(languageProvider);
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: locale.languageCode == 'ar' || locale.languageCode == 'ur'
              ? TextAlign.right
              : TextAlign.left,
        ),
        backgroundColor: Colors.green,
      ),
    );
  }
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
    final loc = AppLocalizations.of(context)!;
    final locale = ref.watch(languageProvider);
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
                // Arrow icon
                Positioned(
                left: locale.languageCode == 'ar' || locale.languageCode == 'ur' ? null : 0,
                right: locale.languageCode == 'ar' || locale.languageCode == 'ur' ? 0 : null,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Icon(
                    locale.languageCode == 'ar' || locale.languageCode == 'ur' 
                        ? Icons.arrow_back_ios 
                        : Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
                // Title
                Center(
                child: Text(
                  loc.visitDetails ?? 'Visit Details',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 24,
                  ),
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
                      loc.from ?? 'From',
                      const Color(0xFFFFA200),
                    ),
                    const SizedBox(width: 12),
                    _buildTimeSlot(
                      _visitData['timeTo'],
                      loc.to ?? 'TO',
                      const Color(0xFFFFA200),
                    ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Visit Details Card
                _buildInfoCard(
                  loc.visitDetails ?? 'Visit Details',
                  [
                    {'label': loc.contractNumber ?? 'Contract number', 'value': _visitData['contractNumber']},
                    {'label': loc.customerName ?? 'Customer Name', 'value': _visitData['customerName']},
                    {'label': loc.residencyNumber ?? 'Residency number', 'value': _visitData['residencyNumber']},
                    {'label': loc.statusType ?? 'Status type', 'value': _visitData['statusType']},
                    {'label': loc.laborName ?? 'Labor name', 'value': _visitData['laborName']},
                    {'label': loc.serviceName ?? 'Service name', 'value': _visitData['serviceName']},
                    {'label': loc.nationality ?? 'Nationality', 'value': _visitData['nationality']},
                  ],
                ),

                const SizedBox(height: 8),

                // Address Card
                _buildInfoCard(
                  loc.address ?? 'Address',
                  [
                    if (_isLoadingAddress)
                      {'label': loc.loading ?? 'Loading...', 'value': loc.pleaseWait ?? 'Please wait'}
                    else if (_addressDetails != null) ...[
                      {'label': loc.houseType ?? 'House Type', 'value': _addressDetails!['house_type'] ?? 'N/A'},
                      {'label': loc.buildingNumber ?? 'Building Number', 'value': _addressDetails!['building_number'] ?? 'N/A'},
                      {'label': loc.floorNumber ?? 'Floor Number', 'value': _addressDetails!['floor_number']?.toString() ?? 'N/A'},
                      {'label': loc.apartmentNumber ?? 'Apartment Number', 'value': _addressDetails!['apartment_number'] ?? 'N/A'},
                      {'label': loc.notes ?? 'Notes', 'value': _addressDetails!['card_text'] ?? 'N/A'},
                    ]
                    else
                      {'label': loc.address ?? 'Address', 'value': loc.failedToLoadAddress ?? 'Failed to load address details'},
                  ],
                ),

                const SizedBox(height: 24),

                // Update Location Button
                Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUpdating ? null : _handleUpdateLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF05ABD7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 2,
                  ),
                  child: _isUpdating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        loc.updateLocation ?? 'Update Location',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                ),
              ),

                const SizedBox(height: 24),

                // Choose Visit Status Dropdown
                _buildDropdownField(
                label: loc.chooseVisitStatus ?? 'Choose visit status',
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
                hintText: loc.notes ?? 'Notes',
                controller: _notesController,
                maxLines: 8,
              ),

                const SizedBox(height: 24),

                // Update Button
                Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUpdating ? null : _handleUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF05ABD7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 2,
                  ),
                  child: _isUpdating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        loc.update ?? 'Update',
                        style: const TextStyle(
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