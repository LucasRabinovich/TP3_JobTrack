import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class InterviewsScreen extends StatefulWidget {
  const InterviewsScreen({super.key});

  @override
  State<InterviewsScreen> createState() => _InterviewsScreenState();
}

class _InterviewsScreenState extends State<InterviewsScreen> {
  static const Color lime = Color(0xFFD4FF00);

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

  Future<void> _openLink(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('NO SE PUDO ABRIR EL ENLACE'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: lime,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black, size: 30),
        title: const Text(
          'MIS ENTREVISTAS',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 1),
        ),
        shape: const Border(bottom: BorderSide(color: Colors.black, width: 2)),
      ),
      body: user == null
          ? const Center(
              child: Text(
                'NO HAY USUARIO AUTENTICADO',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('interviews')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.black));
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text('ERROR AL CARGAR ENTREVISTAS', style: TextStyle(fontWeight: FontWeight.w900)),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'NO HAY ENTREVISTAS PROGRAMADAS',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final company = data['company']?.toString().toUpperCase() ?? 'EMPRESA';
                    final position = data['position']?.toString().toUpperCase() ?? 'PUESTO';
                    final dateStr = data['dateString']?.toString().toUpperCase() ?? 'FECHA Y HORA';
                    final modality = data['modality']?.toString().toUpperCase() ?? 'MODALIDAD';
                    final linkOrLocation = data['link']?.toString() ?? '';
                    final notes = data['notes']?.toString() ?? ''; // Capturamos las notas

                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: _brutalBox(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(company, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                                    const SizedBox(height: 4),
                                    Text(position, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: modality == 'VIRTUAL' ? const Color(0xFFE0E0E0) : lime,
                                  border: Border.all(color: Colors.black, width: 1.5),
                                ),
                                child: Text(modality, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Colors.black, thickness: 1.5, height: 0),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 8),
                              Text(dateStr, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            ],
                          ),
                          
                          // SECCIÓN DE INSTRUCCIONES / NOTAS
                          if (notes.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8E8E8),
                                border: Border.all(color: Colors.black, width: 1.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'INSTRUCCIONES:',
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.black54),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    notes,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          if (linkOrLocation.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: modality == 'VIRTUAL' ? () => _openLink(linkOrLocation) : null,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: _brutalBox(color: modality == 'VIRTUAL' ? lime : Colors.white),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(modality == 'VIRTUAL' ? Icons.videocam : Icons.location_on, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      modality == 'VIRTUAL' ? 'UNIRSE A LA LLAMADA' : linkOrLocation.toUpperCase(),
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}