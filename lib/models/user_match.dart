import 'user.dart';

class UserMatch {
  final String id;
  final String user1Id;
  final String user2Id;
  final User matchedUser;
  final DateTime createdAt;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderId;
  final bool receivedSuperLike;
  final DateTime? superLikeAt;

  UserMatch({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.matchedUser,
    required this.createdAt,
    this.lastMessage,
    this.lastMessageAt,
    this.lastMessageSenderId,
    bool? receivedSuperLike,
    this.superLikeAt,
  }) : receivedSuperLike = receivedSuperLike ?? false;

  bool get hasReceivedSuperLike => receivedSuperLike;

  String otherUserId(String currentUserId) {
    return currentUserId == user1Id ? user2Id : user1Id;
  }
}
