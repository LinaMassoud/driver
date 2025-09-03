import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'visit_details.dart';

class DriverVisitsScreen extends StatefulWidget {
  const DriverVisitsScreen({Key? key}) : super(key: key);

  @override
  State<DriverVisitsScreen> createState() => _DriverVisitsScreenState();
}

class _DriverVisitsScreenState extends State<DriverVisitsScreen> {
  Set<String> expandedVisits = {};
  bool _showVisits = false;
String? _selectedOrderType;
String? _selectedShiftType;
String? _selectedVisitStatus;

// Add these dropdown options as class variables:
final List<String> _orderTypes = [
  'Order by delivery No.',
  'Order by Google', 
  'Order by Manual'
];

final List<String> _shiftTypes = [
  'Shift Type 1', 
  'Shift Type 2', 
  'Shift Type 3'
]; // You can update these with actual shift type names

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

  // Hardcoded data based on the image
  final List<Map<String, dynamic>> _hardcodedVisits = [
  {
    'id': '1',
    'workerName': 'Narmin zain - Addamam',
    'timeSlot': 'From 08:00AM To 12:00PM',
    'totalVisits': 6,
    'address': 'Al Malaz, Riyadh 12635, Saudi Arabia',
    'latitude': 24.7136,
    'longitude': 46.6753,
    'nationalities': {'East Asia': 6},
    'workers': [
      {
        'name': 'Jovelyn Nativadid Capirial (East Asia)',
        'price': '90.0 SAR',
        'duration': 'Fawran 4 Hours',
        'contractId': 'HS738759',
        'status': 'Paid',
        'bookingStatus': 'New'
      }
    ]
  },
  {
    'id': '2',
    'workerName': 'Narmin zain - Addamam',
    'timeSlot': 'From 08:00AM To 12:00PM',
    'totalVisits': 6,
    'address': 'King Fahd District, Riyadh 12271, Saudi Arabia',
    'latitude': 24.6877,
    'longitude': 46.7219,
    'nationalities': {'East Asia': 6},
    'workers': [
      {
        'name': 'Jovelyn Nativadid Capirial (East Asia)',
        'price': '90.0 SAR',
        'duration': 'Fawran 4 Hours',
        'contractId': 'HS738759',
        'status': 'Paid',
        'bookingStatus': 'New'
      }
    ]
  },
  {
    'id': '3',
    'workerName': 'Narmin zain - Addamam',
    'timeSlot': 'From 08:00AM To 12:00PM',
    'totalVisits': 6,
    'address': 'Al Olaya, Riyadh 12213, Saudi Arabia',
    'latitude': 24.6951,
    'longitude': 46.6851,
    'nationalities': {'East Asia': 6},
    'workers': [
      {
        'name': 'Jovelyn Nativadid Capirial (East Asia)',
        'price': '90.0 SAR',
        'duration': 'Fawran 4 Hours',
        'contractId': 'HS738759',
        'status': 'Paid',
        'bookingStatus': 'New'
      }
    ]
  }
];

Future<void> _makePhoneCall(String phoneNumber) async {
  final Uri launchUri = Uri(
    scheme: 'tel',
    path: phoneNumber,
  );
  
  if (await canLaunchUrl(launchUri)) {
    await launchUrl(launchUri);
  } else {
    // Show error message if phone call cannot be made
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not launch phone call'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Add these methods to your _DriverVisitsScreenState class:

void _showOrderTypeDialog(BuildContext context) {
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
                insetPadding: const EdgeInsets.symmetric(horizontal: 20), // Override default insets
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width: double.infinity, // Take full available width
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Order Type',
                        style: TextStyle(
                          color: Color(0xFF05ABD7),
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Order type options
                      _buildDialogOption('Order by delivery No.', _selectedOrderType, (value) {
                        setState(() {
                          _selectedOrderType = value;
                        });
                        Navigator.of(context).pop();
                      }, isSelected: _selectedOrderType == 'Order by delivery No.'),
                      const SizedBox(height: 12),
                      
                      _buildDialogOption('Order by Google', _selectedOrderType, (value) {
                        setState(() {
                          _selectedOrderType = value;
                        });
                        Navigator.of(context).pop();
                      }, isSelected: _selectedOrderType == 'Order by Google'),
                      const SizedBox(height: 12),
                      
                      _buildDialogOption('Order by Manual', _selectedOrderType, (value) {
                        setState(() {
                          _selectedOrderType = value;
                        });
                        Navigator.of(context).pop();
                      }, isSelected: _selectedOrderType == 'Order by Manual'),
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


void _showShiftTypeDialog(BuildContext context) {
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
                insetPadding: const EdgeInsets.symmetric(horizontal: 20), // Override default insets
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width: double.infinity, // Take full available width
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Shift Type',
                        style: TextStyle(
                          color: Color(0xFF05ABD7),
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Shift type options
                      _buildDialogOption('Shift Type 1', _selectedShiftType, (value) {
                        setState(() {
                          _selectedShiftType = value;
                        });
                        Navigator.of(context).pop();
                      }, isSelected: _selectedShiftType == 'Shift Type 1'),
                      const SizedBox(height: 12),
                      
                      _buildDialogOption('Shift Type 2', _selectedShiftType, (value) {
                        setState(() {
                          _selectedShiftType = value;
                        });
                        Navigator.of(context).pop();
                      }, isSelected: _selectedShiftType == 'Shift Type 2'),
                      const SizedBox(height: 12),
                      
                      _buildDialogOption('Shift Type 3', _selectedShiftType, (value) {
                        setState(() {
                          _selectedShiftType = value;
                        });
                        Navigator.of(context).pop();
                      }, isSelected: _selectedShiftType == 'Shift Type 3'),
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

void _showVisitStatusDialog(BuildContext context) {
  final List<String> statusOptions = [
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
                insetPadding: const EdgeInsets.symmetric(horizontal: 20), // Override default insets
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width: double.infinity, // Take full available width
                  padding: const EdgeInsets.all(24),
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8, // Limit dialog height
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
                      
                      // Scrollable options container
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            children: statusOptions.map((option) => Column(
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

Future<void> _openDefaultMaps(double latitude, double longitude, String address) async {
  // Try to open native map apps first
  final Uri geoUri = Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude(${Uri.encodeComponent(address)})');
  
  if (await canLaunchUrl(geoUri)) {
    await launchUrl(geoUri, mode: LaunchMode.externalApplication);
  } else {
    // Fallback to Google Maps web
    final Uri googleMapsUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving'
    );
    
    if (await canLaunchUrl(googleMapsUri)) {
      await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
    } else {
      _showErrorSnackBar('Could not open maps');
    }
  }
}

void _showErrorSnackBar(String message) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
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
  Widget _buildVisitCard(Map<String, dynamic> visit) {
  final visitId = visit['id'].toString();
  final isExpanded = expandedVisits.contains(visitId);

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
          // Main card content - wrapped in GestureDetector for navigation
          GestureDetector(
            onTap: () {
              // Navigate to visit details screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VisitDetailsScreen(),
                ),
              );
            },
            child: Column(
              children: [
                // Header section
                Container(
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        // Blue background section for expand/collapse button - extends to full height
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (expandedVisits.contains(visitId)) {
                                expandedVisits.remove(visitId);
                              } else {
                                expandedVisits.add(visitId);
                              }
                            });
                          },
                          child: Container(
                            width: 60,
                            decoration: BoxDecoration(
                              color: Color(0xFF05ABD7),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(11),
                                topRight: Radius.zero,
                                bottomLeft: isExpanded ? Radius.zero : Radius.zero,
                                bottomRight: Radius.zero,
                              ),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: AnimatedRotation(
                                turns: isExpanded ? 0.25 : 0,
                                duration: const Duration(milliseconds: 300),
                                child: const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // White background section for visit info
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.zero,
                                topRight: Radius.circular(11),
                                bottomLeft: Radius.zero,
                                bottomRight: Radius.zero,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    SvgPicture.asset(
                                      'assets/icons/person_visit.svg',
                                      width: 16,
                                      height: 16,
                                      colorFilter: ColorFilter.mode(Color(0xFF05ABD7), BlendMode.srcIn),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        visit['workerName'],
                                        style: const TextStyle(
                                          color: Color(0xFF05ABD7),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Color(0xFF05ABD7),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      visit['timeSlot'],
                                      style: const TextStyle(
                                        color: Color(0xFF05ABD7),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isExpanded)
                  Container(
                    width: double.infinity,
                    height: 0.5, // 0.5px thick
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Color(0xFFBCBEBF),
                          width: 0.5,
                        ),
                      ),
                    ),
                  ),

                // Expandable content
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: isExpanded
                      ? Container(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Worker details directly in the expanded area
                              ...visit['workers'].map<Widget>((worker) {
                                return Column(
                                  children: [
                                    Row(
                                      children: [
                                        SvgPicture.asset(
                                          'assets/icons/worker.svg',
                                          width: 16,
                                          height: 16,
                                          colorFilter: ColorFilter.mode(Color(0xFF00BCD4), BlendMode.srcIn),
                                        ),
                                        const SizedBox(width: 2),
                                        Expanded(
                                          child: Text(
                                            worker['name'],
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF091735),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Details in grid format
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildDetailItem(
                                            Icons.attach_money,
                                            worker['price'],
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildDetailItem(
                                            Icons.access_time,
                                            worker['duration'],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildDetailItem(
                                            Icons.receipt,
                                            worker['contractId'],
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildDetailItem(
                                            Icons.check_circle,
                                            worker['status'],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildDetailItem(
                                            Icons.info_outline,
                                            worker['bookingStatus'],
                                          ),
                                        ),
                                        const Expanded(child: SizedBox()),
                                      ],
                                    ),
                                  ],
                                );
                              }).toList(),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          
          // Action buttons - Now integrated into the card
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Open maps directly instead of navigating to another screen
                    _openDefaultMaps(
                      visit['latitude'] ?? 24.7136,
                      visit['longitude'] ?? 46.6753,
                      visit['address'] ?? 'Address not available',
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFC107),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(11),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Address',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    _showPhoneDialog(context, '0587583901');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFA200),
                    ),
                    child: const Center(
                      child: Text(
                        'Call',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Arrive action
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF21C15A),
                      borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(11),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Arrive',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  void _showPhoneDialog(BuildContext context, String phoneNumber) {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.5), // Darken the background, including safe areas
    builder: (BuildContext context) {
      return Stack(
        children: [
          // Dialog content
          Center(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
              child: Dialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Phone Number',
                        style: TextStyle(
                          color: Color(0xFF05ABD7),
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Phone number button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop(); // Close dialog first
                            await _makePhoneCall(phoneNumber); // Then make the call
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF05ABD7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            phoneNumber,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Back button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFBCC0C5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Back',
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
              ),
            ),
          ),
        ],
      );
    },
  );
}



  Widget _buildDetailItem(IconData icon, String text, {Color? statusColor}) {
  // Determine which SVG to use based on the icon type
  String svgAsset;
  switch (icon) {
    case Icons.attach_money:
      svgAsset = 'assets/icons/info.svg';
      break;
    case Icons.access_time:
      svgAsset = 'assets/icons/info.svg';
      break;
    case Icons.receipt:
      svgAsset = 'assets/icons/info.svg';
      break;
    case Icons.check_circle:
      svgAsset = 'assets/icons/info.svg';
      break;
    case Icons.info_outline:
      svgAsset = 'assets/icons/info.svg';
      break;
    default:
      svgAsset = 'assets/icons/info.svg';
  }

  return Row(
    children: [
      SvgPicture.asset(
        svgAsset,
        width: 12,
        height: 12,
        colorFilter: ColorFilter.mode(Color(0xFF00BCD4), BlendMode.srcIn),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: statusColor ?? const Color(0xFF091735),
            fontWeight: statusColor != null ? FontWeight.w600 : FontWeight.normal,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
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
                  child: SvgPicture.asset(
                    'assets/icons/menu.svg',
                    width: 16,
                    height: 16,
                    color: Colors.white,
                  ),
                ),
                // Title
                const Center(
                  child: Text(
                    'Visits',
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
                // Order Type Dropdown
                GestureDetector(
                  onTap: () => _showOrderTypeDialog(context),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Order Type',
                                style: TextStyle(
                                  color: Color(0xFF091735),
                                  fontSize: 16,
                                ),
                              ),
                              if (_selectedOrderType != null)
                                Text(
                                  _selectedOrderType!,
                                  style: const TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 14,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down, color: Color(0xFF666666)),
                      ],
                    ),
                  ),
                ),

                // Shift Type 
                GestureDetector(
                  onTap: () => _showShiftTypeDialog(context),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Shift Type',
                                style: TextStyle(
                                  color: Color(0xFF091735),
                                  fontSize: 16,
                                ),
                              ),
                              if (_selectedShiftType != null)
                                Text(
                                  _selectedShiftType!,
                                  style: const TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 14,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down, color: Color(0xFF666666)),
                      ],
                    ),
                  ),
                ),

                // Choose Visit Status 
                GestureDetector(
                  onTap: () => _showVisitStatusDialog(context),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Choose visit status',
                                style: TextStyle(
                                  color: Color(0xFF091735),
                                  fontSize: 16,
                                ),
                              ),
                              if (_selectedVisitStatus != null)
                                Text(
                                  _selectedVisitStatus!,
                                  style: const TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 14,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down, color: Color(0xFF666666)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Show Visits Button
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showVisits = !_showVisits;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFA200),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Show Visits',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Content shown only when _showVisits is true
                if (_showVisits) ...[
                  // Number of employees by nationality card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(0xFF05ABD7),
                        width: 1,
                      ),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top section with padding
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Centered title
                              Center(
                                child: const Text(
                                  'Number of employees by nationality',
                                  style: TextStyle(
                                    color: Color(0xFF00BCD4),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              // Divider
                              Container(
                                width: double.infinity,
                                height: 0.5,
                                color: Color(0xFFBCBEBF),
                              ),
                              const SizedBox(height: 12),
                              
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'East Asia :',
                                    style: TextStyle(
                                      color: Color(0xFF90A3B2),
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '6',
                                    style: TextStyle(
                                      color: Color(0xFF90A3B2),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Total visits container extending full width
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Color(0xFFE0F8FE),
                            border: Border(
                              top: BorderSide(
                                color: Color(0xFF05ABD7),
                                width: 1,
                              ),
                            ),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(11),
                              bottomRight: Radius.circular(11),
                            ),
                          ),
                          child: const Text(
                            'Total number of visits: 6',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF00BCD4),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Visit Cards
                  ...List.generate(
                    _hardcodedVisits.length,
                    (index) => _buildVisitCard(_hardcodedVisits[index]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}