library;

import 'package:flutter/material.dart';

/// 图像处理工具类
class ImageUtils {
  ImageUtils._();

  /// 计算目标尺寸
  static (int width, int height) calculateTargetSize({
    required int sourceWidth,
    required int sourceHeight,
    required double targetRatio,
  }) {
    final targetHeightByWidth = (sourceWidth * (1 / targetRatio)).round();
    if (targetHeightByWidth >= sourceHeight) {
      return (sourceWidth, targetHeightByWidth);
    }

    final targetWidthByHeight = (sourceHeight * targetRatio).round();
    return (targetWidthByHeight, sourceHeight);
  }

  /// 计算覆盖缩放的源矩形
  static Rect calculateCoverSourceRect({
    required double sourceWidth,
    required double sourceHeight,
    required double targetWidth,
    required double targetHeight,
  }) {
    final sourceAspect = sourceWidth / sourceHeight;
    final targetAspect = targetWidth / targetHeight;

    if (sourceAspect > targetAspect) {
      final width = sourceHeight * targetAspect;
      return Rect.fromLTWH((sourceWidth - width) / 2, 0, width, sourceHeight);
    }

    final height = sourceWidth / targetAspect;
    return Rect.fromLTWH(0, (sourceHeight - height) / 2, sourceWidth, height);
  }

  /// 下_scale 整数值
  static int scaleInt(int value, double scale) {
    if (value <= 0) return value;
    return max(1, (value * scale).round());
  }

  /// 限制值到字节范围
  static int clampToByte(num value) => value.clamp(0, 255).round();

  /// 限制值到正整数范围
  static int clampToPositiveInt(num value) => max(1, value.round());

  /// 计算模糊半径到 sigma
  static double boxShadowBlurToSigma(double blurRadius) =>
      blurRadius > 0 ? blurRadius * 0.57735 + 0.5 : 0;
}
