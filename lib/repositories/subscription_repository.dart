import 'package:appwrite/appwrite.dart';
import '../models/subscription_model.dart';
import '../services/appwrite_service.dart';
import 'base_repository.dart';

class SubscriptionRepository extends BaseRepository<SubscriptionModel> {
  SubscriptionRepository(AppwriteService service)
      : super(service, 'subscriptions');

  @override
  SubscriptionModel fromJson(Map<String, dynamic> json) => SubscriptionModel.fromJson(json);

  @override
  Map<String, dynamic> toJson(SubscriptionModel item) => item.toJson();

  /// Get subscription for a specific user.
  Future<SubscriptionModel?> getSubscriptionForUser(String userId) async {
    final results = await getAll(queries: [
      Query.equal('userId', [userId]),
      Query.limit(1),
    ]);
    return results.isNotEmpty ? results.first : null;
  }

  /// Check if a user has an active pro or coach subscription.
  Future<bool> hasProAccess(String userId) async {
    final sub = await getSubscriptionForUser(userId);
    if (sub == null) return false;
    return sub.isActive && (sub.isPro || sub.isCoach) && !sub.hasExpired;
  }

  /// Create or update a subscription.
  Future<SubscriptionModel?> saveSubscription(SubscriptionModel subscription) async {
    final existing = await getSubscriptionForUser(subscription.userId);
    if (existing != null) {
      return update(existing.id, subscription.toJson());
    }
    return create('unique()', subscription.toJson());
  }
}