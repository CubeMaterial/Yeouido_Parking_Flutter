import 'package:flutter/material.dart';

class AdminTopBar extends StatelessWidget {
  const AdminTopBar({super.key, required this.useDrawer, this.onMenuPressed});

  final bool useDrawer;
  final VoidCallback? onMenuPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 56,
      color: const Color(0xFFFFD54F),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          if (useDrawer)
            IconButton(
              onPressed: onMenuPressed,
              icon: const Icon(Icons.menu),
              tooltip: '메뉴',
            )
          else
            const SizedBox(width: 8),
          const Icon(Icons.park, size: 22),
          const SizedBox(width: 8),
          Text(
            '한강공원 관리자',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          Text(
            '여한이 없을까?',
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

