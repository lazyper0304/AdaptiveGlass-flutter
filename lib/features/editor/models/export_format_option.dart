enum ExportFormatOption { png, jpg }

extension ExportFormatOptionX on ExportFormatOption {
  String get label => switch (this) {
    ExportFormatOption.png => 'PNG',
    ExportFormatOption.jpg => 'JPG',
  };

  String get extension => switch (this) {
    ExportFormatOption.png => '.png',
    ExportFormatOption.jpg => '.jpg',
  };
}
