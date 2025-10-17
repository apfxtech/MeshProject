class Contact {
  final String name;
  final String type;
  final String imagePath;
  final String subtitle;
  final String? botId;

  const Contact({
    required this.name,
    required this.type,
    required this.imagePath,
    required this.subtitle,
    this.botId,
  });

  @override
  bool operator ==(Object other) =>
      other is Contact &&
      name == other.name &&
      type == other.type &&
      botId == other.botId;

  @override
  int get hashCode => name.hashCode ^ type.hashCode ^ (botId?.hashCode ?? 0);
}