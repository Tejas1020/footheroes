import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription_model.dart';
import '../repositories/subscription_repository.dart';
import 'auth_provider.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(ref.watch(appwriteServiceProvider));
});

// Subscription state
enum SubscriptionStatus { initial, loading, loaded, error }

class SubscriptionState {
  final SubscriptionStatus status;
  final SubscriptionModel? subscription;
  final bool hasProAccess;
  final String? error;

  const SubscriptionState({
    this.status = SubscriptionStatus.initial,
    this.subscription,
    this.hasProAccess = false,
    this.error,
  });

  SubscriptionState copyWith({
    SubscriptionStatus? status,
    SubscriptionModel? subscription,
    bool? hasProAccess,
    String? error,
  }) {
    return SubscriptionState(
      status: status ?? this.status,
      subscription: subscription ?? this.subscription,
      hasProAccess: hasProAccess ?? this.hasProAccess,
      error: error,
    );
  }
}

// Subscription notifier
class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  final SubscriptionRepository _subscriptionRepo;

  SubscriptionNotifier(this._subscriptionRepo) : super(const SubscriptionState());

  Future<void> loadSubscription(String userId) async {
    state = state.copyWith(status: SubscriptionStatus.loading);
    try {
      final subscription = await _subscriptionRepo.getSubscriptionForUser(userId);
      final hasPro = await _subscriptionRepo.hasProAccess(userId);
      state = state.copyWith(
        status: SubscriptionStatus.loaded,
        subscription: subscription,
        hasProAccess: hasPro,
      );
    } catch (e) {
      state = state.copyWith(status: SubscriptionStatus.error, error: e.toString());
    }
  }
}

// Subscription provider
final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  return SubscriptionNotifier(ref.watch(subscriptionRepositoryProvider));
});