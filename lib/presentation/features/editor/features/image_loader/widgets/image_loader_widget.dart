import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

/// 图片加载器组件
class ImageLoaderWidget extends StatefulWidget {
  const ImageLoaderWidget({
    super.key,
    required this.onImageLoaded,
    this.initialImage,
  });

  final ValueChanged<Uint8List> onImageLoaded;
  final Uint8List? initialImage;

  @override
  State<ImageLoaderWidget> createState() => _ImageLoaderWidgetState();
}

class _ImageLoaderWidgetState extends State<ImageLoaderWidget> {
  Uint8List? _image;

  @override
  void initState() {
    super.initState();
    _image = widget.initialImage;
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.pickFiles(
      dialogTitle: '选择图片',
      type: FileType.custom,
      allowedExtensions: const [
        'png',
        'jpg',
        'jpeg',
        'bmp',
        'webp',
        'tif',
        'tiff',
      ],
      withData: true,
    );

    final file = result?.files.firstOrNull;
    if (file?.bytes == null) return;
    if (!mounted) return;

    setState(() {
      _image = file!.bytes!;
    });
    widget.onImageLoaded(_image!);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(18),
        ),
        child: _image != null
            ? Image.memory(
                _image!,
                fit: BoxFit.cover,
              )
            : const Padding(
                padding: EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      '点击选择图片',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
