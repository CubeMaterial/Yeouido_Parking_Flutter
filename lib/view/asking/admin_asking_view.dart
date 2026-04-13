// 문의글 보기 (관리자 웹) - 채팅 UI
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:yeouido_parking_flutter/view/common/admin_sidebar.dart';
import 'package:yeouido_parking_flutter/view/common/admin_top_bar.dart';

class AdminAskingView extends StatefulWidget {
  const AdminAskingView({super.key, this.title, this.chatId});

  final String? title;
  final String? chatId;

  @override
  State<AdminAskingView> createState() => _AdminAskingViewState();
}

class _AdminAskingViewState extends State<AdminAskingView> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 3;

  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  bool _sending = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    await _sendToFirestore(text);
  }

  Future<void> _sendToFirestore(String text) async {
    if (_sending) return;
    final chatId = widget.chatId;
    if (chatId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('채팅을 먼저 선택해 주세요.')),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      _controller.clear();

      final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
      final messagesRef = chatRef.collection('messages');

      await FirebaseFirestore.instance.runTransaction((tx) async {
        tx.set(
          chatRef,
          <String, dynamic>{
            'updatedAt': FieldValue.serverTimestamp(),
            'lastMessage': text,
          },
          SetOptions(merge: true),
        );
        tx.set(
          messagesRef.doc(),
          <String, dynamic>{
            'text': text,
            'createdAt': FieldValue.serverTimestamp(),
            'senderType': 'admin',
            'senderUserID': 0,
          },
        );
      });

      _focusNode.requestFocus();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      if (!mounted) return;
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('메시지 전송 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title?.trim().isNotEmpty == true
        ? widget.title!.trim()
        : '채팅 문의';
    final chatId = widget.chatId;

    return LayoutBuilder(
      builder: (context, constraints) {
        final useDrawer = constraints.maxWidth < 980;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF3F4F6),
          drawer: useDrawer
              ? Drawer(
                  child: AdminSidebar(
                    selectedIndex: _selectedIndex,
                    onSelected: (index) =>
                        setState(() => _selectedIndex = index),
                  ),
                )
              : null,
          body: Row(
            children: [
              if (!useDrawer)
                SizedBox(
                  width: 220,
                  child: AdminSidebar(
                    selectedIndex: _selectedIndex,
                    onSelected: (index) =>
                        setState(() => _selectedIndex = index),
                  ),
                ),
              Expanded(
                child: Column(
                  children: [
                    AdminTopBar(
                      useDrawer: useDrawer,
                      onMenuPressed: useDrawer
                          ? () => _scaffoldKey.currentState?.openDrawer()
                          : null,
                    ),
                    Expanded(
                      child: Scrollbar(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 560),
                            child: Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26),
                              ),
                              child: SizedBox(
                                height: 720,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(26),
                                  child: DecoratedBox(
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF2F2F7),
                                    ),
                                    child: Column(
                                      children: [
                                        _ChatHeader(
                                          title: title,
                                          onClose: () =>
                                              Navigator.of(context).maybePop(),
                                        ),
                                        Expanded(
                                          child: chatId == null
                                              ? const Center(
                                                  child: Text(
                                                    '채팅을 선택해 주세요.',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w800,
                                                      color: Color(0xFF6B7280),
                                                    ),
                                                  ),
                                                )
                                              : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                                  stream: FirebaseFirestore.instance
                                                      .collection('chats')
                                                      .doc(chatId)
                                                      .collection('messages')
                                                      .orderBy('createdAt', descending: false)
                                                      .snapshots(),
                                                  builder: (context, snapshot) {
                                                    if (snapshot.hasError) {
                                                      return Center(
                                                        child: Text(
                                                          '메시지 불러오기 실패: ${snapshot.error}',
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.w800,
                                                            color: Color(0xFFB91C1C),
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                    if (!snapshot.hasData) {
                                                      return const Center(child: CircularProgressIndicator());
                                                    }

                                                    final docs = snapshot.data!.docs;
                                                    if (docs.isEmpty) {
                                                      return const Center(
                                                        child: Text(
                                                          '아직 메시지가 없습니다.',
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.w800,
                                                            color: Color(0xFF6B7280),
                                                          ),
                                                        ),
                                                      );
                                                    }

                                                    final messages = docs
                                                        .map((d) => _ChatMessage.fromMap(d.data()))
                                                        .whereType<_ChatMessage>()
                                                        .toList(growable: false);

                                                    return ListView.builder(
                                                      controller: _scrollController,
                                                      reverse: true,
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 10,
                                                      ),
                                                      itemCount: messages.length,
                                                      itemBuilder: (context, index) {
                                                        final msg = messages[messages.length - 1 - index];
                                                        return _ChatBubble(
                                                          message: msg,
                                                          isAdmin: msg.fromAdmin,
                                                        );
                                                      },
                                                    );
                                                  },
                                                ),
                                        ),
                                        _ChatInput(
                                          controller: _controller,
                                          focusNode: _focusNode,
                                          onSend: _send,
                                          enabled: chatId != null && !_sending,
                                          hintText: '문의 내용을 입력해 주세요',
                                          sendText: '전송',
                                          accentColor: const Color(0xFFF28B7B),
                                          textStyle: Theme.of(
                                            context,
                                          ).textTheme.bodyLarge,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.createdAt,
    required this.fromAdmin,
  });

  final String text;
  final DateTime createdAt;
  final bool fromAdmin;

  static _ChatMessage? fromMap(Map<String, dynamic> data) {
    final rawText = (data['text'] ?? data['message'] ?? data['content'])?.toString();
    final text = rawText?.trim() ?? '';
    if (text.isEmpty) return null;

    final createdAt = _asDateTime(data['createdAt']) ?? DateTime.now();
    final fromAdmin = _asBool(data['fromAdmin']) ?? _inferFromAdmin(data);

    return _ChatMessage(
      text: text,
      createdAt: createdAt,
      fromAdmin: fromAdmin,
    );
  }

  static bool _inferFromAdmin(Map<String, dynamic> data) {
    final sender =
        (data['senderType'] ?? data['sender'] ?? data['role'] ?? data['type'])?.toString().toLowerCase();
    return sender == 'admin' || sender == 'manager';
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: Row(
          children: [
            SizedBox(
              height: 44,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: TextButton(
                  onPressed: onClose,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: const Text(
                    '닫기',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 54),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.isAdmin});

  final _ChatMessage message;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final timeText = _formatTime(message.createdAt);
    final align = isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isAdmin ? const Color(0xFF59BCE6) : Colors.white;
    final textColor = isAdmin ? Colors.white : const Color(0xFF111827);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Row(
            mainAxisAlignment: isAdmin
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              timeText,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  const _ChatInput({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.enabled,
    required this.hintText,
    required this.sendText,
    required this.accentColor,
    required this.textStyle,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final Future<void> Function() onSend;
  final bool enabled;
  final String hintText;
  final String sendText;
  final Color accentColor;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: enabled,
                  minLines: 1,
                  maxLines: 3,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => unawaited(onSend()),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFBDBDBD),
                    ),
                    border: InputBorder.none,
                  ),
                  style: textStyle?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 64,
              height: 64,
              child: ElevatedButton(
                onPressed: enabled ? () => unawaited(onSend()) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  shape: const CircleBorder(),
                  elevation: 0,
                ),
                child: Text(
                  sendText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatTime(DateTime dt) {
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) {
    if (value > 1000000000000) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.fromMillisecondsSinceEpoch(value * 1000);
  }
  if (value is String) return DateTime.tryParse(value);
  return null;
}

bool? _asBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  final text = value.toString().trim().toLowerCase();
  if (text == 'true' || text == '1' || text == 'y' || text == 'yes') return true;
  if (text == 'false' || text == '0' || text == 'n' || text == 'no') return false;
  return null;
}
