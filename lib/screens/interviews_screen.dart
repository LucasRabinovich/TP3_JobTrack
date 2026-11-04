
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

  bool _showHistory = false;

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

    final uri = Uri.tryParse(url);

    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('NO SE PUDO ABRIR EL ENLACE'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSectionButton(String title, bool history) {
    final selected = _showHistory == history;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showHistory = history;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? lime : Colors.white,
            border: Border.all(
              color: Colors.black,
              width: 2,
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInterviewCard(Map<String, dynamic> data) {
    final company =
        data['company']?.toString().toUpperCase() ?? 'EMPRESA';

    final position =
        data['position']?.toString().toUpperCase() ?? 'PUESTO';

    final dateStr =
        data['dateString']?.toString().toUpperCase() ?? 'FECHA Y HORA';

    final modality =
        data['modality']?.toString().toUpperCase() ?? 'MODALIDAD';

    final linkOrLocation = data['link']?.toString() ?? '';
    final notes = data['notes']?.toString() ?? '';

    final decision =
        data['decisionStatus']?.toString().toUpperCase() ?? '';

    final isAccepted = decision == 'ACEPTADO';
    final isRejected = decision == 'RECHAZADO';
    final hasDecision = isAccepted || isRejected;

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
                    Text(
                      company,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      position,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: modality == 'VIRTUAL'
                      ? const Color(0xFFE0E0E0)
                      : lime,
                  border: Border.all(
                    color: Colors.black,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  modality,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isAccepted
                  ? lime
                  : isRejected
                      ? const Color(0xFFFFA6A6)
                      : const Color(0xFFE8E8E8),
              border: Border.all(
                color: Colors.black,
                width: 1.5,
              ),
            ),
            child: Text(
              hasDecision ? decision : 'PENDIENTE',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),

          if (hasDecision) ...[
            const SizedBox(height: 10),
            Text(
              isAccepted
                  ? 'LA EMPRESA ACEPTÓ TU POSTULACIÓN.'
                  : 'LA EMPRESA RECHAZÓ TU POSTULACIÓN.',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(
            color: Colors.black,
            thickness: 1.5,
            height: 0,
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dateStr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),

          if (notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8E8E8),
                border: Border.all(
                  color: Colors.black,
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'INSTRUCCIONES:',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notes,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (linkOrLocation.isNotEmpty) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: modality == 'VIRTUAL'
                  ? () => _openLink(linkOrLocation)
                  : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                decoration: _brutalBox(
                  color: modality == 'VIRTUAL'
                      ? lime
                      : Colors.white,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      modality == 'VIRTUAL'
                          ? Icons.videocam
                          : Icons.location_on,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        modality == 'VIRTUAL'
                            ? 'UNIRSE A LA LLAMADA'
                            : linkOrLocation.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.black,
          size: 30,
        ),
        title: const Text(
          'MIS ENTREVISTAS',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.black,
            letterSpacing: 1,
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
                'NO HAY USUARIO AUTENTICADO',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      _buildSectionButton('ACTIVAS', false),
                      const SizedBox(width: 8),
                      _buildSectionButton('HISTORIAL', true),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('interviews')
                        .where('userId', isEqualTo: user.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text(
                            'ERROR AL CARGAR ENTREVISTAS',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
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

                      final docs = snapshot.data!.docs;

                      final filteredDocs = docs.where((doc) {
                        final data =
                            doc.data() as Map<String, dynamic>;

                        final decision = data['decisionStatus']
                                ?.toString()
                                .toUpperCase() ??
                            '';

                        final hasDecision =
                            decision == 'ACEPTADO' ||
                            decision == 'RECHAZADO';

                        return _showHistory
                            ? hasDecision
                            : !hasDecision;
                      }).toList();

                      if (filteredDocs.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              docs.isEmpty
                                  ? 'NO HAY ENTREVISTAS PROGRAMADAS'
                                  : _showHistory
                                      ? 'NO HAY ENTREVISTAS EN EL HISTORIAL'
                                      : 'NO HAY ENTREVISTAS ACTIVAS',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final data = filteredDocs[index].data()
                              as Map<String, dynamic>;

                          return _buildInterviewCard(data);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
