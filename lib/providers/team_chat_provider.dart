import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import '../models/chat_message.dart';
import '../services/appwrite_service.dart';
import '../environment.dart';
import 'auth_provider.dart';

enum TeamChatStatus { initial, loading, loaded, sending, error }

class TeamChatState {
  final List<ChatMessage> messages;
  final TeamChatStatus status;
  final String? error;

  const TeamChatState({
    this.messages = const [],
    this.status = TeamChatStatus.initial,
    this.error,
  });

  TeamChatState copyWith({
    List<ChatMessage>? messages,
    TeamChatStatus? status,
    String? error,
  }) => TeamChatState(
    messages: messages ?? this.messages,
    status: status ?? this.status,
    error: error,
  );
}

class TeamChatNotifier extends StateNotifier<TeamChatState> {
  final AppwriteService _appwrite;
  final String _teamId;
  final String? _userId;
  final String? _userName;

  TeamChatNotifier(this._appwrite, this._teamId, this._userId, this._userName)
      : super(const TeamChatState());

  Future<void> loadMessages() async {
    state = state.copyWith(status: TeamChatStatus.loading);
    try {
      final result = await _appwrite.tablesDB.listRows(
        databaseId: Environment.appwriteDatabaseId,
        tableId: Environment.teamMessagesCollectionId,
        queries: [
          Query.equal('teamId', [_teamId]),
          Query.orderDesc('createdAt'),
          Query.limit(50),
        ],
      );
      final messages = result.rows
          .map((row) => ChatMessage.fromJson(row.data))
          .toList()
          .reversed
          .toList();
      state = state.copyWith(messages: messages, status: TeamChatStatus.loaded);
    } catch (e) {
      state = state.copyWith(status: TeamChatStatus.error, error: e.toString());
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final userId = _userId;
    if (userId == null) return;
    final message = ChatMessage(
      id: '',
      messageId: '${_teamId}_${DateTime.now().millisecondsSinceEpoch}',
      teamId: _teamId,
      senderId: userId,
      senderName: _userName ?? 'Unknown',
      text: text.trim(),
      createdAt: DateTime.now(),
    );

    // Optimistic update
    state = state.copyWith(
      messages: [...state.messages, message],
      status: TeamChatStatus.sending,
    );

    try {
      await _appwrite.tablesDB.createRow(
        databaseId: Environment.appwriteDatabaseId,
        tableId: Environment.teamMessagesCollectionId,
        rowId: ID.unique(),
        data: message.toJson(),
      );
      state = state.copyWith(status: TeamChatStatus.loaded);
    } catch (e) {
      // Remove optimistic message on failure
      state = state.copyWith(
        messages: state.messages.where((m) => m.messageId != message.messageId).toList(),
        status: TeamChatStatus.error,
        error: e.toString(),
      );
    }
  }
}

final teamChatProvider = StateNotifierProvider.family<TeamChatNotifier, TeamChatState, String>((ref, teamId) {
  final authState = ref.watch(authProvider);
  return TeamChatNotifier(
    ref.watch(appwriteServiceProvider),
    teamId,
    authState.userId,
    authState.name,
  );
});