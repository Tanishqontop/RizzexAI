enum ChatMessageType { text, image }

class ChatMessage {
  final String id;
  final String matchId;
  final String senderId;
  final String content;
  final ChatMessageType messageType;
  final String? mediaUrl;
  final bool viewOnce;
  final DateTime? viewedAt;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.matchId,
    required this.senderId,
    required this.content,
    this.messageType = ChatMessageType.text,
    this.mediaUrl,
    this.viewOnce = false,
    this.viewedAt,
    required this.createdAt,
  });

  bool get isImage => messageType == ChatMessageType.image;

  bool isViewedByRecipient(String currentUserId) {
    if (!viewOnce) return true;
    if (senderId == currentUserId) return true;
    return viewedAt != null;
  }

  bool get isViewOnceConsumed => viewOnce && viewedAt != null;

  bool canOpenViewOnce(String currentUserId) {
    return viewOnce &&
        !isViewOnceConsumed &&
        senderId != currentUserId &&
        mediaUrl != null;
  }

  bool canPreviewViewOnce(String currentUserId) {
    return viewOnce &&
        !isViewOnceConsumed &&
        mediaUrl != null &&
        mediaUrl!.isNotEmpty;
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase();
      return normalized == 'true' || normalized == 't' || normalized == '1';
    }
    return false;
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    final typeRaw = map['message_type'] as String? ?? 'text';
    return ChatMessage(
      id: map['id'] as String,
      matchId: map['match_id'] as String,
      senderId: map['sender_id'] as String,
      content: map['content'] as String? ?? '',
      messageType:
          typeRaw == 'image' ? ChatMessageType.image : ChatMessageType.text,
      mediaUrl: map['media_url'] as String?,
      viewOnce: _parseBool(map['view_once']),
      viewedAt: map['viewed_at'] != null
          ? DateTime.parse(map['viewed_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
