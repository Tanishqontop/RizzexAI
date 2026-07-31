import 'user.dart';

class ReceivedSuperLike {
  final String swipeId;
  final String swiperId;
  final User swiper;
  final DateTime createdAt;

  const ReceivedSuperLike({
    required this.swipeId,
    required this.swiperId,
    required this.swiper,
    required this.createdAt,
  });
}
