import 'package:flutter/material.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedStatus = 'TODOS';

  final List<Map<String, String>> _applications = [
    {
      'company': 'Mercado Libre',
      'role': 'Flutter Developer',
      'status': 'EN PROCESO',
    },
    {
      'company': 'Globant',
      'role': 'Mobile Developer',
      'status': 'OFERTA',
    },
    {
      'company': 'Accenture',
      'role': 'Junior Developer',
      'status': 'RECHAZADO',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _filteredApplications {
    final search = _searchController.text.toLowerCase();

    return _applications.where((application) {
      final company = application['company']!.toLowerCase();
      final role = application['role']!.toLowerCase();
      final status = application['status']!;

      final matchesSearch =
          company.contains(search) || role.contains(search);

      final matchesStatus =
          _selectedStatus == 'TODOS' || status == _selectedStatus;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  void _selectStatus(String status) {
    setState(() {
      _selectedStatus = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    const brutalistBorder = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(
        color: Colors.black,
        width: 2,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD4FF00),
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
            Text(
              'Consulta y organiza tus procesos laborales.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
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
              ),
            ),

            const SizedBox(height: 20),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterButton('TODOS'),
                _buildFilterButton('EN PROCESO'),
                _buildFilterButton('OFERTA'),
                _buildFilterButton('RECHAZADO'),
              ],
            ),

            const SizedBox(height: 24),

            Expanded(
              child: _filteredApplications.isEmpty
                  ? const Center(
                      child: Text(
                        'NO SE ENCONTRARON POSTULACIONES',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredApplications.length,
                      itemBuilder: (context, index) {
                        final application =
                            _filteredApplications[index];

                        return _buildApplicationCard(application);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String status) {
    final bool selected = _selectedStatus == status;

    return GestureDetector(
      onTap: () {
        _selectStatus(status);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFD4FF00)
              : Colors.white,
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

  Widget _buildApplicationCard(
    Map<String, String> application,
  ) {
    return Container(
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
            application['company']!,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            application['role']!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFD4FF00),
              border: Border.all(
                color: Colors.black,
                width: 2,
              ),
            ),
            child: Text(
              application['status']!,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}