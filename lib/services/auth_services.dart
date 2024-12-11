


import 'package:firebase_auth/firebase_auth.dart';

class AuthServices{
  FirebaseAuth firbaseAuth= FirebaseAuth.instance;

  // Register User

  Future registerUser(String email, String password)async{
    UserCredential userCredential = await firbaseAuth.createUserWithEmailAndPassword(email: email, password: password);
    return userCredential.user;
  }

  // Register User

  Future LoginUser(String email, String password)async{
    UserCredential userCredential = await firbaseAuth.signInWithEmailAndPassword(email: email, password: password);
    return userCredential.user;
  }

}