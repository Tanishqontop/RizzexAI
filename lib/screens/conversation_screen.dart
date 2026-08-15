import 'package:rizzexai/theme/app_typography.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_match.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../services/unread_messages_service.dart';
import '../widgets/chat_image_viewer.dart';
import '../widgets/safety_actions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConversationScreen extends StatefulWidget {
  final UserMatch match;

  const ConversationScreen({super.key, required this.match});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSending = false;
  StreamSubscription<List<ChatMessage>>? _messagesSubscription;

  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() => setState(() {}));
    _markConversationRead();
    _messagesSubscription =
        _chatService.watchMessages(widget.match.id).listen((messages) {
      if (messages.isNotEmpty) {
        _markConversationRead();
      }
    });
  }

  Future<void> _markConversationRead() async {
    await UnreadMessagesService.instance.markMatchAsRead(widget.match.id);
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  Future<void> _sendMessage() async {
    if (_isSending || _messageController.text.trim().isEmpty) return;

    setState(() => _isSending = true);
    try {
      await _chatService.sendMessage(
        matchId: widget.match.id,
        content: _messageController.text,
      );
      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    await _showImagePreviewSheet(File(picked.path));
  }

  Future<void> _showAttachOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF6B46C1)),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Color(0xFF6B46C1)),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showImagePreviewSheet(File file) async {
    var viewOnce = false;
    final captionController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Image.file(file, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('View once'),
                    subtitle: const Text(
                      'Photo disappears after the recipient opens it',
                    ),
                    value: viewOnce,
                    activeTrackColor: const Color(0xFF6B46C1),
                    onChanged: (value) {
                      setSheetState(() => viewOnce = value);
                    },
                  ),
                  TextField(
                    controller: captionController,
                    decoration: InputDecoration(
                      hintText: 'Add a caption (optional)',
                      filled: true,
                      fillColor: const Color(0xFFF6F7FB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _isSending
                        ? null
                        : () async {
                            Navigator.pop(context);
                            await _sendImage(
                              file: file,
                              viewOnce: viewOnce,
                              caption: captionController.text,
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B46C1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Send photo',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    captionController.dispose();
  }

  Future<void> _sendImage({
    required File file,
    required bool viewOnce,
    String? caption,
  }) async {
    setState(() => _isSending = true);
    try {
      await _chatService.sendImageMessage(
        matchId: widget.match.id,
        file: file,
        viewOnce: viewOnce,
        caption: caption,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send photo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _openImageMessage(ChatMessage message) async {
    if (_currentUserId == null) return;

    if (message.viewOnce && message.isViewOnceConsumed) {
      return;
    }

    if (message.canOpenViewOnce(_currentUserId!)) {
      await ChatImageViewer.open(
        context,
        imageUrl: message.mediaUrl!,
        viewOnce: true,
        onOpened: () async {
          try {
            await _chatService.markViewOnceOpened(message.id);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Could not finish view-once: $e. '
                    'Run view_once_delete_media.sql in Supabase.',
                  ),
                ),
              );
            }
          }
        },
      );
      return;
    }

    if (message.viewOnce &&
        message.senderId == _currentUserId &&
        message.canPreviewViewOnce(_currentUserId!)) {
      await ChatImageViewer.open(
        context,
        imageUrl: message.mediaUrl!,
      );
      return;
    }

    if (!message.viewOnce && message.mediaUrl != null) {
      await ChatImageViewer.open(
        context,
        imageUrl: message.mediaUrl!,
      );
    }
  }

  String _formatDateHeader(DateTime dateTime) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<_ChatListItem> _buildChatItems(List<ChatMessage> messages) {
    final items = <_ChatListItem>[];
    DateTime? lastDate;

    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];
      final messageDate = DateTime(
        message.createdAt.year,
        message.createdAt.month,
        message.createdAt.day,
      );

      if (lastDate == null || !_isSameDay(lastDate, messageDate)) {
        items.add(_ChatListItem.date(_formatDateHeader(message.createdAt)));
        lastDate = messageDate;
      }

      final prev = i > 0 ? messages[i - 1] : null;
      final next = i < messages.length - 1 ? messages[i + 1] : null;
      items.add(_ChatListItem.message(
        message: message,
        isGroupedWithPrevious: prev != null &&
            prev.senderId == message.senderId &&
            _isSameDay(prev.createdAt, message.createdAt),
        isGroupedWithNext: next != null &&
            next.senderId == message.senderId &&
            _isSameDay(next.createdAt, message.createdAt),
      ));
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final matchedUser = widget.match.matchedUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          matchedUser.displayName,
          style: AppFonts.geist(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => showSafetyActionsSheet(
              context,
              userId: widget.match.matchedUser.id,
              userName: widget.match.matchedUser.displayName,
              onBlocked: () => Navigator.of(context).pop(),
            ),
            icon: const Icon(Icons.more_vert, size: 24),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.watchMessages(widget.match.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  );
                }

                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🎉', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(
                          'You matched with ${matchedUser.displayName}!',
                          style: AppFonts.geist(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Say hello to start the conversation',
                          style: AppFonts.geist(
                            color: const Color(0xFF6B6B6B),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                _scrollToBottom();

                final items = _buildChatItems(messages);

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    if (item.isDate) {
                      return _DateSeparator(label: item.dateLabel!);
                    }

                    final message = item.message!;
                    final isMe = message.senderId == _currentUserId;
                    return _MessageBubble(
                      message: message,
                      isMe: isMe,
                      currentUserId: _currentUserId,
                      isGroupedWithPrevious: item.isGroupedWithPrevious,
                      isGroupedWithNext: item.isGroupedWithNext,
                      onImageTap: () => _openImageMessage(message),
                    );
                  },
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    final hasText = _messageController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              onPressed: _isSending ? null : () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_outlined, size: 26),
              color: Colors.black,
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        textCapitalization: TextCapitalization.sentences,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Aa',
                          hintStyle: AppFonts.geist(
                            color: const Color(0xFF9A9A9A),
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF9A9A9A)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'GIF',
                          style: AppFonts.geist(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF6B6B6B),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: _isSending ? null : _showAttachOptions,
              icon: const Icon(Icons.videocam_outlined, size: 26),
              color: Colors.black,
            ),
            IconButton(
              onPressed: _isSending
                  ? null
                  : (hasText ? _sendMessage : () {}),
              icon: _isSending
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      hasText ? Icons.send_rounded : Icons.mic_none_outlined,
                      size: 26,
                    ),
              color: Colors.black,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          label,
          style: AppFonts.geist(
            fontSize: 13,
            color: const Color(0xFF6B6B6B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ChatListItem {
  final ChatMessage? message;
  final String? dateLabel;
  final bool isGroupedWithPrevious;
  final bool isGroupedWithNext;

  bool get isDate => dateLabel != null;

  _ChatListItem.date(this.dateLabel)
      : message = null,
        isGroupedWithPrevious = false,
        isGroupedWithNext = false;

  _ChatListItem.message({
    required this.message,
    required this.isGroupedWithPrevious,
    required this.isGroupedWithNext,
  }) : dateLabel = null;
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final String? currentUserId;
  final bool isGroupedWithPrevious;
  final bool isGroupedWithNext;
  final VoidCallback? onImageTap;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    this.currentUserId,
    this.isGroupedWithPrevious = false,
    this.isGroupedWithNext = false,
    this.onImageTap,
  });

  static const _outgoingBubbleColor = Color(0xFFFFD54F);
  static const _incomingBubbleColor = Color(0xFFF2F2F2);

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMe ? _outgoingBubbleColor : _incomingBubbleColor;
    final textColor = Colors.black;

    final topRadius = isGroupedWithPrevious ? 6.0 : 18.0;
    final bottomRadius = isGroupedWithNext ? 6.0 : 18.0;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: isGroupedWithNext ? 2 : 8,
          top: isGroupedWithPrevious ? 0 : 2,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (message.isImage) _buildImageContent(context, bubbleColor),
            if (message.content.isNotEmpty)
              Container(
                padding: EdgeInsets.fromLTRB(
                  14,
                  message.isImage ? 6 : 10,
                  14,
                  10,
                ),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isMe ? topRadius : topRadius),
                    topRight: Radius.circular(isMe ? topRadius : topRadius),
                    bottomLeft: Radius.circular(isMe ? bottomRadius : bottomRadius),
                    bottomRight: Radius.circular(isMe ? bottomRadius : bottomRadius),
                  ),
                ),
                child: Text(
                  message.content,
                  style: AppFonts.geist(
                    color: textColor,
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageContent(BuildContext context, Color bubbleColor) {
    if (message.viewOnce) {
      if (message.isViewOnceConsumed) {
        return _buildPlaceholder(
          bubbleColor: bubbleColor,
          icon: Icons.done_all,
          label: 'Photo opened',
          subtitle: 'This photo is no longer available',
          onTap: null,
        );
      }

      final isSender =
          currentUserId != null && message.senderId == currentUserId;

      return _buildPlaceholder(
        bubbleColor: bubbleColor,
        icon: Icons.timer_outlined,
        label: 'Photo',
        subtitle: isSender ? 'View once · Tap to open' : 'Tap to view once',
        onTap: onImageTap,
      );
    }

    return GestureDetector(
      onTap: onImageTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: CachedNetworkImage(
          imageUrl: message.mediaUrl!,
          width: 220,
          height: 220,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            width: 220,
            height: 220,
            color: bubbleColor,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (_, __, ___) => Container(
            width: 220,
            height: 220,
            color: bubbleColor,
            child: const Icon(Icons.broken_image),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder({
    required Color bubbleColor,
    required IconData icon,
    required String label,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        height: 140,
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black54, size: 36),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppFonts.geist(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              style: AppFonts.geist(
                color: const Color(0xFF6B6B6B),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
