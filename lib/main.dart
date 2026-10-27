import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import 'firebase_options.dart';
import 'package:job_track/screens/login_screen.dart';
import 'package:job_track/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar las variables de configuración desde .env.
  await dotenv.load(fileName: '.env');

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabasePublishableKey =
      dotenv.env['SUPABASE_PUBLISHABLE_KEY'];

  // Validar la configuración antes de iniciar.
  if (supabaseUrl == null ||
      supabaseUrl.isEmpty ||
      !Uri.parse(supabaseUrl).hasAuthority) {
    throw StateError(
      'SUPABASE_URL no está configurada correctamente en .env',
    );
  }

  if (supabasePublishableKey == null ||
      supabasePublishableKey.isEmpty) {
    throw StateError(
      'SUPABASE_PUBLISHABLE_KEY no está configurada en .env',
    );
  }

  // Inicializar Firebase.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializar Supabase.
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
    accessToken: () async {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return null;
      }

      // Comprobación temporal del rol del token Firebase.
      final tokenResult = await user.getIdTokenResult(true);

      debugPrint(
        'ROL SUPABASE: ${tokenResult.claims?['role'] ?? 'SIN CONFIGURAR'}',
      );

      return tokenResult.token;
    },
  );

  runApp(const MiApp());
}

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JobTrack',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: Colors.black,
                ),
              ),
            );
          }

          if (snapshot.hasData) {
            return const HomeScreen();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}


