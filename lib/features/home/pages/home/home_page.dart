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
            sliver: SliverToBoxAdapter(
              child: PageTitleRow(title: '首页', subtitle: '快速选择适合照片的边框风格'),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 150),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 250,
                mainAxisSpacing: 24,
                crossAxisSpacing: 22,
                childAspectRatio: 0.82,
              ),
              itemCount: galleryNames.length,
              itemBuilder: (context, index) {
                return TemplateTile(
                  data: TemplateData(
                    title: galleryNames[index],
                    variant: index + 1,
                  ),
                  onTap: () => context.push(
                    '/editor',
                    extra: galleryNames[index],
                  ),
                  compactMeta: index.isOdd,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
