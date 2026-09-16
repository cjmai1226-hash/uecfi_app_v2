class UserProfile {
  final String nickname;
  final String firstName;
  final String middleName;
  final String lastName;
  final String district;
  final String area;
  final String localCenter;
  final String centerAddress;
  final String memberId;
  final String email;
  final String position;
  final String avatarPath;
  final String coverPath;
  final String avatarUrl;
  final String coverUrl;
  final int contributions;
  final bool isLocked;

  const UserProfile({
    this.nickname = '',
    this.firstName = '',
    this.middleName = '',
    this.lastName = '',
    this.district = '',
    this.area = '',
    this.localCenter = '',
    this.centerAddress = '',
    this.memberId = '',
    this.email = '',
    this.position = 'Member',
    this.avatarPath = '',
    this.coverPath = '',
    this.avatarUrl = '',
    this.coverUrl = '',
    this.contributions = 0,
    this.isLocked = false,
  });

  bool get isProperlyOnboarded {
    final n = nickname.trim();
    final f = firstName.trim();
    final l = lastName.trim();
    final d = district.trim();
    final a = area.trim();
    final c = localCenter.trim();
    final e = email.trim();

    return n.isNotEmpty &&
        f.isNotEmpty &&
        l.isNotEmpty &&
        d.isNotEmpty &&
        d.toLowerCase() != 'default district' &&
        a.isNotEmpty &&
        a.toLowerCase() != 'default area' &&
        c.isNotEmpty &&
        c.toUpperCase() != 'MAIN CENTER' &&
        memberId.trim().isNotEmpty &&
        e.isNotEmpty &&
        e.contains('@');
  }

  bool get isComplete => isProperlyOnboarded;

  UserProfile copyWith({
    String? nickname,
    String? firstName,
    String? middleName,
    String? lastName,
    String? district,
    String? area,
    String? localCenter,
    String? centerAddress,
    String? memberId,
    String? email,
    String? position,
    String? avatarPath,
    String? coverPath,
    String? avatarUrl,
    String? coverUrl,
    int? contributions,
    bool? isLocked,
  }) {
    return UserProfile(
      nickname: nickname ?? this.nickname,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      district: district ?? this.district,
      area: area ?? this.area,
      localCenter: localCenter ?? this.localCenter,
      centerAddress: centerAddress ?? this.centerAddress,
      memberId: memberId ?? this.memberId,
      email: email ?? this.email,
      position: position ?? this.position,
      avatarPath: avatarPath ?? this.avatarPath,
      coverPath: coverPath ?? this.coverPath,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      contributions: contributions ?? this.contributions,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}
