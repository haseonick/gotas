// Flutter - Starter Component para 'Gotas'
// Demuestra el widget del logo animado en forma de gota,
// el selector de batería social y la tarjeta de carta asíncrona.

import 'package:flutter/material.dart';

void main() => runApp(const GotasApp());

class GotasApp extends StatelessWidget {
  const GotasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gotas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B132B),
        cardColor: const Color(0xFF1C2541),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF48CAE4),
          secondary: Color(0xFF0077B6),
          surface: Color(0xFF1C2541),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String socialBattery = '☕ Tranquilo (60%)';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B132B),
        elevation: 0,
        title: Row(
          children: [
            const WaterDropIcon(size: 28),
            const SizedBox(width: 10),
            const Text(
              'Gotas',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFCAF0F8),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ActionChip(
              backgroundColor: const Color(0xFF1C2541),
              side: const BorderSide(color: Color(0x3348CAE4)),
              label: Text(
                socialBattery,
                style: const TextStyle(fontSize: 12, color: Color(0xFF90E0EF)),
              ),
              onPressed: _showBatterySheet,
            ),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner de baja presión
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0x1A0077B6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x3348CAE4)),
            ),
            child: const Row(
              children: [
                Text('🕊️', style: TextStyle(fontSize: 20)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sin presión de inmediatez: lee y responde cuando tu energía lo permita.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF90E0EF)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Gotas que llegaron a ti',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const DropCard(
            author: 'Yuki',
            location: '🇯🇵 Kioto, Japón',
            avatar: '🦊',
            topic: 'Videojuegos & Paz',
            snippet: 'Me gusta construir granjas en Minecraft mientras escucho lluvia. ¿Tienes algún rincón donde te sientas en paz?',
          ),
          const SizedBox(height: 12),
          const DropCard(
            author: 'Mateo',
            location: '🇦🇷 Buenos Aires, Arg',
            avatar: '🦉',
            topic: 'Rutina en Solitario',
            snippet: 'Empecé a entrenar en casa porque el gimnasio tradicional me sobreestimulaba. ¿Prefieres entrenar a solas o con música?',
          ),
        ],
      ),
    );
  }

  void _showBatterySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C2541),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ajustar Batería Social',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Text('⚡', style: TextStyle(fontSize: 24)),
              title: const Text('Alta (100%) - Con ganas de charlar'),
              onTap: () {
                setState(() => socialBattery = '⚡ Alta (100%)');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Text('☕', style: TextStyle(fontSize: 24)),
              title: const Text('Tranquilo (60%) - Respuestas lentas'),
              onTap: () {
                setState(() => socialBattery = '☕ Tranquilo (60%)');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Text('🪫', style: TextStyle(fontSize: 24)),
              title: const Text('Modo Recarga (20%) - Solo leyendo'),
              onTap: () {
                setState(() => socialBattery = '🪫 Modo Recarga (20%)');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Widget Personalizado para la Gota de Agua
class WaterDropIcon extends StatelessWidget {
  final double size;
  const WaterDropIcon({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 1.2),
      painter: _WaterDropPainter(),
    );
  }
}

class _WaterDropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFCAF0F8), Color(0xFF48CAE4), Color(0xFF0077B6)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.moveTo(size.width * 0.5, 0);
    path.cubicTo(
      size.width * 0.5, 0,
      0, size.height * 0.6,
      0, size.height * 0.75,
    );
    path.arcToPoint(
      Offset(size.width, size.height * 0.75),
      radius: Radius.circular(size.width * 0.5),
      clockwise: false,
    );
    path.cubicTo(
      size.width, size.height * 0.6,
      size.width * 0.5, 0,
      size.width * 0.5, 0,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DropCard extends StatelessWidget {
  final String author, location, avatar, topic, snippet;
  const DropCard({
    super.key,
    required this.author,
    required this.location,
    required this.avatar,
    required this.topic,
    required this.snippet,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0x2648CAE4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0x3348CAE4),
                  child: Text(avatar),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(author, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(location, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x2648CAE4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    topic,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF48CAE4)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              snippet,
              style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
