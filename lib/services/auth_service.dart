import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // INICIAR SESIÓN
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // REGISTRAR CANDIDATO
  Future<UserCredential> registerUser({
    required String email,
    required String password,
    required String name,
  }) async {
    final UserCredential userCredential =
        await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;

    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': email,
        'name': name,
        'role': 'candidato',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return userCredential;
  }

  // RECUPERAR CONTRASEÑA
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(
      email: email,
    );
  }

  // CERRAR SESIÓN
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // USUARIO ACTUAL
  User? get currentUser => _auth.currentUser;
}