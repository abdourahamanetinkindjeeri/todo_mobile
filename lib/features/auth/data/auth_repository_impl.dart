import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/entities/app_user.dart';
import '../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().map((user) {
      if (user == null) return null;

      return AppUser(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? 'Utilisateur',
      );
    });
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      throw AppException(_mapAuthError(e));
    } catch (e) {
      throw AppException('Connexion impossible : $e');
    }
  }

  @override
  Future<void> signUp({
    required String displayName,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = credential.user;
      if (user == null) {
        throw const AppException('Création du compte impossible.');
      }

      await user.updateDisplayName(displayName.trim());

      await _firestore.collection('users').doc(user.uid).set({
        'email': email.trim(),
        'displayName': displayName.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      throw AppException(_mapAuthError(e));
    } on FirebaseException catch (e) {
      throw AppException(_mapFirestoreError(e));
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('Inscription impossible : $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AppException('Déconnexion impossible : $e');
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Adresse email invalide.';
      case 'user-disabled':
        return 'Ce compte est désactivé.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email ou mot de passe incorrect.';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé.';
      case 'weak-password':
        return 'Mot de passe trop faible. Minimum 6 caractères.';
      case 'operation-not-allowed':
        return 'Connexion Email/Mot de passe non activée dans Firebase.';
      case 'network-request-failed':
        return 'Problème de connexion internet. Vérifie ton réseau.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessaie plus tard.';
      case 'configuration-not-found':
        return 'Configuration Firebase introuvable. Relance flutterfire configure.';
      default:
        return 'Erreur Firebase Auth : ${e.code}';
    }
  }

  String _mapFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Accès refusé par Firestore. Vérifie les règles de sécurité.';
      case 'unavailable':
        return 'Firestore est temporairement indisponible. Réessaie plus tard.';
      case 'not-found':
        return 'Document Firestore introuvable.';
      case 'already-exists':
        return 'Ce document existe déjà.';
      case 'cancelled':
        return 'Opération annulée.';
      case 'deadline-exceeded':
        return 'La requête Firestore a pris trop de temps.';
      default:
        return 'Erreur Firestore : ${e.code}';
    }
  }
}
