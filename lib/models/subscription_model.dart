/// Subscription model matching the Appwrite subscriptions collection.
class SubscriptionModel {
  final String id;
  final String userId;
  final String plan;
  final String status;
  final String? appwritePaymentId;
  final DateTime expiresAt;

  const SubscriptionModel({
    required this.id,
    required this.userId,
    required this.plan,
    required this.status,
    this.appwritePaymentId,
    required this.expiresAt,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['\$id'] ?? '',
      userId: json['userId'] ?? '',
      plan: json['plan'] ?? 'free',
      status: json['status'] ?? 'active',
      appwritePaymentId: json['appwritePaymentId'],
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'plan': plan,
      'status': status,
      'appwritePaymentId': appwritePaymentId,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  SubscriptionModel copyWith({
    String? id,
    String? userId,
    String? plan,
    String? status,
    String? appwritePaymentId,
    DateTime? expiresAt,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      plan: plan ?? this.plan,
      status: status ?? this.status,
      appwritePaymentId: appwritePaymentId ?? this.appwritePaymentId,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  bool get isFree => plan == 'free';
  bool get isPro => plan == 'pro';
  bool get isCoach => plan == 'coach';
  bool get isActive => status == 'active';
  bool get isExpired => status == 'expired';
  bool get isCancelled => status == 'cancelled';
  bool get hasExpired => DateTime.now().isAfter(expiresAt);
}