import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- CONFIGURACIÓN DE SUPABASE EN VIVO ---
const String supabaseUrl = 'https://cfkaqkeohyphdcnvcnsv.supabase.co';
const String supabaseAnonKey = 'sb_publishable_E7NPno9DbRRJYuSVlOmwtA_bvVWxcWK';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  } catch (e) {
    debugPrint("Error iniciando Supabase: $e");
  }

  runApp(const GotasApp());
}

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
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  String _socialBattery = '☕ Tranquilo (60%)';
  bool _isPlusMember = false;
  String? _dilemmaChoice;

  // Datos del Usuario Actual (Personalizables)
  String _myUsername = 'CaminanteSilencioso';
  String _myAvatar = '🐺';
  List<String> _myInterests = ['#Videojuegos', '#Calistenia', '#Lectura & Manhwas', '#Programación'];
  String _myRhythm = 'Moderado (Respuestas cada 1 o 2 días)';

  // Catálogo de Avatares Ilustrados
  final List<String> _availableAvatars = [
    '🐺', '🦊', '🦉', '🐱', '🐇', '🐼', '🦥', '🐸',
    '🐢', '🦌', '🦔', '🐧', '🌿', '🌸', '🌙', '🌊',
    '🌧️', '🍄', '☕', '🕯️', '🔮', '🪐', '🌌', '🎨'
  ];

  final List<String> _allAvailableInterests = [
    '#Videojuegos', '#Calistenia', '#Lectura & Manhwas', '#Programación',
    '#Mascotas', '#Música Lofi', '#Anime', '#Escritura', '#Arte',
    '#Filosofía', '#Café & Té', '#Astronomía', '#Jardinería', '#Cocina'
  ];

  final List<Map<String, dynamic>> _fallbackDrops = [
    {
      'id': 1,
      'author': 'Yuki',
      'location': '🇯🇵 Kioto, Japón',
      'avatar': '🦊',
      'topic': 'Videojuegos & Paz',
      'content': 'Me gusta construir granjas en Minecraft mientras escucho lluvia. ¿Tienes algún rincón donde te sientas en paz?',
    },
    {
      'id': 2,
      'author': 'Mateo',
      'location': '🇦🇷 Buenos Aires, Arg',
      'avatar': '🦉',
      'topic': 'Rutina en Solitario',
      'content': 'Empecé a entrenar en casa porque el gimnasio tradicional me sobreestimulaba. ¿Prefieres entrenar a solas o con música?',
    },
  ];

  final List<Map<String, dynamic>> _fallbackStory = [
    {'sentence': 'Había una vez un pequeño conejo plateado que encontró un reloj que no medía las horas, sino los momentos de calma.'},
    {'sentence': ' Al girar la manecilla, el ruido de la ciudad se transformaba en el murmullo de un río sereno.'},
    {'sentence': ' Decidió compartir el secreto con un gato que descansaba sobre el tejado.'},
  ];

  final List<Map<String, String>> _chatMessages = [
    {
      'sender': 'Yuki',
      'text': '¡Hola! Leí tu respuesta sobre los proyectos que requieren concentración. Me alegra saber que compartimos ese gusto.',
      'isMe': 'false',
    },
    {
      'sender': 'Tú',
      'text': 'Totalmente. La noche tiene esa calma donde nadie te interrumpe y puedes avanzar a tu ritmo.',
      'isMe': 'true',
    }
  ];

  // Generador de nombres aleatorios poéticos / tranquilos
  String _generateRandomName() {
    final sustantivos = [
      'Caminante', 'Zorro', 'Búho', 'Gato', 'Conejo', 'Lobo',
      'Viajero', 'Eco', 'Bruma', 'Nómada', 'Lector', 'Panda',
      'Erizo', 'Ciervo', 'Rana', 'Pingüino', 'Tortuga', 'Sombra'
    ];
    final adjetivos = [
      'Silencioso', 'Sereno', 'Tranquilo', 'Nocturno', 'Calmo', 'Lofi',
      'Pacífico', 'Suave', 'Astral', 'Zen', 'Pensativo', 'Solitario',
      'Otoñal', 'Lunar', 'Místico', 'Flotante', 'Curioso', 'Luminoso'
    ];
    final rand = math.Random();
    return '${sustantivos[rand.nextInt(sustantivos.length)]}${adjetivos[rand.nextInt(adjetivos.length)]}';
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildGotasPage(),
      _buildRompehielosPage(),
      _buildCoopStoryPage(),
      _buildChatPage(),
      _buildProfilePage(),
    ];

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
          IconButton(
            icon: const Icon(Icons.favorite, color: Color(0xFFFF5E5B)),
            tooltip: 'Apoyar el proyecto',
            onPressed: _showSupportModal,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ActionChip(
              backgroundColor: const Color(0xFF1C2541),
              side: const BorderSide(color: Color(0x3348CAE4)),
              label: Text(
                _socialBattery,
                style: const TextStyle(fontSize: 12, color: Color(0xFF90E0EF)),
              ),
              onPressed: _showBatterySheet,
            ),
          )
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0B132B),
        selectedItemColor: const Color(0xFF48CAE4),
        unselectedItemColor: Colors.white54,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.water_drop_outlined), activeIcon: Icon(Icons.water_drop), label: 'Gotas'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_outlined), activeIcon: Icon(Icons.auto_awesome), label: 'Dilemas'),
          BottomNavigationBarItem(icon: Icon(Icons.brush_outlined), activeIcon: Icon(Icons.brush), label: 'Silencio'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Buzón'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _openNewDropDialog,
              backgroundColor: const Color(0xFF0077B6),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Enviar Gota', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  // 1. PÁGINA: GOTAS EN VIVO (Supabase Realtime)
  Widget _buildGotasPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Gotas que llegaron a ti',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                CircleAvatar(radius: 12, backgroundColor: const Color(0x3348CAE4), child: Text(_myAvatar, style: const TextStyle(fontSize: 12))),
                const SizedBox(width: 6),
                Text(_myUsername, style: const TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            )
          ],
        ),
        const SizedBox(height: 12),

        StreamBuilder<List<Map<String, dynamic>>>(
          stream: Supabase.instance.client
              .from('drops')
              .stream(primaryKey: ['id'])
              .order('created_at', ascending: false),
          builder: (context, snapshot) {
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildDropsList(_fallbackDrops);
            }
            return _buildDropsList(snapshot.data!);
          },
        ),

        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildDropsList(List<Map<String, dynamic>> drops) {
    return Column(
      children: drops.map((drop) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: GestureDetector(
            onTap: () => _openReadAndReplyDialog(drop),
            child: DropCard(
              author: drop['author']?.toString() ?? 'Anónimo',
              location: drop['location']?.toString() ?? 'Mundo',
              avatar: drop['avatar']?.toString() ?? '🐺',
              topic: drop['topic']?.toString() ?? 'Pensamiento',
              snippet: drop['content']?.toString() ?? '',
            ),
          ),
        );
      }).toList(),
    );
  }

  void _openReadAndReplyDialog(Map<String, dynamic> drop) {
    final replyController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C2541),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0x3348CAE4),
                  child: Text(drop['avatar']?.toString() ?? '🐺'),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(drop['author']?.toString() ?? 'Anónimo', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(drop['location']?.toString() ?? 'Mundo', style: const TextStyle(fontSize: 12, color: Colors.white60)),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x2648CAE4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(drop['topic']?.toString() ?? '', style: const TextStyle(color: Color(0xFF48CAE4), fontSize: 12)),
                )
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0B132B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '"${drop['content'] ?? ''}"',
                style: const TextStyle(fontSize: 14, height: 1.5, fontStyle: FontStyle.italic, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text('Tu respuesta como $_myAvatar $_myUsername (sin prisa):', style: const TextStyle(fontSize: 13, color: Color(0xFF90E0EF))),
            const SizedBox(height: 8),
            TextField(
              controller: replyController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Escribe tu reflexión con calma...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF0B132B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Guardar para después', style: TextStyle(color: Colors.white60)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0077B6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () async {
                    final text = replyController.text.trim();
                    if (text.isNotEmpty) {
                      try {
                        if (drop['id'] != null) {
                          await Supabase.instance.client.from('drop_replies').insert({
                            'drop_id': drop['id'],
                            'content': text,
                            'author': '$_myAvatar $_myUsername',
                          });
                        }
                      } catch (_) {}
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✨ Tu respuesta ha sido enviada como una gota lenta.'),
                          backgroundColor: Color(0xFF0077B6),
                        ),
                      );
                    }
                  },
                  child: const Text('Enviar Gota', style: TextStyle(color: Colors.white)),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  void _openNewDropDialog() {
    final topicController = TextEditingController();
    final contentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C2541),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: const Color(0x3348CAE4), child: Text(_myAvatar)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🌊 Lanzar una Gota al Océano', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFCAF0F8))),
                    Text('Firmado como $_myUsername', style: const TextStyle(fontSize: 11, color: Colors.white60)),
                  ],
                )
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: topicController,
              decoration: InputDecoration(
                labelText: 'Tema (Ej: Hábitos, Calistenia, Videojuegos, Lectura)',
                labelStyle: const TextStyle(color: Color(0xFF90E0EF), fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF0B132B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Comparte tu reflexión con tranquilidad...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF0B132B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0077B6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () async {
                    final topic = topicController.text.trim();
                    final content = contentController.text.trim();
                    if (content.isNotEmpty) {
                      try {
                        await Supabase.instance.client.from('drops').insert({
                          'author': _myUsername,
                          'location': 'Tu rincón seguro',
                          'avatar': _myAvatar,
                          'topic': topic.isNotEmpty ? topic : 'Pensamiento libre',
                          'content': content,
                        });
                      } catch (_) {}
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🌊 Tu gota ha sido lanzada al océano global.'),
                          backgroundColor: Color(0xFF0077B6),
                        ),
                      );
                    }
                  },
                  child: const Text('Lanzar al Mundo', style: TextStyle(color: Colors.white)),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  // 2. PÁGINA: ROMPEHIELOS Y DILEMAS
  Widget _buildRompehielosPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('✨ Rompehielos del Día', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Dilemas colectivos para conectar sin la presión del small talk.', style: TextStyle(fontSize: 13, color: Colors.white60)),
        const SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0x2648CAE4))),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0x2648CAE4), borderRadius: BorderRadius.circular(8)),
                  child: const Text('Dilema Global', style: TextStyle(fontSize: 11, color: Color(0xFF48CAE4))),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Si pudieras vivir en una biblioteca infinita donde nunca pasa el tiempo o en una cabaña frente al mar con café ilimitado... ¿cuál elegirías?',
                  style: TextStyle(fontSize: 14, height: 1.4, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: () => setState(() => _dilemmaChoice = 'A'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _dilemmaChoice == 'A' ? const Color(0x3348CAE4) : const Color(0xFF0B132B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _dilemmaChoice == 'A' ? const Color(0xFF48CAE4) : Colors.white12, width: _dilemmaChoice == 'A' ? 2 : 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('📚 La Biblioteca Infinita', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text(_dilemmaChoice == 'A' ? '✓ 62%' : '62%', style: TextStyle(fontWeight: FontWeight.bold, color: _dilemmaChoice == 'A' ? const Color(0xFF48CAE4) : Colors.white60)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () => setState(() => _dilemmaChoice = 'B'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _dilemmaChoice == 'B' ? const Color(0x3348CAE4) : const Color(0xFF0B132B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _dilemmaChoice == 'B' ? const Color(0xFF48CAE4) : Colors.white12, width: _dilemmaChoice == 'B' ? 2 : 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('🌊 La Cabaña en el Mar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text(_dilemmaChoice == 'B' ? '✓ 38%' : '38%', style: TextStyle(fontWeight: FontWeight.bold, color: _dilemmaChoice == 'B' ? const Color(0xFF48CAE4) : Colors.white60)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 3. PÁGINA: CREACIÓN EN SILENCIO (Historias en Realtime)
  Widget _buildCoopStoryPage() {
    final sentenceController = TextEditingController();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('🎨 Creación en Silencio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Construye relatos con personas de distintos países, agregando una frase a la vez.', style: TextStyle(fontSize: 13, color: Colors.white60)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1C2541),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x2648CAE4)),
          ),
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: Supabase.instance.client
                .from('story_sentences')
                .stream(primaryKey: ['id'])
                .order('created_at', ascending: true),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Text(
                  _fallbackStory.map((e) => e['sentence']).join(''),
                  style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.white),
                );
              }
              final fullText = snapshot.data!.map((e) => e['sentence']?.toString() ?? '').join('');
              return Text(
                fullText,
                style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.white),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: sentenceController,
                decoration: InputDecoration(
                  hintText: 'Agrega la siguiente frase como $_myAvatar $_myUsername...',
                  hintStyle: const TextStyle(fontSize: 13, color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF1C2541),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send, color: Color(0xFF48CAE4)),
              onPressed: () async {
                final txt = sentenceController.text.trim();
                if (txt.isNotEmpty) {
                  try {
                    await Supabase.instance.client.from('story_sentences').insert({
                      'author': '$_myAvatar $_myUsername',
                      'sentence': ' $txt',
                    });
                  } catch (_) {}
                  sentenceController.clear();
                }
              },
            )
          ],
        )
      ],
    );
  }

  // 4. PÁGINA: CHAT Y BUZÓN LENTO
  Widget _buildChatPage() {
    final chatInputController = TextEditingController();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color(0xFF1C2541),
          child: Row(
            children: [
              const CircleAvatar(backgroundColor: Color(0x3348CAE4), child: Text('🦊')),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Yuki (Japón)', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Modo Asíncrono', style: TextStyle(fontSize: 11, color: Color(0xFF48CAE4))),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0x33FFB703),
                  foregroundColor: const Color(0xFFFFB703),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Text('🪫', style: TextStyle(fontSize: 14)),
                label: const Text('Pausa Social', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () {
                  setState(() {
                    _chatMessages.add({
                      'sender': _myUsername,
                      'text': '🪫 [Pausa Social]: Me quedé sin batería social por ahora. ¡Seguimos charlando después con calma!',
                      'isMe': 'true',
                    });
                  });
                },
              )
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _chatMessages.length,
            itemBuilder: (ctx, idx) {
              final msg = _chatMessages[idx];
              final isMe = msg['isMe'] == 'true';
              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFF0077B6) : const Color(0xFF1C2541),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x1A48CAE4)),
                  ),
                  child: Text(msg['text']!, style: const TextStyle(fontSize: 13, height: 1.4)),
                ),
              );
            },
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              _buildPromptChip('🎮 ¿Qué juegas o lees últimamente?', chatInputController),
              _buildPromptChip('🎧 ¿Qué música escuchas para relajarte?', chatInputController),
              _buildPromptChip('✨ Me encantó tu reflexión.', chatInputController),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: chatInputController,
                  decoration: InputDecoration(
                    hintText: 'Escribe tu mensaje con calma...',
                    hintStyle: const TextStyle(fontSize: 13, color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF1C2541),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send, color: Color(0xFF48CAE4)),
                onPressed: () {
                  final txt = chatInputController.text.trim();
                  if (txt.isNotEmpty) {
                    setState(() {
                      _chatMessages.add({
                        'sender': _myUsername,
                        'text': txt,
                        'isMe': 'true',
                      });
                    });
                    chatInputController.clear();
                  }
                },
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildPromptChip(String text, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        backgroundColor: const Color(0xFF1C2541),
        side: const BorderSide(color: Color(0x3348CAE4)),
        label: Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF90E0EF))),
        onPressed: () {
          controller.text = text;
        },
      ),
    );
  }

  // 5. PÁGINA: PERFIL, ESPACIO SEGURO Y CONFIGURACIÓN DE IDENTIDAD
  Widget _buildProfilePage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('🌱 Mi Espacio Seguro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF48CAE4)),
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Editar Identidad'),
              onPressed: _openProfileEditorModal,
            )
          ],
        ),
        const SizedBox(height: 4),
        const Text('Configura tu avatar anónimo, temas y límites de interacción.', style: TextStyle(fontSize: 13, color: Colors.white60)),
        const SizedBox(height: 18),
        
        // Tarjeta de Identidad Actual
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0x3348CAE4))),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: const Color(0x3348CAE4),
                      child: Text(_myAvatar, style: const TextStyle(fontSize: 36)),
                    ),
                    if (_isPlusMember)
                      const CircleAvatar(
                        radius: 12,
                        backgroundColor: Color(0xFFFFD166),
                        child: Text('✨', style: TextStyle(fontSize: 12)),
                      )
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _myUsername,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_isPlusMember)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFFFFD166), borderRadius: BorderRadius.circular(8)),
                              child: const Text('PLUS', style: TextStyle(fontSize: 9, color: Colors.black, fontWeight: FontWeight.bold)),
                            )
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(_myRhythm, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        // Banner Apoyo al Proyecto en Perfil
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0x33FF5E5B), Color(0x1A0077B6)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x66FF5E5B)),
          ),
          child: Row(
            children: [
              const Text('💛', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Apoyar el Proyecto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFFFD166))),
                    SizedBox(height: 4),
                    Text('Dona vía Ko-fi o Binance Pay para publicar en Play Store.', style: TextStyle(fontSize: 11, color: Colors.white70)),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5E5B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _showSupportModal,
                child: const Text('Apoyar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),

        const SizedBox(height: 20),
        const Text('Colección de Sellos del Mundo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF90E0EF))),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStampItem('🗼', 'Tokio', 'Desbloqueado'),
            _buildStampItem('🌸', 'Kioto', 'Desbloqueado'),
            _buildStampItem('☕', 'Buenos Aires', 'Gotas Plus'),
            _buildStampItem('🍁', 'Montreal', 'Gotas Plus'),
          ],
        ),

        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Mis Temas de Interés', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF90E0EF))),
            GestureDetector(
              onTap: _openProfileEditorModal,
              child: const Text('Personalizar', style: TextStyle(fontSize: 11, color: Color(0xFF48CAE4))),
            )
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _myInterests.map((t) => Chip(backgroundColor: const Color(0xFF1C2541), label: Text(t, style: const TextStyle(fontSize: 12)))).toList(),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0x1A0077B6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x3348CAE4)),
          ),
          child: const Row(
            children: [
              Text('🛡️', style: TextStyle(fontSize: 20)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tu perfil es anónimo. Nunca mostramos tu ubicación exacta ni fotos reales.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF90E0EF)),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  // Modal Editor de Identidad (Avatares, Nombre Aleatorio e Intereses)
  void _openProfileEditorModal() {
    final nameController = TextEditingController(text: _myUsername);
    String tempAvatar = _myAvatar;
    List<String> tempInterests = List.from(_myInterests);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C2541),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
                ),
                const SizedBox(height: 14),
                const Text('🌱 Personalizar Mi Identidad', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFCAF0F8))),
                const SizedBox(height: 4),
                const Text('Elige cómo te verán los demás viajeros.', style: TextStyle(fontSize: 12, color: Colors.white60)),
                const SizedBox(height: 16),

                // 1. Selector de Avatar
                const Text('1. Elige tu Avatar Ilustrado:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF90E0EF))),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _availableAvatars.length,
                    itemBuilder: (context, idx) {
                      final av = _availableAvatars[idx];
                      final isSelected = tempAvatar == av;
                      return GestureDetector(
                        onTap: () => setModalState(() => tempAvatar = av),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0x3348CAE4) : const Color(0xFF0B132B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? const Color(0xFF48CAE4) : Colors.white12, width: isSelected ? 2 : 1),
                          ),
                          child: Center(child: Text(av, style: const TextStyle(fontSize: 22))),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // 2. Nombre de Usuario con Botón Aleatorio
                const Text('2. Nombre de Viajero (o genera uno anónimo):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF90E0EF))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: 'Tu alias...',
                          filled: true,
                          fillColor: const Color(0xFF0B132B),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0077B6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Text('🎲', style: TextStyle(fontSize: 16)),
                      label: const Text('Aleatorio', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        final randomName = _generateRandomName();
                        nameController.text = randomName;
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 3. Temas de Interés
                const Text('3. Temas que te interesan:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF90E0EF))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _allAvailableInterests.map((interest) {
                    final isSel = tempInterests.contains(interest);
                    return FilterChip(
                      selected: isSel,
                      label: Text(interest, style: TextStyle(fontSize: 11, color: isSel ? Colors.black : Colors.white)),
                      selectedColor: const Color(0xFF48CAE4),
                      backgroundColor: const Color(0xFF0B132B),
                      checkmarkColor: Colors.black,
                      onSelected: (selected) {
                        setModalState(() {
                          if (selected) {
                            tempInterests.add(interest);
                          } else {
                            tempInterests.remove(interest);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // Botón Guardar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF48CAE4),
                      foregroundColor: const Color(0xFF0B132B),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      final newName = nameController.text.trim();
                      if (newName.isNotEmpty) {
                        setState(() {
                          _myUsername = newName;
                          _myAvatar = tempAvatar;
                          _myInterests = tempInterests.isNotEmpty ? tempInterests : ['#General'];
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✨ Identidad actualizada como $_myAvatar $_myUsername'),
                            backgroundColor: const Color(0xFF0077B6),
                          ),
                        );
                      }
                    },
                    child: const Text('Guardar Mi Identidad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStampItem(String emoji, String title, String status) {
    final isLocked = status == 'Gotas Plus';
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF1C2541),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isLocked ? Colors.white24 : const Color(0xFF48CAE4)),
          ),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
        ),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 11)),
        Text(status, style: TextStyle(fontSize: 9, color: isLocked ? const Color(0xFFFFD166) : const Color(0xFF48CAE4))),
      ],
    );
  }

  void _showSupportModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C2541),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: const [
                Text('💛', style: TextStyle(fontSize: 28)),
                SizedBox(width: 10),
                Text('Apoyar Gotas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFD166))),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Ayúdanos a recaudar los \$25 USD para publicar Gotas oficialmente en Google Play Store.',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 20),

            // Opción 1: Ko-fi
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0B132B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFF5E5B)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Text('☕', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 8),
                      Text('Ko-fi (Tarjetas / PayPal)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text('Dona \$1 USD fácilmente con tarjeta internacional o PayPal.', style: TextStyle(fontSize: 11, color: Colors.white60)),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5E5B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Clipboard.setData(const ClipboardData(text: 'https://ko-fi.com/haseonick'));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('📋 Enlace de Ko-fi copiado: https://ko-fi.com/haseonick'),
                            backgroundColor: Color(0xFFFF5E5B),
                          ),
                        );
                      },
                      child: const Text('Copiar enlace de Ko-fi (ko-fi.com/haseonick)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Opción 2: Binance Pay
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0B132B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF3BA2F)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Text('⚡', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 8),
                      Text('Binance Pay (Cero comisiones)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text('Envía USDT o criptomonedas directamente desde tu app de Binance.', style: TextStyle(fontSize: 11, color: Colors.white60)),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF3BA2F),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Clipboard.setData(const ClipboardData(text: 'haseonick'));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('📋 Usuario de Binance Pay copiado: haseonick'),
                            backgroundColor: Color(0xFF0077B6),
                          ),
                        );
                      },
                      child: const Text('Copiar Usuario de Binance: haseonick', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
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
            const Text('Ajustar Batería Social', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Text('⚡', style: TextStyle(fontSize: 24)),
              title: const Text('Alta (100%) - Con ganas de charlar'),
              onTap: () {
                setState(() => _socialBattery = '⚡ Alta (100%)');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Text('☕', style: TextStyle(fontSize: 24)),
              title: const Text('Tranquilo (60%) - Respuestas lentas'),
              onTap: () {
                setState(() => _socialBattery = '☕ Tranquilo (60%)');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Text('🪫', style: TextStyle(fontSize: 24)),
              title: const Text('Modo Recarga (20%) - Solo leyendo'),
              onTap: () {
                setState(() => _socialBattery = '🪫 Modo Recarga (20%)');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

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
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Tocar para leer y responder →',
                  style: TextStyle(fontSize: 11, color: Color(0xFF48CAE4), fontWeight: FontWeight.w500),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
