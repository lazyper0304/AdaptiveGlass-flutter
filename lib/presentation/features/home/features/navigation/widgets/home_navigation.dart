import 'package:flutter/material.dart';

/// 主页导航栏
class HomeNavigation extends StatelessWidget {
  const HomeNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    // TODO: 实现实际的导航栏 UI
    return Container(
      color: Colors.red,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => onSelected(0),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => onSelected(1),
          ),
        ],
      ),
    );
  }
}
