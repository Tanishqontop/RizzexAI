import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rizzexai/theme/app_typography.dart';

/// Luma-style dark bottom navigation with selected icon pill.
class LumaBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const backgroundColor = Color(0xFF202124);
  static const pillColor = Color(0xFF5A5A5C);
  static const unselectedColor = Color(0xFFA6A6A8);
  static const selectedColor = Color(0xFFFFFFFF);
  static const badgeColor = Color(0xFFFF3B30);

  static const _animationDuration = Duration(milliseconds: 180);
  static const _cornerRadius = 16.0;
  static const _barHorizontalInset = 12.0;
  static const _barBottomInset = 8.0;

  static const chatTabIndex = 2;

  const LumaBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.showChatBadge = false,
  });

  final bool showChatBadge;

  static const _items = [
    _LumaNavItem(
      label: 'Home',
      outlineAsset: 'assets/icons/home.svg',
      filledAsset: 'assets/icons/home_filled.svg',
    ),
    _LumaNavItem(
      label: 'Discover',
      outlineAsset: 'assets/icons/explore.svg',
      filledAsset: 'assets/icons/explore_filled.svg',
    ),
    _LumaNavItem(
      label: 'Chat',
      outlineAsset: 'assets/icons/chat.svg',
      filledAsset: 'assets/icons/chat_filled.svg',
    ),
    _LumaNavItem(
      label: 'Profile',
      outlineAsset: 'assets/icons/user.svg',
      filledAsset: 'assets/icons/user_filled.svg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          _barHorizontalInset,
          0,
          _barHorizontalInset,
          _barBottomInset,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_cornerRadius),
          child: ColoredBox(
            color: backgroundColor,
            child: SizedBox(
              height: 64,
              child: Row(
                children: List.generate(
                  _items.length,
                  (index) => Expanded(
                    child: _LumaNavTab(
                      item: _items[index],
                      selected: currentIndex == index,
                      showBadge: index == chatTabIndex && showChatBadge,
                      onTap: () => onTap(index),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LumaNavItem {
  final String label;
  final String outlineAsset;
  final String filledAsset;

  const _LumaNavItem({
    required this.label,
    required this.outlineAsset,
    required this.filledAsset,
  });
}

class _LumaNavTab extends StatelessWidget {
  final _LumaNavItem item;
  final bool selected;
  final bool showBadge;
  final VoidCallback onTap;

  const _LumaNavTab({
    required this.item,
    required this.selected,
    this.showBadge = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final contentColor = selected
        ? LumaBottomNavigation.selectedColor
        : LumaBottomNavigation.unselectedColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white12,
        highlightColor: Colors.white10,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: LumaBottomNavigation._animationDuration,
              curve: Curves.easeOut,
              width: selected ? 60 : 32,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? LumaBottomNavigation.pillColor
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: LumaBottomNavigation._animationDuration,
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeOut,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.92, end: 1)
                              .animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: SvgPicture.asset(
                      selected ? item.filledAsset : item.outlineAsset,
                      key: ValueKey('${item.label}-$selected'),
                      width: 20,
                      height: 20,
                      colorFilter:
                          ColorFilter.mode(contentColor, BlendMode.srcIn),
                    ),
                  ),
                  if (showBadge)
                    Positioned(
                      top: 2,
                      right: selected ? 10 : 2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: LumaBottomNavigation.badgeColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? LumaBottomNavigation.pillColor
                                : LumaBottomNavigation.backgroundColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: LumaBottomNavigation._animationDuration,
              curve: Curves.easeOut,
              style: AppFonts.geist(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                color: contentColor,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}
