import 'package:da4_management/backend/dataDecryption.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'main_menu.dart';
import 'backend/control.dart';
import 'backend/dataEncryption.dart';
import 'backend/keyToken.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:da4_management/theme_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await requestNotificationPermission();
  runApp(MyApp());
}

Future<void> clearCache() async {
  try {
    Directory cacheDir = await getTemporaryDirectory();
    if (cacheDir.existsSync()) {
      cacheDir.listSync(recursive: true).forEach((entity) {
        if (entity is File) {
          entity.deleteSync();
        } else if (entity is Directory) {
          entity.deleteSync(recursive: true);
        }
      });
    }
    print('Cache cleared successfully');
  } catch (e) {
    print('Failed to clear cache: $e');
  }
}

Future<void> requestNotificationPermission() async {
  PermissionStatus statusNotification = await Permission.notification.request();
  PermissionStatus statusCamera = await Permission.camera.request();
  PermissionStatus statusStorage = await Permission.storage.request();
  if (statusNotification.isGranted) {
    // Permission granted
    // Handle notification functionality here
  } else {
    // Permission denied
    // Handle notification functionality accordingly
  }
  if (statusCamera.isGranted) {
    // Permission granted
    // Handle notification functionality here
  } else {
    // Permission denied
    // Handle notification functionality accordingly
  }
  if (statusStorage.isGranted) {
    // Permission granted
    // Handle notification functionality here
  } else {
    // Permission denied
    // Handle notification functionality accordingly
  }
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode =
      ThemeDataSetting().getThemeMode(); // Default to system theme

  void _toggleTheme() {
    print(ThemeDataSetting().getThemeMode);

    setState(() {
      if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.light;
      }
      ThemeDataSetting().setThemeMode(_themeMode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Main Menu',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      home: LoginScreen(themeVoid: _toggleTheme),
    );
  }
}

class LoginScreen extends StatefulWidget {
  final Function themeVoid;

  LoginScreen({required this.themeVoid});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  void showLoadingOverlay() {
    setState(() {
      _isLoading = true;
    });
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Stack(
          children: [
            Opacity(
              opacity: 0.3,
              child: ModalBarrier(dismissible: false, color: Colors.black),
            ),
            Center(
              child: CircularProgressIndicator(),
            ),
          ],
        );
      },
    );
  }

  void hideLoadingOverlay() {
    setState(() {
      _isLoading = false;
    });
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _showAlertDialog({
    required String title,
    required String content,
  }) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.pop(dialogContext);
              },
            ),
          ],
        );
      },
    );
  }

  bool isUserInList(String email) {
    for (var user in UserList().userList) {
      if (user['username'] == email) {
        if (user['role'] == 'admin' || user['role'] == 'superadmin') {
          loginState.username = email;
          loginState.role = user['role'];
          return true;
        }
      }
    }
    return false;
  }

  void _login() async {
    // Perform login logic here
    String email = encryptData(_emailController.text, _passwordController.text);
    String password = encryptData(_passwordController.text, KeyToken.pass);

    // Validate the login credentials
    if (email.isEmpty || password.isEmpty) {
      await _showAlertDialog(
        title: 'Error',
        content: 'Please enter email and password.',
      );
      return;
    }

    try {
      showLoadingOverlay();
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: decryptData(email, decryptData(password, KeyToken.pass)),
        password: decryptData(password, KeyToken.pass),
      );
      // Login successful, you can proceed to the next step
      if (isUserInList(
              decryptData(email, decryptData(password, KeyToken.pass))) &&
          (userCredential.user != null)) {
        clearCache();
        hideLoadingOverlay();
        await _showAlertDialog(
          title: 'Success',
          content: 'Login successful',
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MainMenu()),
        );
      } else {
        hideLoadingOverlay();
        await _showAlertDialog(
          title: 'Error',
          content: 'Login failed',
        );
      }
    } catch (e) {
      // Login failed, handle the error
      // You can display an error message or show a dialog to the user
      print('Login error: $e');
      hideLoadingOverlay();
      await _showAlertDialog(
        title: 'Error',
        content: 'Login failed',
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
        actions: [
          IconButton(
            onPressed: () {
              widget.themeVoid();
              if (isDarkMode) {
                ThemeDataSetting().setThemeMode(ThemeMode.light);
              } else {
                ThemeDataSetting().setThemeMode(ThemeMode.dark);
              }
            }, // Toggle the theme here
            icon: isDarkMode
                ? const Icon(Icons.dark_mode)
                : const Icon(Icons.light_mode),
            tooltip:
                isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
              ),
            ),
            SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: _login,
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
