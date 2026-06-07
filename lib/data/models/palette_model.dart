/// 调色板条目模型
class PaletteEntry {
  const PaletteEntry({
    required this.red,
    required this.green,
    required this.blue,
  });

  final int red;
  final int green;
  final int blue;

  String get hexCode => '#${_hex(red)}${_hex(green)}${_hex(blue)}';

  static String _hex(int value) =>
      value.toRadixString(16).padLeft(2, '0').toUpperCase();
}
