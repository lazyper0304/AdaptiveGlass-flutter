import 'package:flutter/material.dart';

import '../../../../core/constants/theme_constants.dart';
import '../../../../domain/entities/template.dart';

/// 模板网格
class TemplateGrid extends StatelessWidget {
  const TemplateGrid({
    super.key,
    required this.templates,
    required this.onTap,
  });

  final List<Template> templates;
  final ValueChanged<Template> onTap;

  @override
  Widget build(BuildContext context) {
    return SliverList.separated(
      itemCount: templates.length,
      separatorBuilder: (context, index) => const SizedBox(height: 18),
      itemBuilder: (context, index) {
        final template = templates[index];
        return TemplateCard(
          template: template,
          onTap: () => onTap(template),
        );
      },
    );
  }
}
