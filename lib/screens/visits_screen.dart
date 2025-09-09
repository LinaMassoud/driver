import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'visit_details.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/visit_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:driver/providers/language_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driver/providers/selected_date_provider.dart';

class DriverVisitsScreen extends ConsumerStatefulWidget {
  final String? selectedDate;
  const DriverVisitsScreen({
    Key? key,
    this.selectedDate,
  }) : super(key: key);

  @override
  ConsumerState<DriverVisitsScreen> createState() => _DriverVisitsScreenState();
}

class _DriverVisitsScreenState extends ConsumerState<DriverVisitsScreen> {
  Set<String> expandedVisits = {};
  bool _showVisits = false;
  bool _isLoading = false;
  
  // Selected values with IDs
  int? _selectedOrderTypeId;
  String? _selectedOrderType;
  
  int? _selectedShiftTypeId;
  String? _selectedShiftType;
  
  int? _selectedVisitStatusId;
  String? _selectedVisitStatus;

  // API data lists
  List<Map<String, dynamic>> _orderTypes = [];
  List<Map<String, dynamic>> _shiftTypes = [];
  List<Map<String, dynamic>> _visitStatuses = [];
  
  // Visits data
  List<Map<String, dynamic>> _visits = [];

  Map<String, int> _nationalityStats = {};
int _totalVisits = 0;

String? _selectedShiftDescription;

  @override
void initState() {
  super.initState();
  _loadDropdownData();
  
  // Get the selected shift from the provider
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final selectedDateShift = ref.read(selectedDateShiftProvider);
    if (selectedDateShift.shift != null && selectedDateShift.shift!.isNotEmpty) {
      // Find the shift in the loaded data and set it
      _setShiftFromProvider(selectedDateShift.shift!);
    }
  });
}

void _setShiftFromProvider(String shiftName) {
  if (_shiftTypes.isNotEmpty) {
    final matchingShift = _shiftTypes.firstWhere(
      (shift) => shift['service_shifts'] == shiftName,
      orElse: () => {},
    );
    
    if (matchingShift.isNotEmpty) {
      setState(() {
        _selectedShiftType = shiftName;
        _selectedShiftTypeId = matchingShift['id'];
        _selectedShiftDescription = matchingShift['description'];
      });
    }
  }
}

  Future<void> _loadDropdownData() async {
  setState(() {
    _isLoading = true;
  });

  try {
    // Load all dropdown data
    final orderTypesResult = await ApiService.getOrderTypes();
    final shiftsResult = await ApiService.getShifts();
    final visitStatusesResult = await ApiService.getVisitStatuses();

    setState(() {
      _orderTypes = orderTypesResult ?? [];
      _shiftTypes = shiftsResult ?? [];
      _visitStatuses = visitStatusesResult ?? [];
    });

    // Set default values after loading data
    await _setDefaultValues();

    // After loading shift types, check if there's a selected shift from provider
    final selectedDateShift = ref.read(selectedDateShiftProvider);
    if (selectedDateShift.shift != null && selectedDateShift.shift!.isNotEmpty) {
      _setShiftFromProvider(selectedDateShift.shift!);
    }
  } catch (e) {
    print('Error loading dropdown data: $e');
    _showErrorSnackBar('Failed to load data. Please try again.');
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

  Future<void> _fetchVisits() async {
  if (_selectedShiftTypeId == null) {
    _showErrorSnackBar('Please select a shift type');
    return;
  }

  setState(() {
    _isLoading = true;
    _showVisits = false; // Hide the content while loading
    _nationalityStats.clear(); // Clear previous stats
    _totalVisits = 0;
  });

  try {
    // Get car_id from secure storage
    const FlutterSecureStorage secureStorage = FlutterSecureStorage();
    final carIdString = await secureStorage.read(key: 'car_id');
    if (carIdString == null) {
      _showErrorSnackBar('Car ID not found. Please login again.');
      return;
    }

    final carId = int.parse(carIdString);
    // Use the passed date or default to today's date
    final String dateToUse = widget.selectedDate ?? _getTodayDateString();

    final result = await ApiService.getVisits(
      carId: carId,
      shiftId: _selectedShiftTypeId!,
      date: dateToUse,
    );

    if (result != null) {
  // Check if result is a Map with error key
  if (result is Map && result.containsKey('error')) {
    _showErrorSnackBar(result['error']);
  } else {
    List<Map<String, dynamic>> visits = [];
    
    // Handle both response formats:
    // 1. Direct array response: []
    // 2. Object with visits key: {"visits": [...]}
    if (result is List) {
      visits = result.cast<Map<String, dynamic>>();
    } else if (result is Map && result.containsKey('visits')) {
      visits = (result['visits'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    }

    // Filter visits by status first (before sorting)
    visits = _filterVisitsByStatus(visits);

    // Sort visits based on selected order type
    visits = await _sortVisits(visits);

    // Calculate nationality statistics from the filtered and sorted visits data
    Map<String, int> nationalityCount = {};
    
    for (var visit in visits) {
      final groupName = visit['GROUP_NAME']?.toString().trim();
      if (groupName != null && groupName.isNotEmpty) {
        nationalityCount[groupName] = (nationalityCount[groupName] ?? 0) + 1;
      }
    }

    setState(() {
      _visits = visits;
      _nationalityStats = nationalityCount;
      _totalVisits = visits.length;
      _showVisits = true;
    });
  }
} else {
  _showErrorSnackBar('Failed to fetch visits');
}
  } catch (e) {
    print('Error fetching visits: $e');
    _showErrorSnackBar('Failed to fetch visits. Please try again.');
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

Future<void> _setDefaultValues() async {
  final loc = AppLocalizations.of(context)!;
  // Set default order type to "Order by Manual" (ID: 3)
  final manualOrderType = _orderTypes.firstWhere(
    (orderType) => orderType['id'] == 3,
    orElse: () => {},
  );
  
  if (manualOrderType.isNotEmpty) {
    setState(() {
      _selectedOrderTypeId = 3;
      _selectedOrderType = manualOrderType['order_type'];
    });
  }

  // Set default visit status to "All" (null values)
  setState(() {
    _selectedVisitStatusId = null;
    _selectedVisitStatus = loc.all;
  });
}




Future<List<Map<String, dynamic>>> _sortVisits(List<Map<String, dynamic>> visits) async {
  if (_selectedOrderTypeId == null) return visits;

  switch (_selectedOrderTypeId) {
    case 1: // Order by Delivery No.
      visits.sort((a, b) {
        final contractA = a['CONTRACT_NUMBER']?.toString() ?? '';
        final contractB = b['CONTRACT_NUMBER']?.toString() ?? '';
        return contractB.compareTo(contractA); // Descending order
      });
      return visits;

    case 2: // Order by Google (closest distance)
      return await _sortByDistance(visits);

    case 3: // Order by Manual
    default:
      return visits; // Return as-is from API
  }
}

Future<List<Map<String, dynamic>>> _sortByDistance(List<Map<String, dynamic>> visits) async {
  try {
    // Get current location first
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions denied, returning unsorted visits');
        return visits;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions permanently denied, returning unsorted visits');
      return visits;
    }

    Position currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Create a list to store visits with their distances
    List<Map<String, dynamic>> visitsWithDistance = [];

    for (var visit in visits) {
      final addressId = visit['ADDRESS_ID'];
      if (addressId != null) {
        final addressDetails = await ApiService.getCustomerAddressDetails(addressId);
        
        if (addressDetails != null) {
          final latitude = addressDetails['latitude']?.toDouble() ?? 24.7136;
          final longitude = addressDetails['longitude']?.toDouble() ?? 46.6753;
          
          // Calculate distance using Geolocator
          final distance = Geolocator.distanceBetween(
            currentPosition.latitude,
            currentPosition.longitude,
            latitude,
            longitude,
          );
          
          // Add distance to visit data
          Map<String, dynamic> visitWithDistance = Map.from(visit);
          visitWithDistance['_distance'] = distance;
          visitsWithDistance.add(visitWithDistance);
        } else {
          // If address details not found, assign a large distance
          Map<String, dynamic> visitWithDistance = Map.from(visit);
          visitWithDistance['_distance'] = double.maxFinite;
          visitsWithDistance.add(visitWithDistance);
        }
      } else {
        // If no address ID, assign a large distance
        Map<String, dynamic> visitWithDistance = Map.from(visit);
        visitWithDistance['_distance'] = double.maxFinite;
        visitsWithDistance.add(visitWithDistance);
      }
    }

    // Sort by distance (ascending - closest first)
    visitsWithDistance.sort((a, b) {
      final distanceA = a['_distance'] as double;
      final distanceB = b['_distance'] as double;
      return distanceA.compareTo(distanceB);
    });

    // Remove the temporary distance field before returning
    for (var visit in visitsWithDistance) {
      visit.remove('_distance');
    }

    return visitsWithDistance;
  } catch (e) {
    print('Error sorting visits by distance: $e');
    return visits; // Return unsorted if error occurs
  }
  
}


List<Map<String, dynamic>> _filterVisitsByStatus(List<Map<String, dynamic>> visits) {
  // If no visit status is selected (null), return all visits
  if (_selectedVisitStatusId == null) {
    return visits;
  }

  // Find the selected status name from the _visitStatuses list
  String? selectedStatusName;
  for (var status in _visitStatuses) {
    if (status['id'] == _selectedVisitStatusId) {
      selectedStatusName = status['status_name'];
      break;
    }
  }

  if (selectedStatusName == null) {
    return visits; // If status not found, return all visits
  }

  // Filter visits based on STATUS_TYPE matching the selected status name
  return visits.where((visit) {
    final visitStatusType = visit['STATUS_TYPE']?.toString() ?? '';
    return visitStatusType.toLowerCase() == selectedStatusName?.toLowerCase();
  }).toList();
}

String _getTodayDateString() {
  final now = DateTime.now();
  return "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
}

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
  final loc = AppLocalizations.of(context)!;
  if (_orderTypes.isEmpty) {
      _showErrorSnackBar(loc.orderTypesNotLoaded ?? 'Order types not loaded yet. Please wait...');
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       Text(
                        loc.orderType,
                        style: const TextStyle(
                          color: Color(0xFF05ABD7),
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Dynamic order type options from API
                      ..._orderTypes.map((orderType) => Column(
                        children: [
                          _buildDialogOption(
                            orderType['order_type'],
                            _selectedOrderType,
                            (value) {
                              setState(() {
                                _selectedOrderType = value;
                                _selectedOrderTypeId = orderType['id'];
                              });
                              _resetVisitsDisplay();
                              Navigator.of(context).pop();
                            },
                            isSelected: _selectedOrderTypeId == orderType['id'],
                          ),
                          const SizedBox(height: 12),
                        ],
                      )).toList(),
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
  final loc = AppLocalizations.of(context)!;
  if (_shiftTypes.isEmpty) {
      _showErrorSnackBar(loc.shiftTypesNotLoaded ?? 'Shift types not loaded yet. Please wait...');
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                      loc.shiftType,
                      style: const TextStyle(
                        color: Color(0xFF05ABD7),
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                      const SizedBox(height: 24),
                      
                      // Dynamic shift type options from API
                      ..._shiftTypes.map((shiftType) => Column(
                        children: [
                          _buildDialogOption(
                            '${shiftType['service_shifts']}',
                            _selectedShiftType,
                            (value) {
                              setState(() {
                                _selectedShiftType = value;
                                _selectedShiftTypeId = shiftType['id'];
                                _selectedShiftDescription = shiftType['description'];
                              });
                              _resetVisitsDisplay();
                              Navigator.of(context).pop();
                            },
                            isSelected: _selectedShiftTypeId == shiftType['id'],
                          ),
                          const SizedBox(height: 12),
                        ],
                      )).toList(),
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
  final loc = AppLocalizations.of(context)!;
  if (_visitStatuses.isEmpty) {
      _showErrorSnackBar(loc.visitStatusesNotLoaded ?? 'Visit statuses not loaded yet. Please wait...');
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
                      
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              // "All" option - now selected by default
                              _buildDialogOption(
                                loc.all,
                                _selectedVisitStatus,
                                (value) {
                                  setState(() {
                                    _selectedVisitStatus = loc.all;
                                    _selectedVisitStatusId = null;
                                  });
                                  _resetVisitsDisplay();
                                  Navigator.of(context).pop();
                                },
                                isSelected: _selectedVisitStatusId == null,
                                isAllOption: true,
                              ),
                              const SizedBox(height: 12),
                              
                              // Dynamic visit status options from API
                              ..._visitStatuses.map((status) => Column(
                                children: [
                                  _buildDialogOption(
                                    status['status_name'],
                                    _selectedVisitStatus,
                                    (value) {
                                      setState(() {
                                        _selectedVisitStatus = value;
                                        _selectedVisitStatusId = status['id'];
                                      });
                                      _resetVisitsDisplay();
                                      Navigator.of(context).pop();
                                    },
                                    isSelected: _selectedVisitStatusId == status['id'],
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

Future<void> _handleArriveAction(Map<String, dynamic> visit) async {
  // Check if visit status is already "Arrived" (status_type contains "Arrive" or visit status is 3)
  final currentStatusType = visit['STATUS_TYPE']?.toString().toLowerCase() ?? '';
  if (currentStatusType.contains('arrive')) {
    _showErrorSnackBar('Visit is already marked as arrived');
    return;
  }

  setState(() {
    _isLoading = true;
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

    // Format current datetime to match server expected format: "2025-09-05T09:00:00.000000"
    final now = DateTime.now();
    final formattedDate = "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final formattedTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    final microseconds = now.microsecond.toString().padLeft(6, '0');
    final currentDateTime = "${formattedDate}T${formattedTime}.${microseconds}";

    // Call the update appointment API
    final result = await ApiService.updateAppointment(
      appointmentId: visit['APPOINTMENT_ID'],
      visitStatusId: 3, // Arrived status
      actualStartDatetime: currentDateTime,
      location: locationJson,
    );

    if (result['success']) {
      final message = result['data']?['message'] ?? 'Arrived successfully';
      _showSuccessSnackBar(message);
      
      // Refresh the visits list to show updated status
      await _fetchVisits();
    } else {
      _showErrorSnackBar(result['error']);
    }
  } catch (e) {
    print('Error handling arrive action: $e');
    _showErrorSnackBar('Failed to mark as arrived. Please try again.');
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

// Add this helper method for success messages
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

// Add this method to check if arrive button should be enabled
bool _canArrive(Map<String, dynamic> visit) {
  final currentStatusType = visit['STATUS_TYPE']?.toString().toLowerCase() ?? '';
  // Enable arrive button only if status is not already "Arrived"
  return !currentStatusType.contains('arrive');
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
  final loc = AppLocalizations.of(context)!;
  final locale = ref.watch(languageProvider);
  final visitId = visit['SERVICE_CONTRACT_ID'].toString();
  final isExpanded = expandedVisits.contains(visitId);

  print("Selected shift description: $_selectedShiftDescription");

  String timeSlot = _selectedShiftDescription ?? 'Time not available';

  // Get workers list
  List<String> workersList = [];
  if (visit['WORKERS'] != null && visit['WORKERS'] is List) {
    workersList = (visit['WORKERS'] as List).cast<String>();
  }

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
            onTap: () async {
                // Create Visit object and navigate to visit details screen
                final visitObj = Visit.fromJson(visit, shiftDescription: _selectedShiftDescription);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VisitDetailsScreen(visit: visitObj),
                  ),
                );
                
                // If result is true, it means the visit was updated, so refresh the visits
                if (result == true) {
                  await _fetchVisits();
                }
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
                                topLeft: locale.languageCode == 'ar' || locale.languageCode == 'ur'
                                    ? Radius.zero
                                    : Radius.circular(11),
                                topRight: locale.languageCode == 'ar' || locale.languageCode == 'ur'
                                    ? Radius.circular(11)
                                    : Radius.zero,
                                bottomLeft: isExpanded ? Radius.zero : Radius.zero,
                                bottomRight: Radius.zero,
                              ),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Center(
                          child: AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0, // Changed from 0.25 to 0.5 for 180-degree rotation
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              Icons.keyboard_arrow_down, // Changed to use down arrow that rotates
                              color: Colors.white,
                              size: 25,
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
                              topLeft: locale.languageCode == 'ar' || locale.languageCode == 'ur'
                                  ? Radius.circular(11)
                                  : Radius.zero,
                              topRight: locale.languageCode == 'ar' || locale.languageCode == 'ur'
                                  ? Radius.zero
                                  : Radius.circular(11),
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
                                        visit['CUSTOMER_NAME'] ?? 'Customer name not available',
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
                                      timeSlot,
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
                              // Workers section
                              if (workersList.isNotEmpty)
                                ...workersList.map<Widget>((workerName) {
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
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              '${workerName.trim()} (${visit['GROUP_NAME'] ?? 'N/A'})',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF091735),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                  );
                                }).toList(),
                              
                              // Contract and service details in grid format
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDetailItem(
                                      Icons.attach_money,
                                      '${visit['TOTAL_PRICE']  ?? '0'} SAR',
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildDetailItem(
                                      Icons.access_time,
                                      visit['SERVICE_NAME'] ?? 'Service not specified',
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
                                      visit['CONTRACT_NUMBER'] ?? 'Contract N/A',
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildDetailItem(
                                      Icons.check_circle,
                                      visit['CONTRACT_STATUS'] ?? 'Status N/A',
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
                                      visit['STATUS_TYPE'] ?? 'Type N/A',
                                    ),
                                  ),
                                ],
                              ),
                              
                              
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
            // Address button
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final addressDetails = await ApiService.getCustomerAddressDetails(visit['ADDRESS_ID'] ?? 0);
                  
                  if (addressDetails != null) {
                    final latitude = addressDetails['latitude'] ?? 24.7136;
                    final longitude = addressDetails['longitude'] ?? 46.6753;
                    final address = addressDetails['card_text'] ?? 'Address ID: ${visit['ADDRESS_ID'] ?? 'N/A'}';
                    
                    _openDefaultMaps(latitude, longitude, address);
                  } else {
                    _openDefaultMaps(
                      24.7136,
                      46.6753,
                      'Address ID: ${visit['ADDRESS_ID'] ?? 'N/A'}',
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC107), // Ensure yellow color is applied
                    borderRadius: BorderRadius.only(
                      bottomLeft: locale.languageCode == 'ar' || locale.languageCode == 'ur' 
                          ? Radius.zero 
                          : const Radius.circular(11),
                      bottomRight: locale.languageCode == 'ar' || locale.languageCode == 'ur' 
                          ? const Radius.circular(11) 
                          : Radius.zero,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      loc.address,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Call button
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _showPhoneDialog(context, visit['PHONE_NUMBER'] ?? '0000000000');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFA200), // Ensure orange color is applied
                    // No border radius for middle button
                  ),
                  child: Center(
                    child: Text(
                      loc.call,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Arrive button
            Expanded(
              child: GestureDetector(
                onTap: _canArrive(visit) ? () => _handleArriveAction(visit) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF21C15A), // Ensure green color is applied
                    borderRadius: BorderRadius.only(
                      bottomLeft: locale.languageCode == 'ar' || locale.languageCode == 'ur' 
                          ? const Radius.circular(11) 
                          : Radius.zero,
                      bottomRight: locale.languageCode == 'ar' || locale.languageCode == 'ur' 
                          ? Radius.zero 
                          : const Radius.circular(11),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _canArrive(visit) ? loc.arrive : loc.arrived,
                      style: const TextStyle(
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
    final loc = AppLocalizations.of(context)!;
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
                      Text(
                      loc.phoneNumber,
                      style: const TextStyle(
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
                          child: Text(
                          loc.back,
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
              ),
            ),
          ),
        ],
      );
    },
  );
}

void _resetVisitsDisplay() {
  setState(() {
    _showVisits = false;
    _visits.clear();
    _nationalityStats.clear();
    _totalVisits = 0;
    expandedVisits.clear();
  });
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
            fontWeight: statusColor != null ? FontWeight.w600 : FontWeight.w500,
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
    final locale = ref.watch(languageProvider); // Add this line
    final loc = AppLocalizations.of(context)!;
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
              // Arrow icon - positioned based on language
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
                  loc.visits,
                  style: TextStyle(
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
                // Order Type Dropdown
               GestureDetector(
                onTap: () => _showOrderTypeDialog(context),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedOrderType != null 
                          ? const Color(0xFF05ABD7) 
                          : const Color(0xFFE0E0E0),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                        _selectedOrderType ?? loc.orderType,
                        textAlign: locale.languageCode == 'ar' || locale.languageCode == 'ur'
                            ? TextAlign.right
                            : TextAlign.left,
                        style: TextStyle(
                          color: _selectedOrderType != null 
                              ? const Color(0xFF05ABD7) 
                              : const Color(0xFF091735),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down, 
                        color: _selectedOrderType != null 
                            ? const Color(0xFF05ABD7) 
                            : const Color(0xFF666666),
                      ),
                    ],
                  ),
                ),
              ),

                // Shift Type 
                GestureDetector(
                onTap: () => _showShiftTypeDialog(context),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedShiftType != null 
                          ? const Color(0xFF05ABD7) 
                          : const Color(0xFFE0E0E0),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedShiftType ?? loc.shiftType,
                          textAlign: locale.languageCode == 'ar' || locale.languageCode == 'ur'
                              ? TextAlign.right
                              : TextAlign.left,
                          style: TextStyle(
                            color: _selectedShiftType != null 
                                ? const Color(0xFF05ABD7) 
                                : const Color(0xFF091735),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down, 
                        color: _selectedShiftType != null 
                            ? const Color(0xFF05ABD7) 
                            : const Color(0xFF666666),
                      ),
                    ],
                  ),
                ),
              ),

                // Choose Visit Status 
                GestureDetector(
                onTap: () => _showVisitStatusDialog(context),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedVisitStatus != null 
                          ? const Color(0xFF05ABD7) 
                          : const Color(0xFFE0E0E0),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedVisitStatus ?? loc.chooseVisitStatus,
                          textAlign: locale.languageCode == 'ar' || locale.languageCode == 'ur'
                              ? TextAlign.right
                              : TextAlign.left,
                          style: TextStyle(
                            color: _selectedVisitStatus != null 
                                ? const Color(0xFF05ABD7) 
                                : const Color(0xFF091735),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down, 
                        color: _selectedVisitStatus != null 
                            ? const Color(0xFF05ABD7) 
                            : const Color(0xFF666666),
                      ),
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
                  onPressed: _isLoading ? null : _fetchVisits,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA200),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading 
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    :  Text(
                      loc.showVisits,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ),
              ),

                // Content shown only when _showVisits is true
                // Show loading indicator while calculating statistics
              if (_isLoading && _selectedShiftTypeId != null)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(
                        color: Color(0xFF05ABD7),
                      ),
                      const SizedBox(height: 16),
                       Text(
                      loc.fetchingVisits ?? 'fetching visits...',
                      style: const TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    ],
                  ),
                )
              // Content shown only when _showVisits is true and not loading
              else if (_showVisits && !_isLoading) ...[
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
                              child:  Text(
                              loc.numberOfEmployeesByNationality ?? 'Number of employees by nationality',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
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
                            
                            // Dynamic nationality statistics
                            if (_nationalityStats.isNotEmpty)
                              ..._nationalityStats.entries.map((entry) => 
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${entry.key} :',
                                        style: TextStyle(
                                          color: Color(0xFF90A3B2),
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        '${entry.value}',
                                        style: TextStyle(
                                          color: Color(0xFF90A3B2),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ).toList()
                            else
                              // Show placeholder when no data
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                  loc.noDataAvailable ?? 'No data available',
                                  style: const TextStyle(
                                    color: Color(0xFF90A3B2),
                                    fontSize: 14,
                                  ),
                                ),
                                  Text(
                                    '0',
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
                        child: Text(
                        '${loc.totalNumberOfVisits ?? 'Total number of visits'}: $_totalVisits',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
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
                if (_visits.isNotEmpty)
                  ...List.generate(
                    _visits.length,
                    (index) => _buildVisitCard(_visits[index]),
                  )
                else
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child:  Center(
                      child: Text(
                      loc.noVisitsFound ?? 'No visits found for the selected criteria',
                      style: const TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 16,
                      ),
                    ),
                    ),
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