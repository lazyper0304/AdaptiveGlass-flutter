import '../../../models/frame_template.dart';

class TemplateData {
  const TemplateData({
    required this.template,
    required this.title,
    required this.subtitle,
    required this.variant,
  });

  final FrameTemplate template;
  final String title;
  final String subtitle;
  final int variant;
}

const homeTemplates = [
  TemplateData(
    template: FrameTemplate.classic,
    title: '经典模式',
    subtitle: '保留原有玻璃感边框和实时调节能力',
    variant: 3,
  ),
  TemplateData(
    template: FrameTemplate.colorBorder,
    title: '色彩边框',
    subtitle: '自动加白边，并从图片提取五种颜色生成色卡',
    variant: 0,
  ),
];
