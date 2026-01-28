import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'models/user_profile.dart';
import 'screens/auth/login_page.dart';
import 'screens/auth/register_page.dart';
import 'screens/dashboard/dashboard_page.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('id_ID', null);
  await _ensureAdminSeeded();
  runApp(const StudyAttendanceApp());
}

class StudyAttendanceApp extends StatelessWidget {
  const StudyAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
      ],
      child: MaterialApp(
        title: 'BAROKAH PRESENSI',
        theme: _appTheme,
        home: const AuthGate(),
        routes: {
          LoginPage.routeName: (_) => const LoginPage(),
          RegisterPage.routeName: (_) => const RegisterPage(),
        },
      ),
    );
  }
}

final ThemeData _appTheme = (() {
  const navy = Color(0xFF0B1F3A);
  final baseScheme = ColorScheme.fromSeed(
    seedColor: navy,
    brightness: Brightness.dark,
  ).copyWith(secondary: Colors.grey);

  return ThemeData(
    colorScheme: baseScheme,
    scaffoldBackgroundColor: navy,
    useMaterial3: true,
    textTheme: const TextTheme().apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
  );
})();

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    return StreamBuilder<User?>(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _CenteredLoader(message: 'Memuat kredensial...');
        }
        final user = snapshot.data;
        if (user == null) {
          return const LoginPage();
        }
        return ProfileGate(userId: user.uid);
      },
    );
  }
}

class ProfileGate extends StatelessWidget {
  const ProfileGate({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    return StreamBuilder<UserProfile?>(
      stream: firestore.watchUserProfile(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _CenteredLoader(message: 'Memuat profil...');
        }
        final profile = snapshot.data;
        if (profile == null) {
          return RegisterPage(prefilledUid: userId);
        }
        return DashboardPage(profile: profile);
      },
    );
  }
}

class _CenteredLoader extends StatelessWidget {
  const _CenteredLoader({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(message),
          ],
        ),
      ),
    );
  }
}

Future<void> _ensureAdminSeeded() async {
  const adminEmail = 'adminppm@gmail.com';
  const adminPassword = 'prindingpyar354';
  final auth = FirebaseAuth.instance;
  final firestore = FirestoreService();

  try {
    final methods = await auth.fetchSignInMethodsForEmail(adminEmail);
    UserCredential credential;
    if (methods.isEmpty) {
      credential = await auth.createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );
    } else {
      credential = await auth.signInWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );
    }

    final user = credential.user;
    if (user != null) {
      final profile = UserProfile(
        uid: user.uid,
        name: 'Admin PPM',
        email: adminEmail,
        role: UserRole.pengurus,
        createdAt: DateTime.now(),
      );
      await firestore.upsertUserProfile(profile);
    }
  } catch (e) {
    debugPrint('Admin seed skipped: $e');
  } finally {
    // Ensure no session is left signed in after seeding
    await auth.signOut();
  }
}
