/// Team chat message model matching the Appwrite teamMessages collection.
class ChatMessage {
  final String id;
  final String messageId;
  final String teamId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.messageId,
    required this.teamId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['\$id'] ?? '',
      messageId: json['messageId'] ?? '',
      teamId: json['teamId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      text: json['text'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'messageId': messageId,
    'teamId': teamId,
    'senderId': senderId,
    'senderName': senderName,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
  };
}