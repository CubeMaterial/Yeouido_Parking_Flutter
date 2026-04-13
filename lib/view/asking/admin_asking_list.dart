// 문의글 리스트
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yeouido_parking_flutter/utils/app_route/app_route.dart';
import 'package:yeouido_parking_flutter/view/common/admin_sidebar.dart';
import 'package:yeouido_parking_flutter/view/common/admin_top_bar.dart';

class AdminAskingList extends StatefulWidget {
  const AdminAskingList({super.key});

  @override
  State<AdminAskingList> createState() => _AdminAskingListState();
}

class _AdminAskingListState extends State<AdminAskingList> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 3;

  final _threadsRef = FirebaseFirestore.instance.collection('chats').withConverter<_ChatThread>(
        fromFirestore: (snap, _) => _ChatThread.fromFirestore(snap),
        toFirestore: (value, _) => value.toFirestore(),
      );

  Future<void> _openThread(_ChatThread thread) async {
    await Navigator.of(context).pushNamed(
      AppRoute.adminAskingView,
      arguments: {
        'chatId': thread.id,
        'title': thread.userName.isNotEmpty ? thread.userName : '채팅 문의',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool useDrawer = constraints.maxWidth < 980;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF3F4F6),
          drawer: useDrawer
              ? Drawer(
                  child: AdminSidebar(
                    selectedIndex: _selectedIndex,
                    onSelected: (index) => setState(() => _selectedIndex = index),
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
                    onSelected: (index) => setState(() => _selectedIndex = index),
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
                            constraints: const BoxConstraints(maxWidth: 1100),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  '문의 관리',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: Colors.black.withValues(alpha: 0.06),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            const Expanded(
                                              child: Text(
                                                '채팅 목록',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            TextButton.icon(
                                              onPressed: () => setState(() {}),
                                              icon: const Icon(Icons.refresh, size: 18),
                                              label: const Text('새로고침'),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        StreamBuilder<QuerySnapshot<_ChatThread>>(
                                          stream: _threadsRef
                                              .orderBy('updatedAt', descending: true)
                                              .snapshots(),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasError) {
                                              return _ErrorBox(
                                                message: snapshot.error.toString(),
                                              );
                                            }
                                            if (!snapshot.hasData) {
                                              return const _LoadingBox();
                                            }

                                            final docs = snapshot.data!.docs;
                                            if (docs.isEmpty) {
                                              return const _EmptyBox(
                                                message: '채팅 문의가 없습니다.',
                                              );
                                            }

                                            return ListView.separated(
                                              shrinkWrap: true,
                                              physics: const NeverScrollableScrollPhysics(),
                                              itemCount: docs.length,
                                              separatorBuilder: (_, index) => const Divider(height: 1),
                                              itemBuilder: (context, index) {
                                                final thread = docs[index].data();
                                                return _ThreadTile(
                                                  thread: thread,
                                                  onTap: () => _openThread(thread),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
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

class _ChatThread {
  const _ChatThread({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.lastMessage,
    required this.status,
    required this.userId,
    required this.userName,
    required this.userEmail,
  });

  final String id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String lastMessage;
  final String status;
  final String userId;
  final String userName;
  final String userEmail;

  static _ChatThread fromFirestore(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data() ?? const <String, dynamic>{};
    return _ChatThread(
      id: snap.id,
      createdAt: _asDateTime(data['createdAt']),
      updatedAt: _asDateTime(data['updatedAt']),
      lastMessage: (data['lastMessage'] ?? '').toString(),
      status: (data['status'] ?? '').toString(),
      userId: (data['userID'] ?? data['userId'] ?? '').toString(),
      userName: (data['userName'] ?? '').toString(),
      userEmail: (data['userEmail'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toFirestore() => <String, dynamic>{
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'lastMessage': lastMessage,
        'status': status,
        'userID': userId,
        'userName': userName,
        'userEmail': userEmail,
      };
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({required this.thread, required this.onTap});

  final _ChatThread thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = thread.userName.trim().isNotEmpty ? thread.userName.trim() : thread.id;
    final subtitleParts = <String>[
      if (thread.userEmail.trim().isNotEmpty) thread.userEmail.trim(),
      if (thread.userId.trim().isNotEmpty) 'ID: ${thread.userId.trim()}',
    ];
    final subtitle = subtitleParts.join(' · ');

    final updated = thread.updatedAt ?? thread.createdAt;
    final updatedText = updated == null ? '-' : _formatDateTime(updated);
    final last = thread.lastMessage.trim().isNotEmpty ? thread.lastMessage.trim() : '(메시지 없음)';
    final status = thread.status.trim().isNotEmpty ? thread.status.trim() : '-';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF111827).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.chat_bubble_outline, size: 18, color: Color(0xFF111827)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _StatusChip(status: status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6B7280),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 6),
                  Text(
                    last,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  updatedText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 6),
                const Icon(Icons.chevron_right, size: 18, color: Color(0xFF9CA3AF)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final lower = status.toLowerCase();
    final (Color bg, Color fg) = switch (lower) {
      'open' => (const Color(0xFFE8F5E9), const Color(0xFF1B5E20)),
      'closed' => (const Color(0xFFFFEBEE), const Color(0xFFB71C1C)),
      _ => (const Color(0xFFF3F4F6), const Color(0xFF374151)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: fg,
        ),
      ),
    );
  }
}

class _LoadingBox extends StatelessWidget {
  const _LoadingBox();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(18),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB91C1C)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFFB91C1C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) {
    // Accept milliseconds since epoch (best-effort).
    if (value > 1000000000000) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.fromMillisecondsSinceEpoch(value * 1000);
  }
  if (value is String) return DateTime.tryParse(value);
  return null;
}

String _formatDateTime(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $hh:$mm';
}
