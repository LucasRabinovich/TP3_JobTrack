
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'application_detail_screen.dart';
import 'job_offers_screen.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  State<ApplicationsScreen> createState() =>
      _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  static const Color lime = Color(0xFFD4FF00);
  static const Color background = Color(0xFFF4F4F4);

  final TextEditingController _searchController =
      TextEditingController();

  String _selectedStatus = 'TODOS';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectStatus(String status) {
    setState(() {
      _selectedStatus = status;
    });
  }

  void _exploreOffers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const JobOffersScreen(),
      ),
    );
  }

  Widget _buildFilterButton(String status) {
    final selected = _selectedStatus == status;

    return GestureDetector(
      onTap: () => _selectStatus(status),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: selected ? lime : Colors.white,
          border: Border.all(
            color: Colors.black,
            width: 2,
          ),
        ),
        child: Text(
          status,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required bool hasApplications,
  }) {
    if (hasApplications) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'NO SE ENCONTRARON POSTULACIONES '
            'CON LOS FILTROS SELECCIONADOS',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.work_outline,
              size: 64,
              color: Colors.black54,
            ),
            const SizedBox(height: 20),
            const Text(
              'TODAVÍA NO TENÉS POSTULACIONES',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Explorá las ofertas publicadas por las '
              'empresas y postulate a las que te interesen.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _exploreOffers,
              style: ElevatedButton.styleFrom(
                backgroundColor: lime,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                  side: BorderSide(
                    color: Colors.black,
                    width: 2,
                  ),
                ),
              ),
              icon: const Icon(Icons.search),
              label: const Text(
                'EXPLORAR OFERTAS',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationCard({
    required String applicationId,
    required Map<String, dynamic> applicationData,
  }) {
    final company =
        (applicationData['company'] ?? 'Sin empresa').toString();

    final role =
        (applicationData['role'] ?? 'Sin puesto').toString();

    final status =
        (applicationData['status'] ?? 'SIN ESTADO').toString();

    final modality =
        (applicationData['modality'] ?? '').toString();

    final salary =
        (applicationData['salary'] ?? '').toString();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ApplicationDetailScreen(
              applicationId: applicationId,
              applicationData: applicationData,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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

            if (modality.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Modalidad: $modality'),
            ],

            if (salary.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Salario: $salary'),
            ],

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: lime,
                    border: Border.all(
                      color: Colors.black,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Row(
                  children: [
                    Text(
                      'VER DETALLE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    const brutalistBorder = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(
        color: Colors.black,
        width: 2,
      ),
    );

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: lime,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: const Text(
          'POSTULACIONES',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.black,
            letterSpacing: 1,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'MIS POSTULACIONES',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Consultá el estado de tus postulaciones '
              'a las ofertas laborales.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _searchController,
              onChanged: (_) {
                setState(() {});
              },
              decoration: const InputDecoration(
                hintText: 'Buscar empresa o puesto...',
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.black,
                ),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: brutalistBorder,
                focusedBorder: brutalistBorder,
                contentPadding: EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 20),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterButton('TODOS'),
                _buildFilterButton('POSTULADO'),
                _buildFilterButton('EN PROCESO'),
                _buildFilterButton('ENTREVISTA'),
                _buildFilterButton('OFERTA'),
                _buildFilterButton('RECHAZADO'),
              ],
            ),

            const SizedBox(height: 24),

            Expanded(
              child: user == null
                  ? const Center(
                      child: Text(
                        'NO HAY USUARIO AUTENTICADO',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : StreamBuilder<
                      QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('applications')
                          .where(
                            'userId',
                            isEqualTo: user.uid,
                          )
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: SelectableText(
                                'ERROR AL CARGAR POSTULACIONES\n'
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

                        final docs = snapshot.data!.docs;

                        final search = _searchController.text
                            .trim()
                            .toLowerCase();

                        final filteredDocs = docs.where((doc) {
                          final data = doc.data();

                          final company =
                              (data['company'] ?? '')
                                  .toString()
                                  .toLowerCase();

                          final role =
                              (data['role'] ?? '')
                                  .toString()
                                  .toLowerCase();

                          final status =
                              (data['status'] ?? '')
                                  .toString()
                                  .toUpperCase();

                          final matchesSearch =
                              company.contains(search) ||
                              role.contains(search);

                          final matchesStatus =
                              _selectedStatus == 'TODOS' ||
                              status == _selectedStatus;

                          return matchesSearch && matchesStatus;
                        }).toList();

                        filteredDocs.sort((a, b) {
                          DateTime readDate(
                            Map<String, dynamic> data,
                          ) {
                            final value = data['createdAt'] ??
                                data['date'];

                            return value is Timestamp
                                ? value.toDate()
                                : DateTime(1970);
                          }

                          return readDate(b.data()).compareTo(
                            readDate(a.data()),
                          );
                        });

                        if (filteredDocs.isEmpty) {
                          return _buildEmptyState(
                            hasApplications: docs.isNotEmpty,
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.only(
                            bottom: 12,
                          ),
                          itemCount: filteredDocs.length,
                          itemBuilder: (context, index) {
                            final document = filteredDocs[index];

                            return _buildApplicationCard(
                              applicationId: document.id,
                              applicationData: document.data(),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
