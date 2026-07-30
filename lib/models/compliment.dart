import 'user.dart';

class Compliment {
  final String id;
  final String senderId;
  final String recipientId;
  final String message;
  final String? reply;
  final DateTime? repliedAt;
  final DateTime createdAt;
  final User? sender;
  final User? recipient;

  Compliment({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.message,
    this.reply,
    this.repliedAt,
    required this.createdAt,
    this.sender,
    this.recipient,
  });

  factory Compliment.fromMap(Map<String, dynamic> map) {
    User? parseProfile(Map<String, dynamic>? data) {
      if (data == null) return null;
      try {
        return User.fromMap(data);
      } catch (_) {
        return User.fromBasicMap(data);
      }
    }

    return Compliment(
      id: map['id'] as String,
      senderId: map['sender_id'] as String,
      recipientId: map['recipient_id'] as String,
      message: map['message'] as String,
      reply: map['reply'] as String?,
      repliedAt: map['replied_at'] != null
          ? DateTime.parse(map['replied_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      sender: parseProfile(map['sender'] as Map<String, dynamic>?),
      recipient: parseProfile(map['recipient'] as Map<String, dynamic>?),
    );
  }

  bool get isPendingReply => reply == null;
}
