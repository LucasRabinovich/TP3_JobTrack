import 'package:flutter/material.dart';
import 'package:job_track/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController(); 

  String _selectedEducation = 'Terciario en curso';
  String _selectedModality = 'Híbrido';

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  final List<String> _educationOptions = [
    'Secundario Completo',
    'Terciario en curso',
    'Terciario Completo',
    'Universitario en curso',
    'Universitario Completo',
    'Autodidacta / Bootcamps'
  ];

  final List<String> _modalityOptions = ['Remoto', 'Híbrido', 'Presencial'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _titleController.dispose();
    _phoneController.dispose(); 
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(email);
  }

  void _handleRegister() async {
    if (_isLoading) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final title = _titleController.text.trim();
    final phone = _phoneController.text.trim(); 

    if (name.isEmpty || email.isEmpty || password.isEmpty || title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos obligatorios'),
        ),
      );
      return;
    }

    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Formato de email inválido'),
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La contraseña debe tener al menos 6 caracteres'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await _authService.registerUser(
        email: email,
        password: password,
        name: name,
      );
      
      final uid = userCredential.user!.uid;
      
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'name': name,
        'role': 'candidato',
        'professionalTitle': title,
        'educationLevel': _selectedEducation,
        'preferredModality': _selectedModality,
        'phone': phone, 
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Perfil de candidato creado con éxito!'),
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const brutalistBorder = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: Colors.black, width: 2.0),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F4F4),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'JOBTRACKER',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.black),
              ),
              const SizedBox(height: 32),
              
              const Text(
                'PERFIL DEL CANDIDATO',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.black),
              ),
              const SizedBox(height: 8),
              
              Text(
                'Completá tus datos profesionales para que las empresas te encuentren.',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 32),

              const Text(
                'NOMBRE COMPLETO *',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                keyboardType: TextInputType.name,
                style: const TextStyle(fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  hintText: '', 
                  hintStyle: TextStyle(color: Colors.grey),
                  filled: true, fillColor: Colors.white,
                  enabledBorder: brutalistBorder, focusedBorder: brutalistBorder, contentPadding: EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'TITULAR PROFESIONAL *',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                style: const TextStyle(fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  hintText: 'Ej. Analista Programador / Backend Node.js',
                  hintStyle: TextStyle(color: Colors.grey),
                  filled: true, fillColor: Colors.white,
                  enabledBorder: brutalistBorder, focusedBorder: brutalistBorder, contentPadding: EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'FORMACIÓN ACADÉMICA',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedEducation, 
                icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                style: const TextStyle(fontFamily: 'monospace', color: Colors.black, fontSize: 16),
                decoration: const InputDecoration(
                  filled: true, fillColor: Colors.white,
                  enabledBorder: brutalistBorder, focusedBorder: brutalistBorder, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                items: _educationOptions.map((String val) => DropdownMenuItem<String>(value: val, child: Text(val))).toList(),
                onChanged: (newValue) => setState(() => _selectedEducation = newValue!),
              ),
              const SizedBox(height: 24),

              const Text(
                'MODALIDAD DE TRABAJO PREFERIDA',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedModality, 
                icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                style: const TextStyle(fontFamily: 'monospace', color: Colors.black, fontSize: 16),
                decoration: const InputDecoration(
                  filled: true, fillColor: Colors.white,
                  enabledBorder: brutalistBorder, focusedBorder: brutalistBorder, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                items: _modalityOptions.map((String val) => DropdownMenuItem<String>(value: val, child: Text(val))).toList(),
                onChanged: (newValue) => setState(() => _selectedModality = newValue!),
              ),
              const SizedBox(height: 24),
              
              const Divider(color: Colors.black, thickness: 2),
              const SizedBox(height: 24),

              const Text(
                'EMAIL *',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  hintText: 'correo@ejemplo.com',
                  hintStyle: TextStyle(color: Colors.grey),
                  filled: true, fillColor: Colors.white,
                  enabledBorder: brutalistBorder, focusedBorder: brutalistBorder, contentPadding: EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'CONTRASEÑA *',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: TextStyle(
                  fontFamily: 'monospace',
                  letterSpacing: _obscurePassword ? 4.0 : 1.0,
                ),
                decoration: InputDecoration(
                  hintText: _obscurePassword ? '........' : 'Tu contraseña',
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    letterSpacing: _obscurePassword ? 4.0 : 1.0,
                  ),
                  filled: true, fillColor: Colors.white,
                  enabledBorder: brutalistBorder, focusedBorder: brutalistBorder, contentPadding: const EdgeInsets.all(16),
                  suffixIcon: GestureDetector(
                    onTap: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    child: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'TELÉFONO (OPCIONAL)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  hintText: 'Ej. +54 11 1234 5678',
                  hintStyle: TextStyle(color: Colors.grey),
                  filled: true, fillColor: Colors.white,
                  enabledBorder: brutalistBorder, focusedBorder: brutalistBorder, contentPadding: EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 40),

              GestureDetector(
                onTap: _handleRegister,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: _isLoading
                        ? const Color(0xFFAACC00)
                        : const Color(0xFFD4FF00),
                    border: Border.all(color: Colors.black, width: 2.0),
                    boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)],
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            height: 24, width: 24,
                            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3.0),
                          )
                        : const Text(
                            'CREAR PERFIL',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: Colors.black),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(color: Colors.black, fontSize: 14),
                      children: [
                        TextSpan(text: '¿Ya tienes cuenta? '),
                        TextSpan(
                          text: 'Ingresa aquí',
                          style: TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline, decorationThickness: 2.0),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}