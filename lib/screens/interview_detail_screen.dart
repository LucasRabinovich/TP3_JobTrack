import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class InterviewDetailScreen extends StatefulWidget {
  final String interviewId;

  const InterviewDetailScreen({
    super.key,
    required this.interviewId,
  });

  @override
  State<InterviewDetailScreen> createState() =>
      _InterviewDetailScreenState();
}

class _InterviewDetailScreenState extends State<InterviewDetailScreen> {
  static const Color lime = Color(0xFFD4FF00);

  final TextEditingController _notesController =
      TextEditingController();

  bool _isSaving = false;
  bool _notesInitialized = false;
  String _attendanceStatus = 'PENDIENTE';

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('interviews')
          .doc(widget.interviewId)
          .update({
        'attendanceStatus': _attendanceStatus,
        'candidateNotes': _notesController.text.trim(),
        'candidateUpdatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cambios guardados correctamente'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _infoBox(String title, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: lime,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'DETALLE DE ENTREVISTA',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.black,
            fontSize: 17,
          ),
        ),
      ),
      body: user == null
          ? const Center(child: Text('Iniciá sesión'))
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('interviews')
                  .doc(widget.interviewId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Error al cargar entrevista'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.black,
                    ),
                  );
                }

                final document = snapshot.data!;

                if (!document.exists) {
                  return const Center(
                    child: Text('Entrevista no encontrada'),
                  );
                }

                final data = document.data()!;

                if (data['userId'] != user.uid) {
                  return const Center(
                    child: Text('No tenés acceso a esta entrevista'),
                  );
                }

                if (!_notesInitialized) {
                  _notesController.text =
                      (data['candidateNotes'] ?? '').toString();

                  final savedStatus =
                      (data['attendanceStatus'] ?? 'PENDIENTE')
                          .toString();

                  _attendanceStatus = [
                    'PENDIENTE',
                    'CONFIRMADA',
                    'REPROGRAMACION_SOLICITADA',
                  ].contains(savedStatus)
                      ? savedStatus
                      : 'PENDIENTE';

                  _notesInitialized = true;
                }

                final date =
                    (data['date'] as Timestamp?)?.toDate();

                final company =
                    (data['company'] ?? 'Sin empresa').toString();

                final role =
                    (data['role'] ?? 'Sin puesto').toString();

                final platform =
                    (data['platform'] ?? 'No especificada').toString();

                final type =
                    (data['type'] ?? 'No especificado').toString();

                final interviewer =
                    (data['interviewer'] ?? '').toString();

                final link =
                    (data['link'] ?? '').toString();
                    
                final companyNotes = 
                    (data['notes'] ?? '').toString(); // Extraemos las notas de la empresa

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        company.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        role,
                        style: const TextStyle(fontSize: 17),
                      ),
                      const SizedBox(height: 24),

                      _infoBox(
                        'FECHA',
                        date == null
                            ? (data['dateString'] ?? 'No disponible').toString() // Fallback a dateString por si se programó desde la nueva función
                            : _formatDate(date),
                      ),

                      _infoBox(
                        'HORA',
                        date == null
                            ? 'Ver fecha'
                            : _formatTime(date),
                      ),

                      _infoBox('TIPO DE ENTREVISTA', type != 'No especificado' ? type : (data['modality'] ?? 'No especificado').toString()), // Fallback a modality
                      _infoBox('PLATAFORMA', platform),

                      if (interviewer.isNotEmpty)
                        _infoBox('ENTREVISTADOR', interviewer),

                      // ACÁ MOSTRAMOS LAS NOTAS DE LA EMPRESA
                      if (companyNotes.isNotEmpty)
                        _infoBox('INSTRUCCIONES DE LA EMPRESA', companyNotes),

                      if (link.isNotEmpty) ...[
                        _infoBox('LINK / DIRECCIÓN', link),
                        TextButton.icon(
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: link),
                            );

                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text('Enlace copiado'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy),
                          label: const Text('COPIAR ENLACE'),
                        ),
                      ],

                      const SizedBox(height: 20),

                      const Text(
                        'MI ASISTENCIA',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),

                      DropdownButtonFormField<String>(
                        key: ValueKey(_attendanceStatus),
                        initialValue: _attendanceStatus,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(
                              color: Colors.black,
                              width: 2,
                            ),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'PENDIENTE',
                            child: Text('PENDIENTE'),
                          ),
                          DropdownMenuItem(
                            value: 'CONFIRMADA',
                            child: Text('CONFIRMAR ASISTENCIA'),
                          ),
                          DropdownMenuItem(
                            value: 'REPROGRAMACION_SOLICITADA',
                            child: Text('SOLICITAR REPROGRAMACIÓN'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _attendanceStatus = value;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 28),

                      const Text(
                        'MIS NOTAS PERSONALES',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),

                      TextField(
                        controller: _notesController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText:
                              'Preguntas para la entrevista, '
                              'temas para preparar...',
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(
                              color: Colors.black,
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(
                              color: Colors.black,
                              width: 2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      ElevatedButton(
                        onPressed:
                            _isSaving ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: lime,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.all(18),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                            side: BorderSide(
                              color: Colors.black,
                              width: 2,
                            ),
                          ),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.black,
                              )
                            : const Text(
                                'GUARDAR CAMBIOS',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}