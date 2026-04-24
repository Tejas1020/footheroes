import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:footheroes/theme/app_theme.dart';
import '../../../../providers/auth_provider.dart';
import '../../domain/entities/nearby_match.dart';
import '../../domain/entities/playing_position.dart';
import '../../domain/usecases/request_to_join_match.dart';
import '../../providers/repositories_provider.dart';

/// Dialog for sending a join request to a match.
class RequestToJoinDialog extends ConsumerStatefulWidget {
  final NearbyMatch match;
  final VoidCallback? onSent;

  const RequestToJoinDialog({
    super.key,
    required this.match,
    this.onSent,
  });

  @override
  ConsumerState<RequestToJoinDialog> createState() =>
      _RequestToJoinDialogState();
}

class _RequestToJoinDialogState extends ConsumerState<RequestToJoinDialog> {
  PlayingPosition _position = PlayingPosition.any;
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  Future<void> _submit() async {
    final auth = ref.read(authProvider);
    final uid = auth.userId;
    if (uid == null || uid.isEmpty) {
      _showError('Not authenticated');
      return;
    }

    setState(() => _isSending = true);
    try {
      final usecase = ref.read(requestToJoinMatchProvider);
      await usecase(RequestToJoinMatchParams(
        matchId: widget.match.id,
        requesterUid: uid,
        requesterPosition: _position.value,
        requesterMessage: _messageController.text.trim().isEmpty
            ? null
            : _messageController.text.trim(),
      ));
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSent?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        _showError(e.toString());
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.abyss,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Request to Join',
              style: AppTheme.dmSans.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.parchment,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.match.venueName ?? 'Unknown venue',
              style: AppTheme.dmSans.copyWith(
                fontSize: 14,
                color: AppTheme.gold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Your Position',
              style: AppTheme.dmSans.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.parchment,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: PlayingPosition.values.map((p) {
                final selected = _position == p;
                return ChoiceChip(
                  label: Text(p.value),
                  selected: selected,
                  onSelected: (_) => setState(() => _position = p),
                  selectedColor: AppTheme.cardinal,
                  backgroundColor: AppTheme.cardSurface,
                  labelStyle: AppTheme.dmSans.copyWith(
                    color: selected
                        ? Colors.white
                        : AppTheme.parchment,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              maxLines: 3,
              style: TextStyle(color: AppTheme.parchment),
              decoration: InputDecoration(
                hintText: 'Optional message to the host...',
                hintStyle:
                    TextStyle(color: AppTheme.mutedParchment),
                filled: true,
                fillColor: AppTheme.cardSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSending ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.mutedParchment,
                      side: BorderSide(color: AppTheme.cardBorderColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppTheme.dmSans.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSending ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.cardinal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Send Request',
                            style: AppTheme.dmSans.copyWith(
                              fontWeight: FontWeight.w700,
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
}
