import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // For now we will use the web configuration for all platforms since that's what was in the HTML.
    // In a real app, you'd add android and ios specific configurations here.
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCIuCEWRXeuCfYM9KXQ0lgk4jnxQQfAzaA',
    appId: '1:776886718939:web:946ba9fb04153a150697fe',
    messagingSenderId: '776886718939',
    projectId: 'taskmate-5f854',
    authDomain: 'taskmate-5f854.firebaseapp.com',
    storageBucket: 'taskmate-5f854.firebasestorage.app',
    measurementId: 'G-WEKXP20HC2',
  );
}
