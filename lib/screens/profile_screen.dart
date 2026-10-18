import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Importamos la pantalla de edición que creaste recién
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color lime = Color(0xFFD4FF00);
  static const Color background = Color(0xFFF4F4F4);

  
  BoxDecoration _brutalBox({Color color = Colors.white}) {
    return BoxDecoration(
      color: color,
      border: Border.all(color: Colors.black, width: 2),
      boxShadow: const [
        BoxShadow(
          color: Colors.black,
          offset: Offset(4, 4),
          blurRadius: 0,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text(
          'NO HAY USUARIO AUTENTICADO',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.black));
        }

        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};

        
        final name = (data['name'] ?? 'LUCAS M. RABINOVICH').toString().toUpperCase();
        final profession = (data['profession'] ?? 'ANALISTA DE SISTEMAS').toString().toUpperCase();
        final email = data['email'] ?? user.email ?? 'usuario@ejemplo.com';
        final location = data['location'] ?? 'Buenos Aires, Argentina';
        
        final bio = data['bio'] ?? 
            'Desarrollador enfocado en soluciones eficientes y escalables. Apasionado por la creación de interfaces accesibles y la optimización de sistemas. Buscando nuevos desafíos técnicos.';
        
        final expTitle = data['expTitle'] ?? 'Desarrollador Junior';
        final expSubtitle = data['expSubtitle'] ?? 'Tech Solutions Inc. • 2024 - Actualidad';
        final expDesc = data['expDescription'] ?? 'Implementación de nuevas funcionalidades, mantenimiento de código y despliegue de aplicaciones.';
        
        final education = data['education'] ?? 'Instituto Tecnológico de Educación Superior ORT Argentina';
        
        final List<dynamic> rawSkills = data['skills'] ?? ['Flutter', 'Dart', 'Firebase', 'Git'];
        final List<String> skills = rawSkills.map((e) => e.toString()).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'MI PERFIL',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                  GestureDetector(
                    
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: _brutalBox(color: lime),
                      child: const Text(
                        'EDITAR PERFIL',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.black, thickness: 2, height: 0),
              const SizedBox(height: 20),

              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        
                        _buildCard(
                          child: Column(
                            children: [
                              const CircleAvatar(
                                radius: 45,
                                backgroundColor: Colors.black,
                                child: Icon(Icons.person_outline, color: Colors.white, size: 50),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, height: 1.1),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                profession,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Tarjeta Contacto
                        _buildCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('CONTACTO'),
                              Text(email, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Text(location, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Tarjeta Habilidades
                        _buildCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('HABILIDADES'),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: skills.map((skill) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: lime,
                                      border: Border.all(color: Colors.black, width: 1.5),
                                    ),
                                    child: Text(
                                      skill.toUpperCase(),
                                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // --- COLUMNA DERECHA ---
                  Expanded(
                    flex: 6,
                    child: Column(
                      children: [
                        // Tarjeta Sobre Mí
                        _buildCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('SOBRE MÍ'),
                              Text(
                                bio,
                                style: const TextStyle(fontSize: 12, height: 1.4, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        
                        _buildCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('EXPERIENCIA'),
                              IntrinsicHeight(
                                child: Row(
                                  children: [
                                    Container(width: 4, color: lime), 
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            expTitle.toUpperCase(),
                                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            expSubtitle,
                                            style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            expDesc,
                                            style: const TextStyle(fontSize: 12, height: 1.4, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        
                        _buildCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('EDUCACIÓN'),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.school, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      education,
                                      style: const TextStyle(fontSize: 12, height: 1.4, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40), 
            ],
          ),
        );
      },
    );
  }

  
  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _brutalBox(),
      child: child,
    );
  }

  
  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
        ),
        const SizedBox(height: 6),
        const Divider(color: Colors.black, thickness: 1.5, height: 0),
        const SizedBox(height: 12),
      ],
    );
  }
}