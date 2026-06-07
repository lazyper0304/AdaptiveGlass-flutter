import 'package:flutter/material.dart';

import 'editor_app_bar.dart';

/// 编辑器布局
class EditorLayout extends StatelessWidget {
  const EditorLayout({
    super.key,
    required this.appBar,
    required this.body,
    this.bottomNavigationBar,
  });

  final PreferredSizeWidget appBar;
  final Widget body;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: appBar,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
