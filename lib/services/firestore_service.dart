import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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
  }) async {
    await _firestore.collection('community_posts').add({
      'content': content,
      'authorEmail': authorEmail,
      'authorNickname': authorNickname,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': 0,
      'comments': 0,
    });
  }

  // 1b. Update Post
  Future<void> updateCommunityPost({
    required String postId,
    required String newContent,
    required String previousContent,
  }) async {
    await _firestore.collection('community_posts').doc(postId).update({
      'content': newContent,
      'previousContent': previousContent,
      'editedAt': FieldValue.serverTimestamp(),
      'isEdited': true,
    });
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
  }) async {
    final postRef = _firestore.collection('community_posts').doc(postId);

    // Write to subcollection
    await postRef.collection('comments').add({
      'content': content,
      'authorEmail': authorEmail,
      'authorNickname': authorNickname,
      'timestamp': FieldValue.serverTimestamp(),
    });

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
    await _firestore.collection('community_posts').doc(postId).set({
      'isReported': true,
      'reportReason': reason,
      'reportedBy': reportedBy,
      'reportedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
  Future<void> updateComment(String postId, String commentId, String newText) async {
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

      // A. Fetch Posts
      final postSnap = await _firestore
          .collection('community_posts')
          .where('authorEmail', isEqualTo: email)
          .get();
      
      for (var doc in postSnap.docs) {
        final data = doc.data();
        final timestamp = data['timestamp'] as Timestamp?;
        items.add({
          'id': doc.id,
          'type': 'Post',
          'title': data['content'] ?? '',
          'subtitle': 'Published in Community Feed',
          'timestamp': timestamp?.toDate() ?? DateTime.now(),
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
        items.add({
          'id': doc.id,
          'type': 'Song Suggestion',
          'title': data['title'] ?? 'Untitled Song',
          'subtitle': 'Suggested under "${data['category'] ?? 'Worship'}"',
          'lyrics': data['lyrics'] ?? '',
          'timestamp': timestamp?.toDate() ?? DateTime.now(),
          'status': data['status'] ?? 'pending',
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
        final updateType = data['updateType'] ?? 'Info update';
        final payload = data['payload'] as Map<String, dynamic>? ?? {};
        
        String details = '';
        if (updateType == 'Contact Person') {
          details = 'Contact Person: ${payload['contactPerson'] ?? 'N/A'}\nContact Number: ${payload['contactNumber'] ?? 'N/A'}';
        } else {
          details = 'Coordinates: ${payload['latitude'] ?? 'N/A'}, ${payload['longitude'] ?? 'N/A'}\nMaps URL: ${payload['mapsUrl'] ?? 'N/A'}';
        }

        items.add({
          'id': doc.id,
          'type': 'Center Update',
          'title': data['centerName'] ?? 'Center Update',
          'subtitle': 'Suggested: $updateType',
          'details': details,
          'timestamp': timestamp?.toDate() ?? DateTime.now(),
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
  Future<List<Map<String, dynamic>>> getCenterMembers(String centerName, String centerAddress) async {
    if (centerName.isEmpty) return [];
    try {
      final query = await _firestore
          .collection('users')
          .where('centerName', isEqualTo: centerName)
          .where('centerAddress', isEqualTo: centerAddress)
          .get();
      
      final List<Map<String, dynamic>> members = [];
      for (var doc in query.docs) {
        members.add(doc.data());
      }
      return members;
    } catch (e) {
      debugPrint('Error getting center members: $e');
      return [];
    }
  }

  // 17. Submit Help & Feedback Request
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

  // 19. Get All Help & Feedbacks (For Admin)
  Future<List<Map<String, dynamic>>> getAllHelpFeedbacks() async {
    try {
      final query = await _firestore.collection('help_feedbacks').get();

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
      debugPrint('Error getting all feedbacks: $e');
      return [];
    }
  }

  // 20. Respond to Help Feedback (Admin reply)
  Future<void> respondToHelpFeedback({
    required String ticketId,
    required String adminReply,
    required String status,
  }) async {
    await _firestore.collection('help_feedbacks').doc(ticketId).update({
      'adminReply': adminReply,
      'status': status,
      'repliedAt': FieldValue.serverTimestamp(),
    });
  }

  // 21. Get All Song Submissions (For Admin)
  Future<List<Map<String, dynamic>>> getAllSongSubmissions() async {
    try {
      final query = await _firestore.collection('song_submissions').get();

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
      debugPrint('Error getting all song submissions: $e');
      return [];
    }
  }

  // 22. Respond to Song Submission (Admin status update)
  Future<void> respondToSongSubmission({
    required String submissionId,
    required String status,
  }) async {
    await _firestore.collection('song_submissions').doc(submissionId).update({
      'status': status,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }

  // 23. Get All Registered Users (For Admin)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final query = await _firestore.collection('users').get();
      final List<Map<String, dynamic>> items = [];
      for (var doc in query.docs) {
        final data = doc.data();
        items.add(data);
      }
      // Sort by nickname/name
      items.sort((a, b) {
        final nameA = (a['name']?.toString() ?? '').toLowerCase();
        final nameB = (b['name']?.toString() ?? '').toLowerCase();
        return nameA.compareTo(nameB);
      });
      return items;
    } catch (e) {
      debugPrint('Error getting all users: $e');
      return [];
    }
  }
}
