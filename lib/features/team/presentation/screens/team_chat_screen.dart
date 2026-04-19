import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/midnight_pitch_theme.dart';
import '../../../../providers/team_chat_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../models/chat_message.dart';

/// Team Chat screen — messages loaded from Appwrite, optimistic sends.
class TeamChatScreen extends ConsumerStatefulWidget {
  final String teamId;
  final String teamName;

  const TeamChatScreen({super.key, required this.teamId, this.teamName = 'Team'});

  @override
  ConsumerState<TeamChatScreen> createState() => _TeamChatScreenState();
}

class _TeamChatScreenState extends ConsumerState<TeamChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(teamChatProvider(widget.teamId).notifier).loadMessages();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    ref.read(teamChatProvider(widget.teamId).notifier).sendMessage(text);
    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(teamChatProvider(widget.teamId));
    final currentUserId = ref.watch(authProvider).userId;

    return Scaffold(
      backgroundColor: MidnightPitchTheme.surfaceDim,
      appBar: AppBar(
        backgroundColor: MidnightPitchTheme.surfaceContainer,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.teamName,
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: MidnightPitchTheme.primaryText,
              ),
            ),
            Text('Team Chat',
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 11,
                color: MidnightPitchTheme.mutedText,
              ),
            ),
          ],
        ),
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          color: MidnightPitchTheme.primaryText,
        ),
      ),
      body: Column(children: [
        Expanded(child: _buildMessageList(chatState, currentUserId)),
        _buildInputBar(chatState.status == TeamChatStatus.sending),
      ]),
    );
  }

  Widget _buildMessageList(TeamChatState chatState, String? currentUserId) {
    if (chatState.status == TeamChatStatus.loading) {
      return Center(
        child: CircularProgressIndicator(color: MidnightPitchTheme.electricBlue),
      );
    }
    if (chatState.messages.isEmpty) {
      return Center(
        child: Text('No messages yet. Start the conversation!',
          style: TextStyle(
            fontFamily: MidnightPitchTheme.fontFamily,
            color: MidnightPitchTheme.mutedText,
          ),
        ),
      );
    }
    // Scroll to bottom after first load
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: chatState.messages.length,
      itemBuilder: (context, index) =>
        _buildMessageBubble(chatState.messages[index], currentUserId),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, String? currentUserId) {
    final isMe = message.senderId == currentUserId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isMe
                ? MidnightPitchTheme.electricBlue.withValues(alpha: 0.15)
                : MidnightPitchTheme.surfaceContainer,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
              bottomRight: isMe ? Radius.zero : const Radius.circular(16),
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (!isMe)
              Text(message.senderName,
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: MidnightPitchTheme.electricBlue,
                ),
              ),
            if (!isMe) const SizedBox(height: 4),
            Text(message.text,
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 14,
                color: MidnightPitchTheme.primaryText,
              ),
            ),
            const SizedBox(height: 4),
            Text(_formatTime(message.createdAt),
              style: TextStyle(
                fontFamily: MidnightPitchTheme.fontFamily,
                fontSize: 10,
                color: MidnightPitchTheme.mutedText,
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildInputBar(bool isSending) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 24),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainer,
        border: Border(top: BorderSide(color: MidnightPitchTheme.surfaceContainerHigh)),
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _controller,
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              color: MidnightPitchTheme.primaryText,
            ),
            decoration: InputDecoration(
              hintText: 'Type a message...',
              hintStyle: TextStyle(color: MidnightPitchTheme.mutedText),
              filled: true,
              fillColor: MidnightPitchTheme.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onSubmitted: (_) => _sendMessage(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: isSending ? null : _sendMessage,
          icon: isSending
              ? SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: MidnightPitchTheme.electricBlue))
              : Icon(Icons.send, color: MidnightPitchTheme.electricBlue),
        ),
      ]),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}