// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCOK4xHCIyydF1DNHhgGfONo_IDT9NHfBo',
    appId: '1:775588754611:web:69149fb5de5bf99188acc6',
    messagingSenderId: '775588754611',
    projectId: 'da4management',
    authDomain: 'da4management.firebaseapp.com',
    storageBucket: 'da4management.appspot.com',
    measurementId: 'G-Y0JL6345S8',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDcSLK3_np2ZJOcNQ1wN-F8HhwQIyB7Xyw',
    appId: '1:775588754611:android:4788160106e0fb3f88acc6',
    messagingSenderId: '775588754611',
    projectId: 'da4management',
    storageBucket: 'da4management.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBsC0oZS0p_zG273YWAyqPFyYRpVHYEQsM',
    appId: '1:775588754611:ios:04a70e4be8956aac88acc6',
    messagingSenderId: '775588754611',
    projectId: 'da4management',
    storageBucket: 'da4management.appspot.com',
    iosClientId:
        '775588754611-h97k0to4pf1snql3jf7mark9chjti06s.apps.googleusercontent.com',
    iosBundleId: 'com.example.da4Management',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBsC0oZS0p_zG273YWAyqPFyYRpVHYEQsM',
    appId: '1:775588754611:ios:2e935aa2cdd36f8288acc6',
    messagingSenderId: '775588754611',
    projectId: 'da4management',
    storageBucket: 'da4management.appspot.com',
    iosClientId:
        '775588754611-dflf8k1fhchncs3dfmnvsfr2rto6e5hk.apps.googleusercontent.com',
    iosBundleId: 'com.example.da4Management.RunnerTests',
  );
}
