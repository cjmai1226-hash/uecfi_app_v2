import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class UserService extends ValueNotifier<UserProfile> {
  static final UserService instance = UserService._internal();

  UserService._internal() : super(const UserProfile()) {
    loadProfile();
  }

  UserProfile get currentUser => value;

  Future<void> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    value = UserProfile(
      nickname: prefs.getString('nickname') ?? '',
      firstName: prefs.getString('firstName') ?? '',
      middleName: prefs.getString('middleName') ?? '',
      lastName: prefs.getString('lastName') ?? '',
      district: prefs.getString('district') ?? '',
      area: prefs.getString('area') ?? '',
      localCenter: prefs.getString('localCenter') ?? '',
      centerAddress: prefs.getString('centerAddress') ?? '',
      memberId: prefs.getString('memberId') ?? '',
      email: prefs.getString('email') ?? '',
      position: prefs.getString('position') ?? 'Member',
      avatarPath: prefs.getString('avatarPath') ?? '',
      coverPath: prefs.getString('coverPath') ?? '',
    );
  }

  Future<void> updateProfile({
    required String nickname,
    String firstName = '',
    String middleName = '',
    String lastName = '',
    required String district,
    required String area,
    required String localCenter,
    required String centerAddress,
    String memberId = '',
    String email = '',
    String position = 'Member',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nickname', nickname);
    await prefs.setString('firstName', firstName);
    await prefs.setString('middleName', middleName);
    await prefs.setString('lastName', lastName);
    await prefs.setString('district', district);
    await prefs.setString('area', area);
    await prefs.setString('localCenter', localCenter);
    await prefs.setString('centerAddress', centerAddress);
    if (memberId.isNotEmpty) await prefs.setString('memberId', memberId);
    if (email.isNotEmpty) await prefs.setString('email', email);
    await prefs.setString('position', position);

    value = UserProfile(
      nickname: nickname,
      firstName: firstName.isNotEmpty ? firstName : value.firstName,
      middleName: middleName.isNotEmpty ? middleName : value.middleName,
      lastName: lastName.isNotEmpty ? lastName : value.lastName,
      district: district,
      area: area,
      localCenter: localCenter,
      centerAddress: centerAddress,
      memberId: memberId.isNotEmpty ? memberId : value.memberId,
      email: email.isNotEmpty ? email : value.email,
      position: position,
      avatarPath: value.avatarPath,
      coverPath: value.coverPath,
    );
  }

  Future<void> updateProfileImages({
    String? avatarPath,
    String? coverPath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final current = value;
    final newAvatar = avatarPath ?? current.avatarPath;
    final newCover = coverPath ?? current.coverPath;

    await prefs.setString('avatarPath', newAvatar);
    await prefs.setString('coverPath', newCover);

    value = current.copyWith(
      avatarPath: newAvatar,
      coverPath: newCover,
    );
  }
}
