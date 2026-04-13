import 'package:flutter/material.dart';
import 'package:yeouido_parking_flutter/utils/app_route/app_route.dart';

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({super.key, required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = <({IconData icon, String label})>[
    (icon: Icons.dashboard_outlined, label: '대시 보드'),
    (icon: Icons.local_parking, label: '주차장'),
    (icon: Icons.apartment_outlined, label: '시설 관리'),
    (icon: Icons.event_available_outlined, label: '시설 예약 현황'),
    (icon: Icons.help_outline, label: '문의 관리'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: const Color(0xFFE0E0E0),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF424242),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '박상현 팀장',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final selected = index == selectedIndex;
                  return _SideNavItem(
                    icon: item.icon,
                    label: item.label,
                    selected: selected,
                    onTap: () {
                      onSelected(index);
                      _navigateIfNeeded(context, index);
                    },
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(height: 4),
                itemCount: _items.length,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateIfNeeded(BuildContext context, int index) {
    final targetRoute = switch (index) {
      0 => AppRoute.adminMainPage, // 대시 보드
      1 => AppRoute.adminParkingList, // 시설 예약 현황
      2 => AppRoute.adminReservationList, // 시설 예약 현황
      3 => AppRoute.adminFacilityList, // 시설 관리
      4 => AppRoute.adminAskingList, // 문의 관리
      _ => null,
    };

    if (targetRoute == null) return;

    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (currentRoute == targetRoute) return;

    final scaffoldState = Scaffold.maybeOf(context);
    if (scaffoldState != null && scaffoldState.isDrawerOpen) {
      Navigator.of(context).pop(); // close drawer
    }

    Navigator.of(context).pushReplacementNamed(targetRoute);
  }
}

class _SideNavItem extends StatelessWidget {
  const _SideNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: selected ? Border.all(color: const Color(0xFFBDBDBD)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF424242)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
