class PaymentHistory {
  final String id;
  final String userId;
  final int orderCode;
  final int amount;
  final String description;
  final String planType;
  final int planDurationDays;
  final String status;
  final String? payosTransactionId;
  final DateTime? paidAt;
  final String? checkoutUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentHistory({
    required this.id,
    required this.userId,
    required this.orderCode,
    required this.amount,
    required this.description,
    required this.planType,
    required this.planDurationDays,
    required this.status,
    this.payosTransactionId,
    this.paidAt,
    this.checkoutUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentHistory.fromMap(Map<String, dynamic> map) {
    return PaymentHistory(
      id: map['_id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      orderCode: map['orderCode']?.toInt() ?? 0,
      amount: map['amount']?.toInt() ?? 0,
      description: map['description']?.toString() ?? '',
      planType: map['planType']?.toString() ?? '',
      planDurationDays: map['planDurationDays']?.toInt() ?? 0,
      status: map['status']?.toString() ?? 'pending',
      payosTransactionId: map['payosTransactionId']?.toString(),
      paidAt: map['paidAt'] != null ? DateTime.tryParse(map['paidAt'].toString()) : null,
      checkoutUrl: map['checkoutUrl']?.toString(),
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'].toString()) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'].toString()) : DateTime.now(),
    );
  }

  String get planDisplayName {
    switch (planType) {
      case '1_month':
        return 'Premium 1 tháng';
      case '6_months':
        return 'Premium 6 tháng';
      case '12_months':
        return 'Premium 12 tháng';
      default:
        return planType;
    }
  }

  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return 'Đang chờ';
      case 'paid':
        return 'Đã thanh toán';
      case 'cancelled':
        return 'Đã hủy';
      case 'failed':
        return 'Thất bại';
      default:
        return status;
    }
  }

  String get formattedAmount {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '${formatted}đ';
  }
}
