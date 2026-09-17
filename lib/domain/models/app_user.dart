class AppUser {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final bool isGuest;

  const AppUser({
    required this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
    this.isGuest = false,
  });

  String get readableName {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!;
    }
    if (email != null && email!.contains('@')) {
      return email!.split('@').first;
    }
    if (isGuest) {
      return 'Guest Player 🌱';
    }
    return 'Gardener';
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'isGuest': isGuest,
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] ?? '',
      displayName: json['displayName'],
      email: json['email'],
      photoUrl: json['photoUrl'],
      isGuest: json['isGuest'] ?? false,
    );
  }
}
