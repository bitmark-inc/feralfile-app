import 'package:firebase_auth/firebase_auth.dart';

class AuthFiresabeService {
  static User? _user;

  // init service
  Future<void> initService() async {
    addAuthChangeListener();
  }

  bool get isSignedIn => _user != null && _user!.uid.isNotEmpty;

  Future<String> getJWTToken() {
    final token =
        'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJmaXJlYmFzZS1hZG1pbnNkay1xdG42OUBteS1maXJzdC1wcm9qZWN0LXNhbmcuaWFtLmdzZXJ2aWNlYWNjb3VudC5jb20iLCJhdWQiOiJodHRwczovL2lkZW50aXR5dG9vbGtpdC5nb29nbGVhcGlzLmNvbS9nb29nbGUuaWRlbnRpdHkuaWRlbnRpdHl0b29sa2l0LnYxLklkZW50aXR5VG9vbGtpdCIsImV4cCI6MTcwMjg3MTc0MywiaWF0IjoxNzAyODY4MTQzLCJzdWIiOiJmaXJlYmFzZS1hZG1pbnNkay1xdG42OUBteS1maXJzdC1wcm9qZWN0LXNhbmcuaWFtLmdzZXJ2aWNlYWNjb3VudC5jb20iLCJ1aWQiOiJzYW5nIn0.GBLRBUIf65vxmNzPrWBS2e_f9TdYXzO4L-YI5oLHEhwKu9nfiVVParqoun_lR57_s79ITs8-c5ZMXpVCeWpHGH6XI4GcBEz03hMSuPU-MJeGVwj14FVc_3d1lYYjBaquk_EJr_1AZZyMI9ruoHm_h02GV4X-0KfImE7kdyKpXUahCXcyvEHK-2GZ1atlfuhromRJQTTYSOVFKIkFY1rFrKftA0LWa1NC46bz_HtwrHZ3IUGbWmjhRB3q0eF92dvBv94PEQfAjNLRnHVVkHzgDZci8a01zJw_f2rwlnwu44tTqxswQfsuGdNUBK6GEyWJeSbsnuyNToiQAKNwGysftQ';
    return Future.value(token);
  }

  static void addAuthChangeListener() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _user = user;
      } else {
        _user = null;
      }
    });
  }

  User? get user => _user;

  Future<User?> signInWithCustomToken(String token) async {
    final auth = FirebaseAuth.instance;
    final userCredential = await auth.signInWithEmailAndPassword(
        email: 'sang@bitmark.com', password: 'sangbitmark');
    _user = userCredential.user;
    return user;
  }

  Future<void> signOut() async {
    final auth = FirebaseAuth.instance;
    await auth.signOut();
    _user = null;
  }
}
