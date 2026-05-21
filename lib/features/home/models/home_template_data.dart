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
    subtitle: '玻璃感边框',
    variant: 3,
  ),
  TemplateData(
    template: FrameTemplate.colorBorder,
    title: '色彩边框',
    subtitle: '自动加白边，并从图片提取五种主色生成色卡',
    variant: 0,
  ),
  TemplateData(
    template: FrameTemplate.watermarkBorder,
    title: '水印边框',
    subtitle: '底部白色信息边框，支持照片参数与厂商 Logo',
    variant: 5,
  ),
  TemplateData(
    template: FrameTemplate.colorWalk,
    title: 'Color Walk',
    subtitle: '取色背景，图片展示，支持自定义文字和时间',
    variant: 6,
  ),
];
