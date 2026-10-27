import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JobOfferDetailScreen extends StatefulWidget {
  final String offerId;

  const JobOfferDetailScreen({
    super.key,
    required this.offerId,
  });

  @override
  State<JobOfferDetailScreen> createState() =>
      _JobOfferDetailScreenState();
}

class _JobOfferDetailScreenState extends State<JobOfferDetailScreen> {
  static const Color lime = Color(0xFFD4FF00);

  bool _isApplying = false;

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _applyToOffer(
    Map<String, dynamic> offer,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || _isApplying) return;

    setState(() => _isApplying = true);

    try {
      final firestore = FirebaseFirestore.instance;

      // Verificar que el usuario sea candidato.
      final userSnapshot = await firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (userSnapshot.data()?['role'] != 'candidato') {
        throw Exception(
          'Solo los candidatos pueden postularse.',
        );
      }

      // Evitar postulaciones duplicadas.
      final existing = await firestore
          .collection('applications')
          .where('userId', isEqualTo: user.uid)
          .where('offerId', isEqualTo: widget.offerId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        _showMessage('Ya te postulaste a esta oferta');
        return;
      }

      // Verificar que la oferta siga activa.
      final offerSnapshot = await firestore
          .collection('job_offers')
          .doc(widget.offerId)
          .get();

      if (!offerSnapshot.exists ||
          offerSnapshot.data()?['isActive'] != true) {
        _showMessage('Esta oferta ya no está disponible');
        return;
      }

      final currentOffer = offerSnapshot.data()!;

      final companyId =
          currentOffer['companyId']?.toString() ?? '';

      final companyName =
          currentOffer['companyName']?.toString() ?? 'Empresa';

      if (companyId.isEmpty) {
        throw Exception(
          'La oferta no tiene una empresa válida.',
        );
      }

      // Buscar el CV principal del candidato.
      final documentsSnapshot = await firestore
          .collection('documents')
          .where('userId', isEqualTo: user.uid)
          .get();

      final primaryDocuments = documentsSnapshot.docs.where(
        (document) {
          final data = document.data();

          return data['isPrimary'] == true &&
              data['storageType'] == 'supabase' &&
              data['type'] == 'cv' &&
              data['storagePath'] ==
                  '${user.uid}/${document.id}.pdf';
        },
      ).toList();

      if (primaryDocuments.isEmpty) {
        _showMessage(
          'Necesitás cargar un CV válido y marcarlo '
          'como principal antes de postularte.',
        );
        return;
      }

      if (primaryDocuments.length > 1) {
        throw Exception(
          'Tenés más de un CV principal. '
          'Revisá tus documentos antes de postularte.',
        );
      }

      final primaryCv = primaryDocuments.first;
      final primaryCvData = primaryCv.data();

      // Crear la postulación.
      final applicationRef =
          firestore.collection('applications').doc();

      final accessRef = firestore
          .collection('cv_access')
          .doc(user.uid)
          .collection('companies')
          .doc(companyId);

      final batch = firestore.batch();

      batch.set(applicationRef, {
        'userId': user.uid,
        'offerId': widget.offerId,
        'companyId': companyId,
        'company': companyName,
        'role': currentOffer['title'] ?? '',
        'date': Timestamp.now(),
        'status': 'POSTULADO',
        'modality': currentOffer['modality'] ?? '',
        'salary': currentOffer['salaryRange'] ?? '',
        'notes': '',
        'createdAt': FieldValue.serverTimestamp(),

        // CV utilizado en esta postulación.
        // Guardamos su referencia, no el archivo PDF.
        'cvDocumentId': primaryCv.id,
        'cvName': primaryCvData['name'] ?? 'CV.pdf',
        'cvStorageType': 'supabase',
      });

      // Conservamos el registro de acceso existente
      // para mantener compatibilidad con el proyecto.
      batch.set(accessRef, {
        'candidateId': user.uid,
        'companyId': companyId,
        'applicationId': applicationRef.id,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      _showMessage('¡Te postulaste correctamente!');

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showMessage('Error al postularse: $e');
    } finally {
      if (mounted) {
        setState(() => _isApplying = false);
      }
    }
  }

  Widget _infoBox(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.black,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
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
        foregroundColor: Colors.black,
        title: const Text(
          'DETALLE DE OFERTA',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        shape: const Border(
          bottom: BorderSide(
            color: Colors.black,
            width: 2,
          ),
        ),
      ),
      body: user == null
          ? const Center(
              child: Text(
                'Iniciá sesión',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            )
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('job_offers')
                  .doc(widget.offerId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error al cargar oferta: ${snapshot.error}',
                    ),
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
                    child: Text(
                      'Oferta no encontrada',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  );
                }

                final offer = document.data()!;
                final active = offer['isActive'] == true;

                final logoUrl =
                    offer['logoUrl']?.toString().trim() ?? '';

                final companyName =
                    offer['companyName']?.toString().trim() ??
                        'Empresa No Especificada';

                String value(String field) {
                  final text =
                      offer[field]?.toString().trim() ?? '';

                  return text.isEmpty
                      ? 'No especificado'
                      : text;
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // TARJETA PRINCIPAL
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.black,
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black,
                              offset: Offset(4, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            if (logoUrl.isNotEmpty) ...[
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                  color: const Color(0xFFF4F4F4),
                                ),
                                child: Image.network(
                                  logoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (
                                    context,
                                    error,
                                    stackTrace,
                                  ) =>
                                      const Icon(
                                    Icons.business,
                                    size: 30,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    value('title').toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    companyName.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      _infoBox(
                        'DESCRIPCIÓN Y REQUISITOS',
                        value('description'),
                      ),

                      _infoBox(
                        'MODALIDAD',
                        value('modality'),
                      ),

                      _infoBox(
                        'TIPO DE CONTRATO',
                        value('contractType'),
                      ),

                      _infoBox(
                        'SENIORITY',
                        value('seniority'),
                      ),

                      _infoBox(
                        'UBICACIÓN',
                        value('location'),
                      ),

                      _infoBox(
                        'SALARIO',
                        value('salaryRange'),
                      ),

                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: active && !_isApplying
                            ? () => _applyToOffer(offer)
                            : null,
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
                        child: _isApplying
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 3,
                                ),
                              )
                            : Text(
                                active
                                    ? 'POSTULARME AHORA'
                                    : 'OFERTA CERRADA',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
