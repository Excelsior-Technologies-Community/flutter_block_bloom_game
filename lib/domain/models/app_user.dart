class AppUser {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final bool isGuest;
  final String authProvider;

  const AppUser({
    required this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
    this.isGuest = false,
    this.authProvider = 'password',
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
      'authProvider': authProvider,
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] ?? '',
      displayName: json['displayName'],
      email: json['email'],
      photoUrl: json['photoUrl'],
      isGuest: json['isGuest'] ?? false,
      authProvider: json['authProvider'] ?? 'password',
    );
  }

  AppUser copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? photoUrl,
    bool? isGuest,
    String? authProvider,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      isGuest: isGuest ?? this.isGuest,
      authProvider: authProvider ?? this.authProvider,
    );
  }
}
