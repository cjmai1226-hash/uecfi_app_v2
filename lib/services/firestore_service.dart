import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import 'user_service.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // 1. Create Post
  Future<void> submitCommunityPost({
    required String content,
    required String authorEmail,
    required String authorNickname,
    String? bgGradient,
    String? avatarUrl,
  }) async {
    final Map<String, dynamic> data = {
      'content': content,
      'authorEmail': authorEmail,
      'authorNickname': authorNickname,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': 0,
      'comments': 0,
    };
    if (bgGradient != null &&
        bgGradient.isNotEmpty &&
        bgGradient != 'default') {
      data['bgGradient'] = bgGradient;
    }
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      data['avatarUrl'] = avatarUrl;
    }
    await _firestore.collection('community_posts').add(data);
  }

  // 1b. Update Post
  Future<void> updateCommunityPost({
    required String postId,
    required String newContent,
    required String previousContent,
    String? bgGradient,
  }) async {
    final Map<String, dynamic> data = {
      'content': newContent,
      'previousContent': previousContent,
      'editedAt': FieldValue.serverTimestamp(),
      'isEdited': true,
    };
    if (bgGradient != null &&
        bgGradient.isNotEmpty &&
        bgGradient != 'default') {
      data['bgGradient'] = bgGradient;
    } else {
      data['bgGradient'] = FieldValue.delete();
    }
    await _firestore.collection('community_posts').doc(postId).update(data);
  }

  // 2. Submit Song
  Future<void> submitSongSuggestion({
    required String title,
    required String author,
    required String category,
    required String lyrics,
    required String chords,
    required String submittedByEmail,
  }) async {
    await _firestore.collection('song_submissions').add({
      'title': title,
      'author': author,
      'category': category,
      'lyrics': lyrics,
      'chords': chords,
      'submittedBy': submittedByEmail,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending', // for admin review queues
    });
  }

  // 3. Update Center
  Future<void> submitCenterUpdate({
    required String centerId,
    required String centerName,
    required String centerAddress,
    required String updateType,
    required Map<String, dynamic> payload,
    required String submittedByEmail,
  }) async {
    await _firestore.collection('center_updates').add({
      'centerId': centerId,
      'centerName': centerName,
      'centerAddress': centerAddress,
      'updateType': updateType, // 'Location Locator' or 'Contact Person'
      'payload': payload,
      'submittedBy': submittedByEmail,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }

  // 4. Save User Profile
  Future<void> saveUserProfile({
    required String uid,
    required String email,
    required String name,
    required String firstName,
    required String middleName,
    required String surname,
    required String position,
    required String district,
    required String area,
    required String centerName,
    required String centerAddress,
  }) async {
    if (email.isEmpty) return;
    await _firestore.collection('users').doc(email).set({
      'uid': uid,
      'email': email,
      'name': name,
      'firstName': firstName,
      'middleName': middleName,
      'surname': surname,
      'position': position,
      'district': district,
      'area': area,
      'centerName': centerName,
      'centerAddress': centerAddress,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // 4b. Check if email exists
  Future<bool> checkEmailExists(String email) async {
    if (email.isEmpty) return false;
    final doc = await _firestore.collection('users').doc(email).get();
    return doc.exists;
  }

  // 4c. Check if nickname exists
  Future<bool> checkNicknameExists(String nickname) async {
    if (nickname.isEmpty) return false;
    final query = await _firestore
        .collection('users')
        .where('name', isEqualTo: nickname)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  // 4d. Get User Profile
  Future<Map<String, dynamic>?> getUserProfile(String email) async {
    if (email.isEmpty) return null;
    final doc = await _firestore.collection('users').doc(email).get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }

  // 4e. Increment User Contributions
  Future<void> incrementUserContributions(String email) async {
    if (email.isEmpty) return;
    try {
      final items = await getUserContributions(email);
      final validContributionsCount = items
          .where((item) => item['status'] != 'reported')
          .length;
      await syncUserContributionsCount(email, validContributionsCount);
    } catch (e) {
      debugPrint('Error incrementing user contributions: $e');
    }
  }

  // 4f. Sync User Contributions Count (Self-healing backfill)
  Future<void> syncUserContributionsCount(String email, int count) async {
    if (email.isEmpty) return;
    try {
      final userRef = _firestore.collection('users').doc(email);
      await userRef.update({'contributions': count});

      // Synchronize locally if it is the current user
      final currentProfile = UserService.instance.value;
      if (currentProfile.email.toLowerCase() == email.toLowerCase()) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('contributions', count);
        UserService.instance.value = currentProfile.copyWith(
          contributions: count,
        );
        UserContributionsCache.updateCache(currentProfile.nickname, count);
      }
    } catch (e) {
      debugPrint('Error syncing user contributions count: $e');
    }
  }

  // 5. Get Community Posts Stream
  Stream<QuerySnapshot> getCommunityPostsStream() {
    final threshold = DateTime.now().subtract(const Duration(days: 5));
    return _firestore
        .collection('community_posts')
        .where('timestamp', isGreaterThanOrEqualTo: threshold)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // 5b. Get Community Posts (One-time fetch)
  Future<QuerySnapshot> getCommunityPosts() {
    final threshold = DateTime.now().subtract(const Duration(days: 5));
    return _firestore
        .collection('community_posts')
        .where('timestamp', isGreaterThanOrEqualTo: threshold)
        .orderBy('timestamp', descending: true)
        .get();
  }

  // 6. Toggle Like (Increment/Decrement)
  Future<void> togglePostLike(
    String postId,
    bool isCurrentlyLiked,
    String uid,
  ) async {
    final postRef = _firestore.collection('community_posts').doc(postId);

    if (isCurrentlyLiked) {
      await postRef.update({
        'likes': FieldValue.increment(-1),
        'likedBy': FieldValue.arrayRemove([uid]),
      });
    } else {
      await postRef.update({
        'likes': FieldValue.increment(1),
        'likedBy': FieldValue.arrayUnion([uid]),
      });
    }
  }

  // 7. Add Comment
  Future<void> addComment({
    required String postId,
    required String content,
    required String authorEmail,
    required String authorNickname,
    String? avatarUrl,
  }) async {
    final postRef = _firestore.collection('community_posts').doc(postId);

    final Map<String, dynamic> commentData = {
      'content': content,
      'authorEmail': authorEmail,
      'authorNickname': authorNickname,
      'timestamp': FieldValue.serverTimestamp(),
    };
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      commentData['avatarUrl'] = avatarUrl;
    }

    // Write to subcollection
    await postRef.collection('comments').add(commentData);

    // Increment comment count on parent
    await postRef.update({'comments': FieldValue.increment(1)});
  }

  // 8. Get Comments Stream
  Stream<QuerySnapshot> getCommentsStream(String postId) {
    return _firestore
        .collection('community_posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: false) // Chronological
        .snapshots();
  }

  // 9. Report Post
  Future<void> reportPost({
    required String postId,
    required String reason,
    required String reportedBy,
  }) async {
    final postRef = _firestore.collection('community_posts').doc(postId);

    // Get authorEmail first to deduct points
    String authorEmail = '';
    try {
      final snap = await postRef.get();
      if (snap.exists) {
        authorEmail = snap.data()?['authorEmail'] ?? '';
      }
    } catch (e) {
      debugPrint('Error getting post author email: $e');
    }

    await postRef.set({
      'isReported': true,
      'reportReason': reason,
      'reportedBy': reportedBy,
      'reportedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Recount/sync points for the author to deduct the point
    if (authorEmail.isNotEmpty) {
      await incrementUserContributions(authorEmail);
    }
  }

  // 10. Delete Comment
  Future<void> deleteComment(String postId, String commentId) async {
    final postRef = _firestore.collection('community_posts').doc(postId);
    await postRef.collection('comments').doc(commentId).delete();

    // Decrement comment count on parent but prevent it from going below 0
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);
      if (snapshot.exists) {
        final currentCount = snapshot.data()?['comments'] as int? ?? 0;
        transaction.update(postRef, {
          'comments': currentCount > 0 ? currentCount - 1 : 0,
        });
      }
    });
  }

  // 10b. Update Comment
  Future<void> updateComment(
    String postId,
    String commentId,
    String newText,
  ) async {
    await _firestore
        .collection('community_posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .update({
          'content': newText,
          'editedAt': FieldValue.serverTimestamp(),
          'isEdited': true,
        });
  }

  // 11. Get Announcements Stream
  Stream<QuerySnapshot> getAnnouncementsStream() {
    return _firestore
        .collection('announcements')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // 12. Get User Contributions
  Future<List<Map<String, dynamic>>> getUserContributions(String email) async {
    if (email.isEmpty) return [];

    try {
      final List<Map<String, dynamic>> items = [];
      final currentYear = DateTime.now().year;

      // A. Fetch Posts
      final postSnap = await _firestore
          .collection('community_posts')
          .where('authorEmail', isEqualTo: email)
          .get();

      for (var doc in postSnap.docs) {
        final data = doc.data();
        final timestamp = data['timestamp'] as Timestamp?;
        final date = timestamp?.toDate() ?? DateTime.now();
        if (date.year != currentYear) continue; // Only current year

        items.add({
          'id': doc.id,
          'type': 'Post',
          'title': data['content'] ?? '',
          'content': data['content'] ?? '',
          'bgGradient': data['bgGradient'] as String?,
          'subtitle': 'Published in Community Feed',
          'timestamp': date,
          'status': data['isReported'] == true ? 'reported' : 'active',
        });
      }

      // B. Fetch Song Submissions
      final songSnap = await _firestore
          .collection('song_submissions')
          .where('submittedBy', isEqualTo: email)
          .get();

      for (var doc in songSnap.docs) {
        final data = doc.data();
        final timestamp = data['timestamp'] as Timestamp?;
        final date = timestamp?.toDate() ?? DateTime.now();
        if (date.year != currentYear) continue; // Only current year

        items.add({
          'id': doc.id,
          'type': 'Song Suggestion',
          'title': data['title'] ?? 'Untitled Song',
          'author': data['author'] ?? 'Unknown',
          'category': data['category'] ?? 'Worship',
          'subtitle': 'Suggested under "${data['category'] ?? 'Worship'}"',
          'lyrics': data['lyrics'] ?? '',
          'chords': data['chords'] ?? '',
          'submittedBy': data['submittedBy'] ?? email,
          'timestamp': date,
          'status': (data['status'] ?? 'pending').toString().toLowerCase(),
        });
      }

      // C. Fetch Center Updates
      final updateSnap = await _firestore
          .collection('center_updates')
          .where('submittedBy', isEqualTo: email)
          .get();

      for (var doc in updateSnap.docs) {
        final data = doc.data();
        final timestamp = data['timestamp'] as Timestamp?;
        final date = timestamp?.toDate() ?? DateTime.now();
        if (date.year != currentYear) continue; // Only current year

        final updateType = data['updateType'] ?? 'Info update';
        final payload = data['payload'] as Map<String, dynamic>? ?? {};

        String details = '';
        if (updateType == 'Contact Person') {
          details =
              'Contact Person: ${payload['contactPerson'] ?? payload['contactName'] ?? 'N/A'}\nContact Number: ${payload['contactNumber'] ?? 'N/A'}';
        } else if (updateType == 'Facebook Page') {
          details =
              'Facebook Page: ${payload['facebookPage'] ?? payload['centerpage'] ?? 'N/A'}';
        } else if (updateType == 'Center History') {
          details = 'History: ${payload['historyText'] ?? 'N/A'}';
        } else if (updateType == 'New Center Suggestion') {
          details =
              'Contact: ${payload['contactPerson'] ?? 'N/A'}\nPhone: ${payload['contactNumber'] ?? 'N/A'}\nFacebook: ${payload['facebookPage'] ?? 'N/A'}';
        } else {
          details =
              'Coordinates: ${payload['latLng'] ?? payload['latitude'] ?? 'N/A'}\nMaps URL: ${payload['mapsLink'] ?? payload['mapsUrl'] ?? 'N/A'}';
        }

        items.add({
          'id': doc.id,
          'type': 'Center Update',
          'title': data['centerName'] ?? 'Center Update',
          'subtitle': 'Suggested: $updateType',
          'details': details,
          'timestamp': date,
          'status': data['status'] ?? 'pending',
        });
      }

      // Sort chronological descending
      items.sort((a, b) {
        final DateTime tA = a['timestamp'] as DateTime;
        final DateTime tB = b['timestamp'] as DateTime;
        return tB.compareTo(tA);
      });

      return items;
    } catch (e) {
      debugPrint('Error loading user contributions: $e');
      return [];
    }
  }

  // 13. Delete Community Post
  Future<void> deleteCommunityPost(String postId) async {
    await _firestore.collection('community_posts').doc(postId).delete();
  }

  // 14. Delete Song Submission
  Future<void> deleteSongSubmission(String songId) async {
    await _firestore.collection('song_submissions').doc(songId).delete();
  }

  // 15. Delete Center Update
  Future<void> deleteCenterUpdate(String updateId) async {
    await _firestore.collection('center_updates').doc(updateId).delete();
  }

  // 16. Get Center Members by Name & Address
  Future<List<Map<String, dynamic>>> getCenterMembers(
    String centerName,
    String centerAddress,
  ) async {
    if (centerName.isEmpty) return [];
    try {
      final query = await _firestore
          .collection('users')
          .where('centerName', isEqualTo: centerName)
          .where('centerAddress', isEqualTo: centerAddress)
          .get();

      final List<Map<String, dynamic>> members = [];
      for (var doc in query.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        if (!data.containsKey('email') ||
            (data['email'] as String? ?? '').isEmpty) {
          data['email'] = doc.id;
        }
        members.add(data);
      }
      return members;
    } catch (e) {
      debugPrint('Error getting center members: $e');
      return [];
    }
  }

  // 17. Record or Toggle Center Visit
  Future<void> toggleCenterVisit({
    required String centerName,
    required String centerAddress,
    required UserProfile profile,
    required bool isVisiting,
  }) async {
    if (centerName.trim().isEmpty || profile.email.trim().isEmpty) return;
    final visitDocId = '${centerName.trim().toLowerCase()}_${profile.email.trim().toLowerCase()}'
        .replaceAll(RegExp(r'[^\w]'), '_');

    final docRef = _firestore.collection('center_visits').doc(visitDocId);

    if (isVisiting) {
      await docRef.set({
        'centerName': centerName.trim(),
        'centerAddress': centerAddress.trim(),
        'userEmail': profile.email.trim(),
        'nickname': profile.nickname.trim().isNotEmpty
            ? profile.nickname.trim()
            : 'Member',
        'avatarUrl': profile.avatarUrl,
        'avatarPath': profile.avatarPath,
        'homeCenter': profile.localCenter.trim(),
        'position': profile.position.trim(),
        'visitedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await docRef.delete();
    }
  }

  // 18. Stream Center Visitors
  Stream<List<Map<String, dynamic>>> streamCenterVisitors(String centerName) {
    if (centerName.trim().isEmpty) return Stream.value([]);
    return _firestore
        .collection('center_visits')
        .where('centerName', isEqualTo: centerName.trim())
        .snapshots()
        .map((snapshot) {
      final List<Map<String, dynamic>> visitors = [];
      for (var doc in snapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        if (!data.containsKey('id')) data['id'] = doc.id;
        visitors.add(data);
      }
      return visitors;
    });
  }

  // 18b. Stream Visited Centers for a Specific Member
  Stream<List<Map<String, dynamic>>> streamUserVisitedCenters(String userEmail) {
    final cleanEmail = userEmail.trim().toLowerCase();
    if (cleanEmail.isEmpty) return Stream.value([]);
    final emails = {cleanEmail, userEmail.trim()}.where((e) => e.isNotEmpty).toList();

    return _firestore
        .collection('center_visits')
        .where('userEmail', whereIn: emails)
        .snapshots()
        .map((snapshot) {
      final List<Map<String, dynamic>> visits = [];
      final Set<String> seenCenters = {};
      for (var doc in snapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        if (!data.containsKey('id')) data['id'] = doc.id;
        final cName = (data['centerName'] as String?)?.trim() ?? '';
        if (cName.isNotEmpty && !seenCenters.contains(cName.toLowerCase())) {
          seenCenters.add(cName.toLowerCase());
          visits.add(data);
        }
      }
      visits.sort((a, b) {
        final Timestamp? tA = a['visitedAt'] as Timestamp?;
        final Timestamp? tB = b['visitedAt'] as Timestamp?;
        if (tA == null) return 1;
        if (tB == null) return -1;
        return tB.compareTo(tA);
      });
      return visits;
    });
  }

  // 18c. Get Visited Centers for a Specific Member
  Future<List<Map<String, dynamic>>> getUserVisitedCenters(String userEmail) async {
    final cleanEmail = userEmail.trim().toLowerCase();
    if (cleanEmail.isEmpty) return [];
    final emails = {cleanEmail, userEmail.trim()}.where((e) => e.isNotEmpty).toList();

    try {
      final query = await _firestore
          .collection('center_visits')
          .where('userEmail', whereIn: emails)
          .get();

      final List<Map<String, dynamic>> visits = [];
      final Set<String> seenCenters = {};
      for (var doc in query.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        if (!data.containsKey('id')) data['id'] = doc.id;
        final cName = (data['centerName'] as String?)?.trim() ?? '';
        if (cName.isNotEmpty && !seenCenters.contains(cName.toLowerCase())) {
          seenCenters.add(cName.toLowerCase());
          visits.add(data);
        }
      }
      visits.sort((a, b) {
        final Timestamp? tA = a['visitedAt'] as Timestamp?;
        final Timestamp? tB = b['visitedAt'] as Timestamp?;
        if (tA == null) return 1;
        if (tB == null) return -1;
        return tB.compareTo(tA);
      });
      return visits;
    } catch (e) {
      debugPrint('Error getting user visited centers: $e');
      return [];
    }
  }

  // 19. Get Center Visitors by Center Name
  Future<List<Map<String, dynamic>>> getCenterVisitors(
    String centerName,
    String centerAddress,
  ) async {
    if (centerName.isEmpty) return [];
    try {
      final query = await _firestore
          .collection('center_visits')
          .where('centerName', isEqualTo: centerName.trim())
          .get();

      final List<Map<String, dynamic>> visitors = [];
      for (var doc in query.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        if (!data.containsKey('id')) data['id'] = doc.id;
        visitors.add(data);
      }
      return visitors;
    } catch (e) {
      debugPrint('Error getting center visitors: $e');
      return [];
    }
  }

  // 20. Submit Help & Feedback Request
  Future<void> submitHelpFeedback({
    required String category,
    required String subject,
    required String message,
    required String submittedByEmail,
    required String contactNumber,
  }) async {
    await _firestore.collection('help_feedbacks').add({
      'category': category,
      'subject': subject,
      'message': message,
      'submittedBy': submittedByEmail,
      'contactNumber': contactNumber,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
      'adminReply': '',
    });
  }

  // 18. Get User Help & Feedbacks
  Future<List<Map<String, dynamic>>> getUserHelpFeedbacks(String email) async {
    if (email.isEmpty) return [];
    try {
      final query = await _firestore
          .collection('help_feedbacks')
          .where('submittedBy', isEqualTo: email)
          .get();

      final List<Map<String, dynamic>> items = [];
      for (var doc in query.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        items.add(data);
      }

      // Sort by timestamp descending
      items.sort((a, b) {
        final Timestamp? tA = a['timestamp'] as Timestamp?;
        final Timestamp? tB = b['timestamp'] as Timestamp?;
        if (tA == null) return 1;
        if (tB == null) return -1;
        return tB.compareTo(tA);
      });

      return items;
    } catch (e) {
      debugPrint('Error getting user feedbacks: $e');
      return [];
    }
  }
}

class UserContributionsCache {
  static final Map<String, int> _cache = {};
  static final Map<String, bool> _pending = {};

  static int? get(String nickname) => _cache[nickname.toLowerCase()];

  static Future<int> load(String nickname) async {
    final key = nickname.toLowerCase();
    if (_cache.containsKey(key)) return _cache[key]!;
    if (_pending[key] == true) return 0;
    _pending[key] = true;

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isEqualTo: nickname)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        final val = query.docs.first.data()['contributions'] as int? ?? 0;
        _cache[key] = val;
        return val;
      }
    } catch (e) {
      debugPrint('Error loading user contributions count: $e');
    } finally {
      _pending[key] = false;
    }
    return 0;
  }

  static void updateCache(String nickname, int val) {
    _cache[nickname.toLowerCase()] = val;
  }
}
