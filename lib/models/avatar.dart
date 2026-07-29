class AvatarModel {
  final String id;
  final String name;
  final String emoji;

  const AvatarModel({
    required this.id,
    required this.name,
    required this.emoji,
  });
}

const List<AvatarModel> avatars = [
  AvatarModel(id: "Avatar1", name: "Erkek 1", emoji: "👦"),

  AvatarModel(id: "Avatar2", name: "Erkek 2", emoji: "👨"),

  AvatarModel(id: "Avatar3", name: "Kadın 1", emoji: "👩"),
  AvatarModel(id: "Avatar4", name: "Kadın 2", emoji: "👩"),

  AvatarModel(id: "Avatar5", name: "Robot", emoji: "🤖"),

  AvatarModel(id: "Avatar6", name: "Tilki", emoji: "🦊"),

  AvatarModel(id: "Avatar7", name: "Aslan", emoji: "🦁"),

  AvatarModel(id: "Avatar8", name: "Kedi", emoji: "🐱"),

  AvatarModel(id: "Avatar9", name: "Kaplan", emoji: "🐯"),

  AvatarModel(id: "Avatar10", name: "Ayı", emoji: "🐻"),

  AvatarModel(id: "Avatar11", name: "Panda", emoji: "🐼"),
];
