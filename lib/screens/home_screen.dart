import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:job_track/screens/login_screen.dart';
import 'package:job_track/screens/applications_screen.dart';
import 'package:job_track/screens/interviews_screen.dart';
import 'package:job_track/screens/job_offers_screen.dart';
import 'package:job_track/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color lime = Color(0xFFD4FF00);
  int _selectedIndex = 0;

  final List<String> _appBarTitles = [
    'INICIO',
    'POSTULACIONES',
    'MI PERFIL',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      
      appBar: AppBar(
        title: Text(
          _appBarTitles[_selectedIndex],
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.black,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: lime,
        elevation: 0,
        centerTitle: true,
        shape: const Border(bottom: BorderSide(color: Colors.black, width: 2)),
       
        iconTheme: const IconThemeData(color: Colors.black, size: 30),
      ),
      
      
      endDrawer: Drawer(
        backgroundColor: const Color(0xFFF4F4F4),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: lime,
                border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.black,
                    child: Icon(Icons.person, color: Colors.white, size: 35),
                  ),
                  const SizedBox(height: 12),
                  
                  FutureBuilder<DocumentSnapshot>(
                    future: currentUser != null 
                        ? FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get()
                        : null,
                    builder: (context, snapshot) {
                      String displayName = 'MI CUENTA'; 
                      
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        displayName = 'CARGANDO...';
                      } else if (snapshot.hasData && snapshot.data!.exists) {
                        final data = snapshot.data!.data() as Map<String, dynamic>;
                        
                        displayName = (data['name'] ?? currentUser?.email ?? 'USUARIO').toString().toUpperCase();
                      } else if (currentUser?.email != null) {
                        displayName = currentUser!.email!.toUpperCase();
                      }

                      return Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.w900, 
                          letterSpacing: 1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis, 
                      );
                    },
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              icon: Icons.work_outline,
              text: 'OFERTAS LABORALES',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const JobOffersScreen()));
              },
            ),
            _buildDrawerItem(
              icon: Icons.event_note,
              text: 'MIS ENTREVISTAS',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const InterviewsScreen()));
              },
            ),
            const Spacer(),
            const Divider(color: Colors.black, thickness: 2, height: 0),
            _buildDrawerItem(
              icon: Icons.logout,
              text: 'CERRAR SESIÓN',
              isDestructive: true,
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                }
              },
            ),
          ],
        ),
      ),

      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeContent(),          
          const ApplicationsScreen(),   
          const ProfileScreen(),        
        ],
      ),

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.black, width: 2)),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'INICIO'),
            BottomNavigationBarItem(icon: Icon(Icons.folder_outlined), activeIcon: Icon(Icons.folder), label: 'POSTULACIONES'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'PERFIL'),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('¡Bienvenido a JobTrack!', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('Explorá ofertas laborales y realizá el seguimiento de tu búsqueda.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
            const SizedBox(height: 40),
            _buildNavigationButton(
              text: 'EXPLORAR OFERTAS',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JobOffersScreen())),
            ),
            const SizedBox(height: 24),
            _buildNavigationButton(
              text: 'VER ENTREVISTAS',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InterviewsScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButton({required String text, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: lime,
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)],
        ),
        child: Center(
          child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1, color: Colors.black)),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({required IconData icon, required String text, required VoidCallback onTap, bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.black, size: 28),
      title: Text(text, style: TextStyle(fontWeight: FontWeight.w900, color: isDestructive ? Colors.red : Colors.black, letterSpacing: 0.5)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    );
  }
}