class Contact {
  final String name;
  final String type;
  final String imagePath;
  final String subtitle;
  final String? botId;
  final String? key;

  const Contact({
    required this.name,
    required this.type,
    required this.imagePath,
    required this.subtitle,
    this.botId,
    this.key,
  });

  @override
  bool operator ==(Object other) =>
      other is Contact &&
      type == other.type &&
      botId == other.botId &&
      key == other.key;

  @override
  int get hashCode => name.hashCode ^ type.hashCode ^ (botId?.hashCode ?? 0) ^ (key?.hashCode ?? 0);
}