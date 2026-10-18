import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const Color lime = Color(0xFFD4FF00);
  static const Color background = Color(0xFFF4F4F4);

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controladores exactamente iguales a los campos del perfil
  final _nameController = TextEditingController();
  final _professionController = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();
  final _expTitleController = TextEditingController();
  final _expSubtitleController = TextEditingController();
  final _expDescController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  Future<void> _loadCurrentData() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          
          _nameController.text = data['name'] ?? '';
          _professionController.text = data['profession'] ?? '';
          _locationController.text = data['location'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _expTitleController.text = data['expTitle'] ?? '';
          _expSubtitleController.text = data['expSubtitle'] ?? '';
          _expDescController.text = data['expDescription'] ?? '';
        }
      }
    } catch (e) {
      debugPrint('Error al cargar datos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': _nameController.text.trim(),
          'profession': _professionController.text.trim(),
          'location': _locationController.text.trim(),
          'bio': _bioController.text.trim(),
          'expTitle': _expTitleController.text.trim(),
          'expSubtitle': _expSubtitleController.text.trim(),
          'expDescription': _expDescController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PERFIL ACTUALIZADO CORRECTAMENTE', style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.black,
            ),
          );
          Navigator.pop(context); // Volver a la pantalla del perfil
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ERROR AL GUARDAR: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _professionController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _expTitleController.dispose();
    _expSubtitleController.dispose();
    _expDescController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: lime,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        shape: const Border(bottom: BorderSide(color: Colors.black, width: 2)),
        title: const Text(
          'EDITAR PERFIL',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 1),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.black))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionLabel('DATOS PERSONALES'),
                  _buildTextField(
                    controller: _nameController,
                    label: 'Nombre completo',
                    hint: 'Ej. Juan Pérez',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _professionController,
                    label: 'Profesión o Titular',
                    hint: 'Ej. Frontend Developer',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _locationController,
                    label: 'Ubicación',
                    hint: 'Ej. Buenos Aires, Argentina',
                  ),
                  
                  const SizedBox(height: 32),
                  _buildSectionLabel('SOBRE MÍ'),
                  _buildTextField(
                    controller: _bioController,
                    label: 'Descripción breve',
                    hint: 'Desarrollador web con más de 3 años de experiencia...',
                    maxLines: 4,
                  ),

                  const SizedBox(height: 32),
                  _buildSectionLabel('EXPERIENCIA PRINCIPAL'),
                  _buildTextField(
                    controller: _expTitleController,
                    label: 'Puesto',
                    hint: 'Ej. Desarrollador Frontend Semi-Senior',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _expSubtitleController,
                    label: 'Empresa y Fechas',
                    hint: 'Ej. Tech Solutions Inc. • 2021 - Actualidad',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _expDescController,
                    label: 'Descripción del rol',
                    hint: 'Implementación de diseño de sistemas...',
                    maxLines: 3,
                  ),

                  const SizedBox(height: 40),
                  
                  GestureDetector(
                    onTap: _saveProfile,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        border: Border.all(color: Colors.black, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: lime,
                            offset: Offset(4, 4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'GUARDAR CAMBIOS',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
          const Divider(color: Colors.black, thickness: 2),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    const brutalistBorder = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: Colors.black, width: 2),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.normal),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: brutalistBorder,
            focusedBorder: brutalistBorder,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}