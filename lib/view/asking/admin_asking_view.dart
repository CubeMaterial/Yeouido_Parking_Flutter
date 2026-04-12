// 문의글 보기 (관리자 웹) - 채팅 UI
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yeouido_parking_flutter/view/common/admin_sidebar.dart';
import 'package:yeouido_parking_flutter/view/common/admin_top_bar.dart';

class AdminAskingView extends StatefulWidget {
  const AdminAskingView({super.key, this.title});

  final String? title;

  @override
  State<AdminAskingView> createState() => _AdminAskingViewState();
}

class _AdminAskingViewState extends State<AdminAskingView> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 3;

  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _seed();
  }

  void _seed() {
    final now = DateTime.now();
    _messages.addAll([
      _ChatMessage(
        text: '안녕하세요. 이용 관련 문의가 있어요.',
        createdAt: now.subtract(const Duration(minutes: 4)),
        fromAdmin: false,
      ),
      _ChatMessage(
        text: '네, 어떤 점이 불편하셨나요?',
        createdAt: now.subtract(const Duration(minutes: 3)),
        fromAdmin: true,
      ),
      _ChatMessage(
        text: '예약 변경이 가능한지 궁금합니다.',
        createdAt: now.subtract(const Duration(minutes: 2)),
        fromAdmin: false,
      ),
    ]);
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

    setState(() {
      _messages.add(
        _ChatMessage(text: text, createdAt: DateTime.now(), fromAdmin: true),
      );
      _controller.clear();
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
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title?.trim().isNotEmpty == true
        ? widget.title!.trim()
        : '채팅 문의';

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
                                          child: ListView.builder(
                                            controller: _scrollController,
                                            reverse: true,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 10,
                                            ),
                                            itemCount: _messages.length,
                                            itemBuilder: (context, index) {
                                              final msg =
                                                  _messages[_messages.length -
                                                      1 -
                                                      index];
                                              return _ChatBubble(
                                                message: msg,
                                                isAdmin: msg.fromAdmin,
                                              );
                                            },
                                          ),
                                        ),
                                        _ChatInput(
                                          controller: _controller,
                                          focusNode: _focusNode,
                                          onSend: _send,
                                          enabled: true,
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
