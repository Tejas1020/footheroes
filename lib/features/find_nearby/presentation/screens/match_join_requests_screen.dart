import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:footheroes/theme/app_theme.dart';
import '../../domain/entities/join_request.dart';
import '../../providers/join_requests_provider.dart';
import '../../providers/repositories_provider.dart';

/// Manage pending join requests for a match.
class MatchJoinRequestsScreen extends ConsumerStatefulWidget {
  final String matchId;
  final VoidCallback? onBack;

  const MatchJoinRequestsScreen({
    super.key,
    required this.matchId,
    this.onBack,
  });

  @override
  ConsumerState<MatchJoinRequestsScreen> createState() =>
      _MatchJoinRequestsScreenState();
}

class _MatchJoinRequestsScreenState
    extends ConsumerState<MatchJoinRequestsScreen> {
  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(
      matchJoinRequestsNotifierProvider(widget.matchId),
    );

    return Scaffold(
      backgroundColor: AppTheme.voidBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: requestsAsync.when(
                data: (requests) {
                  if (requests.isEmpty) return _buildEmptyState();
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: requests.length,
                    itemBuilder: (_, i) => _RequestCard(
                      request: requests[i],
                      onApprove: (side) => _approve(requests[i].id, side),
                      onDecline: () => _decline(requests[i].id),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => _buildError(err.toString()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (widget.onBack != null)
            IconButton(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppTheme.parchment,
            ),
          Expanded(
            child: Text(
              'Join Requests',
              style: AppTheme.dmSans.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.parchment,
              ),
            ),
          ),
          IconButton(
            onPressed: () => ref
                .read(matchJoinRequestsNotifierProvider(widget.matchId)
                    .notifier)
                .refresh(),
            icon: Icon(Icons.refresh, color: AppTheme.parchment),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: AppTheme.mutedParchment,
          ),
          const SizedBox(height: 12),
          Text(
            'No pending requests.',
            style: AppTheme.dmSans.copyWith(
              color: AppTheme.mutedParchment,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Text(
        message,
        style: AppTheme.dmSans.copyWith(
          color: AppTheme.cardinal,
        ),
      ),
    );
  }

  Future<void> _approve(String requestId, AssignedSide side) async {
    try {
      final usecase = ref.read(approveJoinRequestProvider);
      await usecase(requestId, side.value);
      ref
          .read(matchJoinRequestsNotifierProvider(widget.matchId).notifier)
          .refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approval failed: $e')),
        );
      }
    }
  }

  Future<void> _decline(String requestId) async {
    try {
      final usecase = ref.read(declineJoinRequestProvider);
      await usecase(requestId);
      ref
          .read(matchJoinRequestsNotifierProvider(widget.matchId).notifier)
          .refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Decline failed: $e')),
        );
      }
    }
  }
}

class _RequestCard extends StatelessWidget {
  final JoinRequest request;
  final void Function(AssignedSide) onApprove;
  final VoidCallback onDecline;

  const _RequestCard({
    required this.request,
    required this.onApprove,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.cardBorderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.navy,
                child: Text(
                  request.requesterPosition,
                  style: AppTheme.dmSans.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.parchment,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Player ID: ${request.requesterUid.substring(0, request.requesterUid.length > 8 ? 8 : request.requesterUid.length)}...',
                      style: AppTheme.dmSans.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.parchment,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Position: ${request.requesterPosition}',
                      style: AppTheme.dmSans.copyWith(
                        fontSize: 12,
                        color: AppTheme.gold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.cardinal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  request.status.value,
                  style: AppTheme.dmSans.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.cardinal,
                  ),
                ),
              ),
            ],
          ),
          if (request.requesterMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              '"${request.requesterMessage!}"',
              style: AppTheme.dmSans.copyWith(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: AppTheme.mutedParchment,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showSidePicker(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.cardinal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Approve',
                    style: AppTheme.dmSans.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onDecline,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.mutedParchment,
                    side: BorderSide(color: AppTheme.cardBorderColor),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Decline',
                    style: AppTheme.dmSans.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSidePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.abyss,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                'Assign to side',
                style: AppTheme.dmSans.copyWith(
                  color: AppTheme.parchment,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: AppTheme.cardinal),
              title: Text(
                'Home',
                style: AppTheme.dmSans.copyWith(
                  color: AppTheme.parchment,
                ),
              ),
              onTap: () {
                context.pop();
                onApprove(AssignedSide.home);
              },
            ),
            ListTile(
              leading: const Icon(Icons.directions_run,
                  color: AppTheme.gold),
              title: Text(
                'Away',
                style: AppTheme.dmSans.copyWith(
                  color: AppTheme.parchment,
                ),
              ),
              onTap: () {
                context.pop();
                onApprove(AssignedSide.away);
              },
            ),
          ],
        ),
      ),
    );
  }
}
