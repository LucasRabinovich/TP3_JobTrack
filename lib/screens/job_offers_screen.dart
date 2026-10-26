import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'job_offer_detail_screen.dart';

class JobOffersScreen extends StatefulWidget {
  const JobOffersScreen({super.key});

  @override
  State<JobOffersScreen> createState() => _JobOffersScreenState();
}

class _JobOffersScreenState extends State<JobOffersScreen> {
  static const Color lime = Color(0xFFD4FF00);
  static const Color background = Color(0xFFF4F4F4);

  final TextEditingController _searchController =
      TextEditingController();

  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _readText(
    Map<String, dynamic> data,
    String field, [
    String fallback = 'No especificado',
  ]) {
    final value = data[field]?.toString().trim();

    return value == null || value.isEmpty
        ? fallback
        : value;
  }

  Widget _buildTag(String value) {
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
        value.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildOfferCard(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    final title = _readText(data, 'title', 'Sin título');
    final modality = _readText(data, 'modality');
    final seniority = _readText(data, 'seniority');
    final contract = _readText(data, 'contractType');
    final location = _readText(data, 'location');
    final salary = _readText(data, 'salaryRange');
    
    // Leemos el logo y el nombre de la empresa
    final logoUrl = data['logoUrl']?.toString().trim() ?? '';
    final companyName = data['companyName']?.toString().trim() ?? 'Empresa';

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
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
          // Fila superior con Logo, Título y Empresa
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (logoUrl.isNotEmpty) ...[
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 2),
                    color: const Color(0xFFF4F4F4),
                  ),
                  child: Image.network(
                    logoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.business, size: 24),
                  ),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      companyName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTag(modality),
              _buildTag(seniority),
              _buildTag(contract),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 19,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(location),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              const Icon(
                Icons.payments_outlined,
                size: 19,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(salary),
              ),
            ],
          ),

          const SizedBox(height: 18),

          const Divider(
            color: Colors.black,
            thickness: 1,
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => JobOfferDetailScreen(
                      offerId: document.id,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: lime,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.all(16),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                  side: BorderSide(
                    color: Colors.black,
                    width: 2,
                  ),
                ),
              ),
              icon: const Icon(
                Icons.arrow_forward,
              ),
              label: const Text(
                'VER DETALLE',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: lime,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          'EXPLORAR OFERTAS',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ),

      body: user == null
          ? const Center(
              child: Text(
                'INICIÁ SESIÓN PARA VER OFERTAS',
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _search =
                            value.trim().toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText:
                          'Buscar por puesto o ubicación',
                      prefixIcon: const Icon(
                        Icons.search,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder:
                          const OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(
                          color: Colors.black,
                          width: 2,
                        ),
                      ),
                      focusedBorder:
                          const OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(
                          color: Colors.black,
                          width: 2,
                        ),
                      ),
                      suffixIcon: _search.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();

                                setState(() {
                                  _search = '';
                                });
                              },
                              icon: const Icon(
                                Icons.close,
                              ),
                            ),
                    ),
                  ),
                ),

                Expanded(
                  child: StreamBuilder<
                      QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('job_offers')
                        .where(
                          'isActive',
                          isEqualTo: true,
                        )
                        .snapshots(),

                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: SelectableText(
                              'No se pudieron cargar las ofertas.\n'
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

                      final offers =
                          snapshot.data!.docs.where((doc) {
                        final data = doc.data();

                        final title = _readText(
                          data,
                          'title',
                          '',
                        ).toLowerCase();

                        final location = _readText(
                          data,
                          'location',
                          '',
                        ).toLowerCase();

                        return title.contains(_search) ||
                            location.contains(_search);
                      }).toList();

                      offers.sort((a, b) {
                        final dateA =
                            a.data()['createdAt'] as Timestamp?;

                        final dateB =
                            b.data()['createdAt'] as Timestamp?;

                        return (dateB?.toDate() ??
                                DateTime(1970))
                            .compareTo(
                          dateA?.toDate() ??
                              DateTime(1970),
                        );
                      });

                      if (offers.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              _search.isEmpty
                                  ? 'NO HAY OFERTAS DISPONIBLES'
                                  : 'NO SE ENCONTRARON OFERTAS',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          20,
                          4,
                          20,
                          24,
                        ),
                        itemCount: offers.length,
                        itemBuilder: (context, index) {
                          return _buildOfferCard(
                            offers[index],
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
}