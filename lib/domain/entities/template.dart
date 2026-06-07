library;

/// 模板实体
class Template {
  const Template({
    required this.id,
    required this.name,
    required this.description,
    required this.variant,
  });

  final String id;
  final String name;
  final String description;
  final TemplateVariant variant;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Template &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          variant == other.variant;

  @override
  int get hashCode => Object.hash(id, name, description, variant);

  @override
  String toString() => 'Template(id: $id, name: $name, variant: $variant)';
}
