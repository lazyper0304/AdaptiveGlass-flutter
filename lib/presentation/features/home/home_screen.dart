import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../core/constants/theme_constants.dart';
import '../../domain/entities/template.dart';
import '../home/features/template_selection/widgets/template_grid.dart';
import '../home/features/template_selection/widgets/template_card.dart';
import 'home_shell.dart';
import 'settings_shell.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  void _onTabSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassScope.stack(
      background: const HomeBackdrop(),
      content: Positioned.fill(
        child: Scaffold(
          extendBody: true,
          backgroundColor: Colors.transparent,
          body: _GestureDetectingNavigationShell(
            navigationShell: navigationShell,
            onTabSelected: _onTabSelected,
          ),
          bottomNavigationBar: const FloatingHomeNavigation(),
        ),
      ),
    );
  }
}

class _GestureDetectingNavigationShell extends StatefulWidget {
  const _GestureDetectingNavigationShell({
    required this.navigationShell,
    required this.onTabSelected,
  });

  final StatefulNavigationShell navigationShell;
  final void Function(int) onTabSelected;

  @override
  State<_GestureDetectingNavigationShell> createState() =>
      _GestureDetectingNavigationShellState();
}

class _GestureDetectingNavigationShellState
    extends State<_GestureDetectingNavigationShell> {
  final double _swipeThreshold = 80.0;
  double _startX = 0.0;
  double _currentX = 0.0;
  bool _isSwiping = false;

  void _onHorizontalDragStart(DragStartDetails details) {
    _startX = details.globalPosition.dx;
    _currentX = _startX;
    _isSwiping = true;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_isSwiping) return;
    _currentX = details.globalPosition.dx;
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!_isSwiping) return;
    _isSwiping = false;

    final deltaX = _currentX - _startX;
    final currentIndex = widget.navigationShell.currentIndex;

    if (deltaX.abs() > _swipeThreshold) {
      if (deltaX > 0 && currentIndex == 1) {
        widget.onTabSelected(0);
      } else if (deltaX < 0 && currentIndex == 0) {
        widget.onTabSelected(1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      behavior: HitTestBehavior.translucent,
      child: _AnimatedNavigationShell(navigationShell: widget.navigationShell),
    );
  }
}

class _AnimatedNavigationShell extends StatefulWidget {
  const _AnimatedNavigationShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<_AnimatedNavigationShell> createState() =>
      _AnimatedNavigationShellState();
}

class _AnimatedNavigationShellState
    extends State<_AnimatedNavigationShell> {
  int _previousIndex = 0;

  @override
  void didUpdateWidget(covariant _AnimatedNavigationShell oldWidget) {
    if (widget.navigationShell.currentIndex !=
        oldWidget.navigationShell.currentIndex) {
      setState(() {
        _previousIndex = oldWidget.navigationShell.currentIndex;
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        final isForward =
            widget.navigationShell.currentIndex > _previousIndex;
        final slideAnimation = Tween<Offset>(
          begin: isForward
              ? const Offset(0.15, 0)
              : const Offset(-0.15, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ));
        final fadeAnimation = Tween<double>(
          begin: 0.8,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ));

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(widget.navigationShell.currentIndex),
        child: widget.navigationShell,
      ),
    );
  }
}

// 模板数据
const homeTemplates = [
  Template(
    id: 'classic',
    name: '经典模式',
    description: '玻璃感边框',
    variant: TemplateVariant.classic,
  ),
  Template(
    id: 'colorBorder',
    name: '色彩边框',
    description: '自动加白边，并从图片提取五种主色生成色卡',
    variant: TemplateVariant.colorBorder,
  ),
  Template(
    id: 'watermarkBorder',
    name: '水印边框',
    description: '底部白色信息边框，支持照片参数与厂商 Logo',
    variant: TemplateVariant.watermarkBorder,
  ),
  Template(
    id: 'colorWalk',
    name: 'Color Walk',
    description: '取色背景，图片展示，支持自定义文字和时间',
    variant: TemplateVariant.colorWalk,
  ),
];
