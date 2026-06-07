/// EXIF 模型
class ExifModel {
  const ExifModel({
    this.make = '',
    this.model = '',
    this.iso = '',
    this.exposureTime = '',
    this.fNumber = '',
    this.focalLength = '',
    this.dateTimeOriginal = '',
  });

  final String make;
  final String model;
  final String iso;
  final String exposureTime;
  final String fNumber;
  final String focalLength;
  final String dateTimeOriginal;

  bool get hasData => model.isNotEmpty || make.isNotEmpty;
}
