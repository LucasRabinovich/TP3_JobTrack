import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  static const Color lime = Color(0xFFD4FF00);
  static const Color background = Color(0xFFF4F4F4);

  
  static const Color colorRechazados = Color(0xFFFFA6A6); 
  static const Color colorEntrevistas = lime;            
  static const Color colorPostulados = Color(0xFF00FFFF); 
  static const Color colorAceptados = Colors.black;       

  BoxDecoration _brutalBox() {
    return BoxDecoration(
      color: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('NO HAY USUARIO', style: TextStyle(fontWeight: FontWeight.w900))),
      );
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black, size: 30),
        title: const Text(
          'JOB TRACKER',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 1),
        ),
        shape: const Border(bottom: BorderSide(color: Colors.black, width: 2)),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('applications')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }

          final docs = snapshot.data?.docs ?? [];

          
          int rechazados = 0;
          int entrevistas = 0;
          int postulados = 0;
          int aceptados = 0;

          Map<int, int> postulacionesPorMes = {};

          for (var doc in docs) {
            final data = doc.data();
            
            final status = (data['status'] ?? '').toString().toUpperCase();
            
            
            if (status == 'RECHAZADO') {
              rechazados++;
            } else if (status == 'ENTREVISTA') {
              entrevistas++;
            } else if (status == 'ACEPTADO') {
              aceptados++;
            } else {
              postulados++;
            }

            DateTime date;
            if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
              date = (data['createdAt'] as Timestamp).toDate();
            } else if (data['date'] != null && data['date'] is Timestamp) {
              date = (data['date'] as Timestamp).toDate();
            } else {
              date = DateTime.now();
            }
            
            postulacionesPorMes[date.month] = (postulacionesPorMes[date.month] ?? 0) + 1;
          }

          final int totalPostulaciones = rechazados + entrevistas + postulados + aceptados;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'ESTADÍSTICAS',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
                const SizedBox(height: 8),
                Text(
                  'Métricas y rendimiento de tu búsqueda.',
                  style: TextStyle(
                    fontSize: 14, 
                    color: Colors.grey[700], 
                    fontFamily: 'monospace', 
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.black, thickness: 3, height: 0),
                const SizedBox(height: 24),

                SizedBox(
                  height: 480, 
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: _brutalBox(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCardTitle('POSTULACIONES\nPOR MES'),
                              const SizedBox(height: 12),
                              const Divider(color: Colors.black, thickness: 1.5, height: 0),
                              const SizedBox(height: 20),
                              Expanded(
                                child: Container(
                                  color: Colors.grey[100],
                                  padding: const EdgeInsets.only(top: 16, right: 8),
                                  child: _buildBarChart(postulacionesPorMes),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 16),

                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: _brutalBox(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCardTitle('ESTADO\nGLOBAL\n(HISTÓRICO)'),
                              const SizedBox(height: 12),
                              const Divider(color: Colors.black, thickness: 1.5, height: 0),
                              const SizedBox(height: 24),
                              
                              SizedBox(
                                height: 140, 
                                child: _buildDonutChart(rechazados, entrevistas, postulados, aceptados, totalPostulaciones),
                              ),
                              
                              const SizedBox(height: 24),
                              const Divider(color: Colors.black, thickness: 1, height: 0),
                              const SizedBox(height: 16),
                              
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        
                                        _buildLegendItem(colorPostulados, 'Postulados', postulados),
                                        const SizedBox(height: 12),
                                        _buildLegendItem(colorRechazados, 'Rechazados', rechazados),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildLegendItem(colorEntrevistas, 'Entrevistas', entrevistas),
                                        const SizedBox(height: 12),
                                        _buildLegendItem(colorAceptados, 'Aceptados', aceptados),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardTitle(String text) {
    return Stack(
      children: [
        Positioned(
          bottom: 2,
          left: 0,
          right: 0,
          height: 10,
          child: Container(color: lime),
        ),
        Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, height: 1.2),
        ),
      ],
    );
  }

  Widget _buildBarChart(Map<int, int> datos) {
    List<BarChartGroupData> barGroups = [];
    final mesesNombres = ['', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    
    if (datos.isEmpty) {
      datos = {DateTime.now().month: 0}; 
    }

    int maxValor = datos.isNotEmpty ? datos.values.reduce((a, b) => a > b ? a : b) : 0;
    
    double topeY = 4.0;
    double intervalo = 1.0;

    if (maxValor <= 4) {
      topeY = 5.0;
      intervalo = 1.0;
    } else if (maxValor <= 12) {
      topeY = (maxValor + 2).toDouble();
      intervalo = 2.0;
    } else {
      topeY = (maxValor + 4).toDouble();
      intervalo = 5.0;
    }

    final mesesOrdenados = datos.keys.toList()..sort();
    final mesesAMostrar = mesesOrdenados.length > 5 
        ? mesesOrdenados.sublist(mesesOrdenados.length - 5) 
        : mesesOrdenados;

    int index = 0;
    for (int mes in mesesAMostrar) {
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: datos[mes]!.toDouble(),
              color: Colors.black,
              width: 24, 
              borderRadius: BorderRadius.zero, 
            ),
          ],
        ),
      );
      index++;
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: topeY, 
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.black, 
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                rod.toY.round().toString(),
                const TextStyle(color: lime, fontWeight: FontWeight.w900, fontSize: 12),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final int idx = value.toInt();
                if (idx < 0 || idx >= mesesAMostrar.length) return const SizedBox();
                final mesReal = mesesAMostrar[idx];
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    mesesNombres[mesReal], 
                    style: const TextStyle(fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: intervalo, 
              getTitlesWidget: (value, meta) {
                if (value == 0 || value % 1 != 0) return const SizedBox();
                return Text(
                  value.toInt().toString(), 
                  style: const TextStyle(fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false, 
          horizontalInterval: intervalo,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[300], strokeWidth: 1.5, dashArray: [4, 4]),
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            left: BorderSide(color: Colors.black, width: 2), 
            bottom: BorderSide(color: Colors.black, width: 2),
          ),
        ),
        barGroups: barGroups,
      ),
    );
  }

  
  Widget _buildDonutChart(int rechazados, int entrevistas, int postulados, int aceptados, int total) {
    if (total == 0) {
      
      rechazados = 12; entrevistas = 5; postulados = 18; aceptados = 2; total = 37;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            sectionsSpace: 0,
            centerSpaceRadius: 40, 
            startDegreeOffset: -90,
            sections: [
              _buildPieSection(colorEntrevistas, entrevistas.toDouble()),
              _buildPieSection(colorRechazados, rechazados.toDouble()),
              _buildPieSection(colorAceptados, aceptados.toDouble()),
              _buildPieSection(colorPostulados, postulados.toDouble()),
            ],
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('TOTAL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
            Text(total.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, height: 1.0)),
          ],
        ),
      ],
    );
  }

  PieChartSectionData _buildPieSection(Color color, double value) {
    return PieChartSectionData(
      color: color,
      value: value,
      title: '', 
      radius: 28,
      borderSide: const BorderSide(color: Colors.black, width: 2), 
    );
  }

  Widget _buildLegendItem(Color color, String title, int count) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.black, width: 1.5),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title, 
                style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900, height: 1.1),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                count.toString(), 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}