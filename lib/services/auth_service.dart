import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    Future<User?> register(String email, String password, String role) async {
    try {
      final credential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Auth OK uid=${credential.user!.uid}');

      // <-- AÑADE ESTO
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('Firestore document created');

      await credential.user?.sendEmailVerification();
      return credential.user;
    } catch (e) {
      print('Error en register: $e');
      rethrow; // para que lo vea el widget
    }
  }

  Future<User?> login(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  // Obtener el rol del usuario actual
  Future<String?> getUserRole() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data()?['role'] as String?;
    }
    return null;
  }

  User? get currentUser => _auth.currentUser;
}
