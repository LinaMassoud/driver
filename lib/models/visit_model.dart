class Visit {
  final int serviceContractId;
  final String contractNumber;
  final String customerName;
  final String residencyNumber;
  final String phoneNumber;
  final String contractStatus;
  final String statusType;
  final String serviceName;
  final String groupName;
  final double totalPrice;
  final int addressId;
  final int appointmentId;
  final String appointmentDate;
  final int carId;
  final int shiftId;
  final List<String> workers;
  final String? shiftDescription;

  Visit({
    required this.serviceContractId,
    required this.contractNumber,
    required this.customerName,
    required this.residencyNumber,
    required this.phoneNumber,
    required this.contractStatus,
    required this.statusType,
    required this.serviceName,
    required this.groupName,
    required this.totalPrice,
    required this.addressId,
    required this.appointmentId,
    required this.appointmentDate,
    required this.carId,
    required this.shiftId,
    required this.workers,
    this.shiftDescription,
  });

  factory Visit.fromJson(Map<String, dynamic> json, {String? shiftDescription}) {
    return Visit(
      serviceContractId: json['SERVICE_CONTRACT_ID'] ?? 0,
      contractNumber: json['CONTRACT_NUMBER'] ?? '',
      customerName: json['CUSTOMER_NAME'] ?? '',
      residencyNumber: json['RESIDENCY_NUMBER'] ?? '',
      phoneNumber: json['PHONE_NUMBER'] ?? '',
      contractStatus: json['CONTRACT_STATUS'] ?? '',
      statusType: json['STATUS_TYPE'] ?? '',
      serviceName: json['SERVICE_NAME'] ?? '',
      groupName: json['GROUP_NAME'] ?? '',
      totalPrice: (json['TOTAL_PRICE'] ?? 0).toDouble(),
      addressId: json['ADDRESS_ID'] ?? 0,
      appointmentId: json['APPOINTMENT_ID'] ?? 0,
      appointmentDate: json['APPOINTMENT_DATE'] ?? '',
      carId: json['CAR_ID'] ?? 0,
      shiftId: json['SHIFT_ID'] ?? 0,
      workers: (json['WORKERS'] as List?)?.cast<String>() ?? [],
      shiftDescription: shiftDescription,
    );
  }
}