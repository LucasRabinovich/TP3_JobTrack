import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:job_track/screens/login_screen.dart';
import 'package:job_track/screens/applications_screen.dart';
import 'package:job_track/screens/interviews_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        title: const Text(
          'INICIO',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        backgroundColor: const Color(0xFFD4FF00),
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 32,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '¡Bienvenido a JobTrack!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Organiza tus postulaciones y realiza el seguimiento '
                'de tu búsqueda laboral.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),

              const SizedBox(height: 40),

              // BOTÓN: POSTULACIONES
              _buildNavigationButton(
                text: 'VER POSTULACIONES',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ApplicationsScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // BOTÓN: ENTREVISTAS
              _buildNavigationButton(
                text: 'VER ENTREVISTAS',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const InterviewsScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // BOTÓN: CERRAR SESIÓN
              ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();

                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const LoginScreen(),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 18,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: const Text(
                  'CERRAR SESIÓN',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFD4FF00),
          border: Border.all(
            color: Colors.black,
            width: 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}