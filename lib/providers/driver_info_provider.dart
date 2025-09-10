import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final driverInfoProvider = FutureProvider<DriverInfo>((ref) async {
  final _secureStorage = const FlutterSecureStorage();

  // List of keys we want to read (excluding token and refresh_token)
  const keysToRead = [
    'car_id',
    'driver_username',
    'car_name',
    'car_brand',
    'car_color',
  ];

  Map<String, String?> storedValues = {};
  for (var key in keysToRead) {
    storedValues[key] = await _secureStorage.read(key: key);
  }

  return DriverInfo.fromMap(storedValues);
});

class DriverInfo {
  final String? carId;
  final String? driverUsername;
  final String? carName;
  final String? carBrand;
  final String? carColor;

  DriverInfo({
    this.carId,
    this.driverUsername,
    this.carName,
    this.carBrand,
    this.carColor,
  });

  factory DriverInfo.fromMap(Map<String, String?> map) {
    return DriverInfo(
      carId: map['car_id'],
      driverUsername: map['driver_username'],
      carName: map['car_name'],
      carBrand: map['car_brand'],
      carColor: map['car_color'],
    );
  }

  Map<String, String?> toMap() {
    return {
      'car_id': carId,
      'driver_username': driverUsername,
      'car_name': carName,
      'car_brand': carBrand,
      'car_color': carColor,
    };
  }
}
