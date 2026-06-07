import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// 编辑器应用栏
class EditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  const EditorAppBar({
    super.key,
    required this.title,
    required this.actions,
    this.onBack,
  });

  final String title;
  final List<Widget> actions;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (onBack != null)
            GlassButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onTap: onBack!,
              width: 44,
              height: 44,
              iconSize: 22,
              label: '返回',
              quality: GlassQuality.standard,
            ),
          if (onBack != null) const SizedBox(width: 12),
          Expanded(
            child: Hero(
              tag: 'editor-title',
              child: Material(
                type: MaterialType.transparency,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                ),
              ),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(58);
}
