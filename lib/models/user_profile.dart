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
  });

  bool get isComplete =>
      nickname.isNotEmpty &&
      firstName.isNotEmpty &&
      lastName.isNotEmpty &&
      district.isNotEmpty &&
      area.isNotEmpty &&
      localCenter.isNotEmpty &&
      memberId.isNotEmpty &&
      email.isNotEmpty &&
      position.isNotEmpty;

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
    );
  }
}
