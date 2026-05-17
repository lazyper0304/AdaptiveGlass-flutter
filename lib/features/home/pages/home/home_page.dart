import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/home_template_data.dart';
import '../../widgets/common_home_widgets.dart';
import '../../widgets/template_sections.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
            sliver: const SliverToBoxAdapter(
              child: PageTitleRow(title: '首页', subtitle: '快速选择适合照片的边框风格'),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 150),
            sliver: SliverList.separated(
              itemCount: homeTemplates.length,
              separatorBuilder: (context, index) => const SizedBox(height: 18),
              itemBuilder: (context, index) {
                final template = homeTemplates[index];
                return TemplateTile(
                  data: template,
                  onTap: () => context.push('/editor', extra: template),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
