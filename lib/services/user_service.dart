import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      avatarUrl: prefs.getString('avatarUrl') ?? '',
      coverUrl: prefs.getString('coverUrl') ?? '',
      contributions: prefs.getInt('contributions') ?? 0,
      isLocked: prefs.getBool('isLocked') ?? false,
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
      avatarUrl: value.avatarUrl,
      coverUrl: value.coverUrl,
      contributions: value.contributions,
      isLocked: value.isLocked,
    );
  }

  Future<void> updateProfileImages({
    String? avatarPath,
    String? coverPath,
    String? avatarUrl,
    String? coverUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final current = value;
    final newAvatar = avatarPath ?? current.avatarPath;
    final newCover = coverPath ?? current.coverPath;
    final newAvatarUrl = avatarUrl ?? current.avatarUrl;
    final newCoverUrl = coverUrl ?? current.coverUrl;

    await prefs.setString('avatarPath', newAvatar);
    await prefs.setString('coverPath', newCover);
    if (avatarUrl != null) await prefs.setString('avatarUrl', newAvatarUrl);
    if (coverUrl != null) await prefs.setString('coverUrl', newCoverUrl);

    value = current.copyWith(
      avatarPath: newAvatar,
      coverPath: newCover,
      avatarUrl: newAvatarUrl,
      coverUrl: newCoverUrl,
    );
  }

  Future<void> updateProfileLock(bool isLocked) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLocked', isLocked);
    value = value.copyWith(isLocked: isLocked);

    final email = value.email.trim().toLowerCase();
    if (email.isNotEmpty && email.contains('@')) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(email).set({
          'isLocked': isLocked,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error syncing profile lock to Firestore: $e');
      }
    }
  }

  Future<void> restoreFullProfile({
    required String nickname,
    required String firstName,
    required String middleName,
    required String lastName,
    required String district,
    required String area,
    required String localCenter,
    required String centerAddress,
    required String memberId,
    required String email,
    required String position,
    String? avatarUrl,
    String? coverUrl,
    int contributions = 0,
    bool isLocked = false,
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
    await prefs.setString('memberId', memberId);
    await prefs.setString('email', email);
    await prefs.setString('position', position);
    if (avatarUrl != null) await prefs.setString('avatarUrl', avatarUrl);
    if (coverUrl != null) await prefs.setString('coverUrl', coverUrl);
    await prefs.setInt('contributions', contributions);
    await prefs.setBool('isLocked', isLocked);

    value = UserProfile(
      nickname: nickname,
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      district: district,
      area: area,
      localCenter: localCenter,
      centerAddress: centerAddress,
      memberId: memberId,
      email: email,
      position: position,
      avatarPath: '',
      coverPath: '',
      avatarUrl: avatarUrl ?? '',
      coverUrl: coverUrl ?? '',
      contributions: contributions,
      isLocked: isLocked,
    );
  }
}
