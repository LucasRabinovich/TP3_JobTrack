import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InterviewsScreen extends StatelessWidget {
  const InterviewsScreen({super.key});

  static const Color lime = Color(0xFFD4FF00);
  static const Color background = Color(0xFFF4F4F4);

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: lime,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'ENTREVISTAS',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
      body: user == null
          ? const Center(
              child: Text(
                'INICIÁ SESIÓN PARA VER TUS ENTREVISTAS',
                textAlign: TextAlign.center,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MIS ENTREVISTAS',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Consultá las entrevistas programadas '
                        'por las empresas.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: StreamBuilder<
                      QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('interviews')
                        .where('userId', isEqualTo: user.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              'No se pudieron cargar las entrevistas.\n'
                              '${snapshot.error}',
                              textAlign: TextAlign.center,
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

                      final interviews = snapshot.data!.docs.toList();

                      interviews.sort((a, b) {
                        final dateA =
                            a.data()['date'] as Timestamp?;
                        final dateB =
                            b.data()['date'] as Timestamp?;

                        final first =
                            dateA?.toDate() ?? DateTime(2100);
                        final second =
                            dateB?.toDate() ?? DateTime(2100);

                        return first.compareTo(second);
                      });

                      if (interviews.isEmpty) {
                        return _buildEmptyState();
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: interviews.length,
                        itemBuilder: (context, index) {
                          final data = interviews[index].data();

                          final date =
                              (data['date'] as Timestamp?)
                                  ?.toDate();

                          return _buildInterviewCard(
                            company:
                                data['company']?.toString() ??
                                    'Sin empresa',
                            role:
                                data['role']?.toString() ??
                                    'Sin puesto',
                            date: date,
                            type:
                                data['type']?.toString() ??
                                    'Sin tipo',
                            platform:
                                data['platform']?.toString() ??
                                    'Sin plataforma',
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.event_busy_outlined,
              size: 64,
              color: Colors.black54,
            ),
            const SizedBox(height: 20),
            const Text(
              'NO TENÉS ENTREVISTAS PROGRAMADAS',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Cuando una empresa programe una entrevista '
              'con vos, aparecerá acá.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterviewCard({
    required String company,
    required String role,
    required DateTime? date,
    required String type,
    required String platform,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
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
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            company.toUpperCase(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            role,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                date == null
                    ? 'Fecha no disponible'
                    : _formatDate(date),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(
                Icons.access_time,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                date == null
                    ? 'Hora no disponible'
                    : _formatTime(date),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTag(type),
              _buildTag(platform),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: lime,
        border: Border.all(
          color: Colors.black,
          width: 2,
        ),
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}