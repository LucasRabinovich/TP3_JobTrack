
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

  Future<void> _applyToOffer(
    Map<String, dynamic> offer,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || _isApplying) return;

    setState(() => _isApplying = true);

    try {
      final firestore = FirebaseFirestore.instance;

      final existing = await firestore
          .collection('applications')
          .where('userId', isEqualTo: user.uid)
          .where('offerId', isEqualTo: widget.offerId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ya te postulaste a esta oferta'),
          ),
        );
        return;
      }

      final offerSnapshot = await firestore
          .collection('job_offers')
          .doc(widget.offerId)
          .get();

      if (!offerSnapshot.exists ||
          offerSnapshot.data()?['isActive'] != true) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Esta oferta ya no está disponible'),
          ),
        );
        return;
      }

      final currentOffer = offerSnapshot.data()!;

      await firestore.collection('applications').add({
        'userId': user.uid,
        'offerId': widget.offerId,
        'companyId': currentOffer['companyId'],
        'company': 'Empresa',
        'role': currentOffer['title'] ?? '',
        'date': Timestamp.now(),
        'status': 'POSTULADO',
        'modality': currentOffer['modality'] ?? '',
        'salary': currentOffer['salaryRange'] ?? '',
        'notes': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Te postulaste correctamente!'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al postularse: $e'),
        ),
      );
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
        border: Border.all(color: Colors.black, width: 2),
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
          Text(value),
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
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: user == null
          ? const Center(child: Text('Iniciá sesión'))
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('job_offers')
                  .doc(widget.offerId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error al cargar oferta: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  );
                }

                final document = snapshot.data!;

                if (!document.exists) {
                  return const Center(
                    child: Text('Oferta no encontrada'),
                  );
                }

                final offer = document.data()!;
                final active = offer['isActive'] == true;

                String value(String field) {
                  final text = offer[field]?.toString().trim() ?? '';
                  return text.isEmpty ? 'No especificado' : text;
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        value('title').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _infoBox('DESCRIPCIÓN Y REQUISITOS', value('description')),
                      _infoBox('MODALIDAD', value('modality')),
                      _infoBox('TIPO DE CONTRATO', value('contractType')),
                      _infoBox('SENIORITY', value('seniority')),
                      _infoBox('UBICACIÓN', value('location')),
                      _infoBox('SALARIO', value('salaryRange')),
                      const SizedBox(height: 16),
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
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                active ? 'POSTULARME' : 'OFERTA CERRADA',
                                style: const TextStyle(
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
