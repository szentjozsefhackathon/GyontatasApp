class User {
  final String username;
  final String? nickname;
  final String? name;
  final String? email;
  final List<int>? favorites;
  final List<int>? responsibilities;

  User({required this.username, this.nickname, this.name, this.email, this.favorites, this.responsibilities});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'] as String,
      nickname: json['nickname'] as String?,
      name: json['name'] as String?,
      email: json['email'] as String?,
      favorites: json['favorites'] as List<int>?,
      responsibilities: json['responsibilities'] as List<int>?,);
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'nickname': nickname,
      'name': name,
      'email': email,
      'favorites': favorites,
      'responsibilities': responsibilities,
    };
  }
}
