import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';

class CommunityProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<CommunityModel> _communities = [];
  List<PostModel> _posts = [];
  CommunityModel? _selectedCommunity;
  bool _isLoading = false;
  String _postText = '';

  // ─── Getters ────────────────────────────────────────────────────────────────
  List<CommunityModel> get communities => _communities;
  
  // Return all posts if no community is selected, else filter by selected community.
  List<PostModel> get filteredPosts {
    if (_selectedCommunity == null) return _posts;
    return _posts.where((p) => p.communityId == _selectedCommunity!.id).toList();
  }
  
  CommunityModel? get selectedCommunity => _selectedCommunity;
  bool get isLoading => _isLoading;
  String get postText => _postText;

  // ─── Init (Firestore) ─────────────────────────────────────────────────────
  Future<void> loadCommunityData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Fetch communities
      final commSnap = await _firestore.collection('communities').get();
      _communities = commSnap.docs
          .map((doc) => CommunityModel.fromJson(doc.data(), doc.id))
          .toList();

      // Fetch posts (ordered by createdAt descending)
      final postsSnap = await _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .get();
      _posts = postsSnap.docs
          .map((doc) => PostModel.fromJson(doc.data(), doc.id))
          .toList();

    } catch (e) {
      debugPrint('Error loading community data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Select Community ────────────────────────────────────────────────────────
  void selectCommunity(CommunityModel? community) {
    _selectedCommunity = community;
    notifyListeners();
  }

  // ─── Like / Unlike ──────────────────────────────────────────────────────────
  void toggleLike(String postId, String userId) {
    if (userId.isEmpty) return;

    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _posts[index];
      
      final List<String> updatedLikedBy = List.from(post.likedBy);
      
      if (updatedLikedBy.contains(userId)) {
        updatedLikedBy.remove(userId);
      } else {
        updatedLikedBy.add(userId);
      }

      final newCount = updatedLikedBy.length;

      _posts[index] = post.copyWith(
        likedBy: updatedLikedBy,
        likeCount: newCount,
      );
      notifyListeners();

      // Update Firestore in the background
      _firestore.collection('posts').doc(postId).update({
        'likedBy': updatedLikedBy,
        'likeCount': newCount,
      });
    }
  }

  // ─── Post Text ──────────────────────────────────────────────────────────────
  void updatePostText(String text) {
    _postText = text;
    notifyListeners();
  }

  // ─── Publish Post ────────────────────────────────────────────────────────────
  Future<void> publishPost({
    required String userId,
    required String userName,
    required String userAvatarUrl,
    required String userLocation,
  }) async {
    if (_postText.trim().isEmpty) return;

    // Use selected community if available, otherwise fallback (we'll just use a generic 'General' or fail)
    if (_selectedCommunity == null && _communities.isEmpty) return;
    final targetCommunity = _selectedCommunity ?? _communities.first;

    final newPost = PostModel(
      id: 'post_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId.isEmpty ? 'current_user' : userId,
      userName: userName,
      userAvatarUrl: userAvatarUrl,
      userLocation: userLocation,
      communityId: targetCommunity.id,
      communityName: targetCommunity.name.toUpperCase(),
      caption: _postText.trim(),
      likeCount: 0,
      commentCount: 0,
      likedBy: [],
      createdAt: DateTime.now(),
    );

    _posts.insert(0, newPost);
    _postText = '';
    notifyListeners();

    // Save to Firestore
    await _firestore.collection('posts').doc(newPost.id).set(newPost.toJson());
  }

  // ─── Add Comment ────────────────────────────────────────────────────────────
  Future<void> addComment({
    required String postId,
    required String userId,
    required String userName,
    required String userAvatarUrl,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;

    final commentId = 'comment_${DateTime.now().millisecondsSinceEpoch}';
    final newComment = CommentModel(
      id: commentId,
      postId: postId,
      userId: userId,
      userName: userName,
      userAvatarUrl: userAvatarUrl,
      text: text.trim(),
      createdAt: DateTime.now(),
    );

    // Save to Firestore subcollection
    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .set(newComment.toJson());

    // Increment comment count
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _posts[index];
      final newCount = post.commentCount + 1;
      _posts[index] = post.copyWith(commentCount: newCount);
      notifyListeners();

      await _firestore.collection('posts').doc(postId).update({
        'commentCount': newCount,
      });
    }
  }

  // Stream comments for a post
  Stream<List<CommentModel>> getCommentsStream(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommentModel.fromJson(doc.data(), doc.id))
            .toList());
  }
}
