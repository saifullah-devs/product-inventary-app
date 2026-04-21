class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final GoogleSignIn googleSignIn;
  final FirebaseFirestore firestore;

  AuthRemoteDataSourceImpl(this.firebaseAuth, this.googleSignIn, this.firestore);

  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    try {
      final credential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return await _adminCheck(credential.user);
    } on FirebaseAuthException catch (e) {
      throw ServerException(message: e.message ?? 'Auth Failed');
    }
  }

  Future<UserModel> _adminCheck(User? user) async {
    if (user == null) throw const ServerException(message: 'User null');
    
    final doc = await firestore.collection('admins').doc(user.uid).get();
    if (!doc.exists) {
      await firebaseAuth.signOut();
      throw const UnauthorizedException(message: 'Access Restricted to Admins');
    }
    return UserModel.fromFirebase(user);
  }
  }