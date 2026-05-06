import 'package:flutter/material.dart';
import 'package:footheroes/theme/app_theme.dart';
import '../../domain/entities/join_request.dart';

class JoinRequestCard extends StatelessWidget {
  final JoinRequest request;
  final ValueChanged<String?> onApprove;
  final VoidCallback onDecline;

  const JoinRequestCard({
    super.key,
    required this.request,
    required this.onApprove,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final statusValue = request.status.value;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.cardSurfaceGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorderColorAlt),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: AppTheme.heroCtaGradient,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  request.requesterUid.isNotEmpty ? request.requesterUid[0].toUpperCase() : '?',
                  style: AppTheme.bebasDisplay.copyWith(fontSize: 18, color: AppTheme.parchment),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.requesterUid,
                      style: AppTheme.bodyBold,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(request.requesterPosition, style: AppTheme.labelSmall),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor(statusValue).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusValue.toUpperCase(),
                  style: AppTheme.dmSans.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _statusColor(statusValue),
                  ),
                ),
              ),
            ],
          ),
          if (request.requesterMessage != null && request.requesterMessage!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(request.requesterMessage!, style: AppTheme.dmSans.copyWith(
              fontSize: 12,
              color: AppTheme.mutedParchment,
              fontStyle: FontStyle.italic,
            )),
          ],
          if (statusValue == 'pending') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _button('Decline', onDecline, isSecondary: true),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _button('Approve', () => onApprove(null)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved': return const Color(0xFF2E7D32);
      case 'declined': return AppTheme.feedbackError;
      default: return AppTheme.sparkBlue;
    }
  }

  Widget _button(String label, VoidCallback onTap, {bool isSecondary = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          gradient: isSecondary ? null : AppTheme.heroCtaGradient,
          borderRadius: BorderRadius.circular(8),
          border: isSecondary ? Border.all(color: AppTheme.cardBorderColorLight) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTheme.dmSans.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSecondary ? AppTheme.parchment : Colors.white,
          ),
        ),
      ),
    );
  }
}
