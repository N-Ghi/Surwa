import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class FollowService {

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Get current logged-in user
  auth.User? get currentUser => auth.FirebaseAuth.instance.currentUser;
  
  // Follow a user
  Future<void> followUser(String targetUserId) async {
    String currentUserId = currentUser!.uid;
    DocumentReference currentUserRef = firestore.collection('Profile').doc(currentUserId);
    DocumentReference targetUserRef = firestore.collection('Profile').doc(targetUserId);

    await firestore.runTransaction((transaction) async {
      DocumentSnapshot currentUserSnapshot = await transaction.get(currentUserRef);
      DocumentSnapshot targetUserSnapshot = await transaction.get(targetUserRef);

      if (!currentUserSnapshot.exists || !targetUserSnapshot.exists) return;

      List following = List.from(currentUserSnapshot['following'] ?? []);
      List followers = List.from(targetUserSnapshot['followers'] ?? []);

      if (!following.contains(targetUserId)) {
        following.add(targetUserId);
        followers.add(currentUserId);
        
        transaction.update(currentUserRef, {'following': following});
        transaction.update(targetUserRef, {'followers': followers});
      }
    });
  }
}