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
  bool _isRegistered = false;

  String _myUsername = '';
  String _myAvatar = '🐺';

  // Votaciones de Dilemas
  String? _dilemmaChoice1;
  String? _dilemmaChoice2;
  String? _dilemmaChoice3;

  String _currentDropsFilter = 'all';
  final List<dynamic> _savedDropIds = [];

  // Lista local en memoria
  List<Map<String, dynamic>> _liveDrops = [];
  bool _isLoadingDrops = true;

  final List<Map<String, String>> _privateJournal = [];
  final List<Map<String, String>> _mySentReplies = [];

  final List<String> _availableAvatars = [
    '🐺', '🦊', '🦉', '🐱', '🐇', '🐼', '🦥', '🐸',
    '🐢', '🦌', '🦔', '🐧', '🦦', '🦝', '🐨', '🦋',
    '🕊️', '🐋', '🌿', '🌸', '🌙', '🌊', '🌧️', '🍄',
    '🌲', '🍁', '🪷', '❄️', '☕', '🕯️', '📖', '🎧',
    '🪴', '🏮', '🔮', '🪐'
  ];

  @override
  void initState() {
    super.initState();
    _fetchLiveDrops();
    _subscribeToLiveChanges();
  }

  Future<void> _fetchLiveDrops() async {
    setState(() => _isLoadingDrops = true);
    try {
      final data = await Supabase.instance.client
          .from('drops')
          .select()
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _liveDrops = List<Map<String, dynamic>>.from(data);
          _isLoadingDrops = false;
        });
      }
    } catch (e) {
      debugPrint("Error obteniendo gotas: $e");
      if (mounted) {
        setState(() => _isLoadingDrops = false);
      }
    }
  }

  void _subscribeToLiveChanges() {
    try {
      Supabase.instance.client
          .channel('public:drops')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'drops',
            callback: (payload) {
              _fetchLiveDrops();
            },
          )
          .subscribe();
    } catch (_) {}
  }

  String _generateRandomName() {
    final sustantivos = [
      'Caminante', 'Zorro', 'Búho', 'Gato', 'Conejo', 'Lobo',
      'Viajero', 'Eco', 'Bruma', 'Nómada', 'Lector', 'Panda',
      'Erizo', 'Ciervo', 'Rana', 'Pingüino', 'Tortuga'
    ];
    final adjetivos = [
      'Silencioso', 'Sereno', 'Tranquilo', 'Nocturno', 'Calmo', 'Lofi',
      'Pacífico', 'Suave', 'Astral', 'Zen', 'Pensativo', 'Solitario'
    ];
    final rand = math.Random();
    return '${sustantivos[rand.nextInt(sustantivos.length)]}${adjetivos[rand.nextInt(adjetivos.length)]}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isRegistered) {
      return _buildOnboardingScreen();
    }

    final List<Widget> pages = [
      _buildGotasPage(),
      _buildBuzonPage(),
      _buildRompehielosPage(),
      _buildCoopStoryPage(),
      _buildDiarioPage(),
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
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.water_drop_outlined), activeIcon: Icon(Icons.water_drop), label: 'Gotas'),
          BottomNavigationBarItem(icon: Icon(Icons.mail_outline), activeIcon: Icon(Icons.mail), label: 'Buzón'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_outlined), activeIcon: Icon(Icons.auto_awesome), label: 'Dilemas'),
          BottomNavigationBarItem(icon: Icon(Icons.brush_outlined), activeIcon: Icon(Icons.brush), label: 'Silencio'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), activeIcon: Icon(Icons.menu_book), label: 'Diario'),
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

  // --- PANTALLA INICIAL OBLIGATORIA (ONBOARDING) ---
  Widget _buildOnboardingScreen() {
    final nameController = TextEditingController();
    String tempAvatar = _myAvatar;

    return Scaffold(
      body: StatefulBuilder(
        builder: (ctx, setGateState) => Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.3),
              radius: 1.2,
              colors: [Color(0xFF1C2541), Color(0xFF0B132B), Color(0xFF050814)],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: Color(0xFF48CAE4), width: 1.5),
                ),
                color: const Color(0xFF1C2541),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const WaterDropIcon(size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'Bienvenido a Gotas',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Crea tu identidad anónima de viajero antes de comenzar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.white60),
                      ),
                      const SizedBox(height: 16),

                      // Vista previa
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B132B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0x3348CAE4)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0x3348CAE4),
                              child: Text(tempAvatar, style: const TextStyle(fontSize: 20)),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              nameController.text.isNotEmpty ? nameController.text : 'Escribe tu alias...',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: nameController.text.isNotEmpty ? Colors.white : Colors.white38,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('1. Elige tu Avatar:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF90E0EF))),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 100,
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 6,
                            crossAxisSpacing: 6,
                            mainAxisSpacing: 6,
                          ),
                          itemCount: _availableAvatars.length,
                          itemBuilder: (c, i) {
                            final av = _availableAvatars[i];
                            final isSel = tempAvatar == av;
                            return GestureDetector(
                              onTap: () => setGateState(() => tempAvatar = av),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSel ? const Color(0x3348CAE4) : const Color(0xFF0B132B),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: isSel ? const Color(0xFF48CAE4) : Colors.white12, width: isSel ? 2 : 1),
                                ),
                                child: Center(child: Text(av, style: const TextStyle(fontSize: 18))),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('2. Tu Nombre o Apodo:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF90E0EF))),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: nameController,
                              onChanged: (v) => setGateState(() {}),
                              decoration: InputDecoration(
                                hintText: 'Ej: ZorroAzul, Lector...',
                                hintStyle: const TextStyle(fontSize: 12, color: Colors.white38),
                                filled: true,
                                fillColor: const Color(0xFF0B132B),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0077B6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              final randName = _generateRandomName();
                              setGateState(() {
                                nameController.text = randName;
                              });
                            },
                            child: const Text('🎲 Aleatorio', style: TextStyle(fontSize: 11, color: Colors.white)),
                          )
                        ],
                      ),
                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF48CAE4),
                            foregroundColor: const Color(0xFF0B132B),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            final name = nameController.text.trim();
                            if (name.length < 3) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('⚠️ Por favor escribe un nombre de al menos 3 letras.')),
                              );
                              return;
                            }

                            // Diálogo de Confirmación: ¿Estás seguro?
                            showDialog(
                              context: context,
                              builder: (c) => AlertDialog(
                                backgroundColor: const Color(0xFF1C2541),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: const BorderSide(color: Color(0xFF48CAE4)),
                                ),
                                title: Row(
                                  children: const [
                                    Text('🔒', style: TextStyle(fontSize: 22)),
                                    SizedBox(width: 8),
                                    Text('¿Estás seguro?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFCAF0F8))),
                                  ],
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Tu nombre de viajero será definitivo y permanente. No podrás cambiarlo después para mantener la confianza en tus cartas.',
                                      style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
                                    ),
                                    const SizedBox(height: 14),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0B132B),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFF48CAE4)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(tempAvatar, style: const TextStyle(fontSize: 22)),
                                          const SizedBox(width: 10),
                                          Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(c),
                                    child: const Text('Revisar', style: TextStyle(color: Colors.white60)),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0077B6),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () async {
                                      Navigator.pop(c);
                                      try {
                                        await Supabase.instance.client.from('profiles').insert({
                                          'username': name,
                                          'avatar': tempAvatar,
                                        });
                                      } catch (_) {}

                                      setState(() {
                                        _myUsername = name;
                                        _myAvatar = tempAvatar;
                                        _isRegistered = true;
                                      });
                                    },
                                    child: const Text('Sí, confirmar 💧', style: TextStyle(color: Colors.white)),
                                  )
                                ],
                              ),
                            );
                          },
                          child: const Text('Comenzar y Entrar al Océano 💧', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- 1. PÁGINA: GOTAS (Con pull-to-refresh y filtro) ---
  Widget _buildGotasPage() {
    List<Map<String, dynamic>> drops = _liveDrops;
    if (_currentDropsFilter == 'saved') {
      drops = drops.where((d) => _savedDropIds.contains(d['id'])).toList();
    }

    return RefreshIndicator(
      onRefresh: _fetchLiveDrops,
      color: const Color(0xFF48CAE4),
      backgroundColor: const Color(0xFF1C2541),
      child: ListView(
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
                    'Sin presión de inmediatez: desliza hacia abajo para actualizar cartas.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF90E0EF)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              ChoiceChip(
                label: const Text('🌊 Todas las Gotas'),
                selected: _currentDropsFilter == 'all',
                onSelected: (s) => setState(() => _currentDropsFilter = 'all'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text('🔖 Guardadas (${_savedDropIds.length})'),
                selected: _currentDropsFilter == 'saved',
                onSelected: (s) => setState(() => _currentDropsFilter = 'saved'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isLoadingDrops)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
          else if (drops.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: Text(
                  'No hay cartas en este momento. ¡Sé el primero en enviar una!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ),
            )
          else
            Column(
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
            ),

          const SizedBox(height: 60),
        ],
      ),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.bookmark_border, size: 16, color: Colors.white70),
                  label: const Text('Guardar para después', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  onPressed: () {
                    final dropId = drop['id'];
                    if (dropId != null && !_savedDropIds.contains(dropId)) {
                      setState(() => _savedDropIds.add(dropId));
                    }
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('🔖 Carta guardada en tu lista para responder más tarde.')),
                    );
                  },
                ),
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

                      setState(() {
                        _mySentReplies.insert(0, {
                          'topic': drop['topic']?.toString() ?? 'Carta',
                          'author': drop['author']?.toString() ?? 'Viajero',
                          'text': text,
                        });
                      });

                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✨ Tu respuesta ha sido enviada y registrada en tu Buzón.'),
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
                      _fetchLiveDrops();
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

  // --- 2. PÁGINA: BUZÓN DE ECOS ---
  Widget _buildBuzonPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('📬 Mi Buzón de Ecos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Historial de respuestas lentas que has enviado a otros viajeros.', style: TextStyle(fontSize: 12, color: Colors.white60)),
        const SizedBox(height: 16),
        if (_mySentReplies.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1C2541),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x2648CAE4)),
            ),
            child: const Column(
              children: [
                Text('📨', style: TextStyle(fontSize: 32)),
                SizedBox(height: 8),
                Text('Aún no has enviado respuestas lentas.', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Abre cualquier carta en "Gotas" y escribe una respuesta para verla registrada aquí.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.white60)),
              ],
            ),
          )
        else
          ..._mySentReplies.map((rep) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0x3348CAE4))),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Respondido a: ${rep['author']} · [${rep['topic']}]', style: const TextStyle(fontSize: 11, color: Color(0xFF48CAE4), fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('"${rep['text']}"', style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.4)),
                    ],
                  ),
                ),
              )),
      ],
    );
  }

  // --- 3. PÁGINA: DILEMAS Y ROMPEHIELOS (4 Secciones) ---
  Widget _buildRompehielosPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('✨ Dilemas del Día', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Descubre afinidades con viajeros de todo el mundo.', style: TextStyle(fontSize: 12, color: Colors.white60)),
        const SizedBox(height: 16),

        _buildDilemmaCard(
          id: 1,
          title: '🌿 1. Refugio Ideal',
          desc: '¿Dónde preferirías pasar un mes completo de tranquilidad?',
          optA: '🌲 Cabaña en Bosque Lluvioso',
          pctA: 64,
          optB: '🌊 Faro frente al Océano',
          pctB: 36,
          choice: _dilemmaChoice1,
          onVote: (c) => setState(() => _dilemmaChoice1 = c),
        ),
        const SizedBox(height: 14),

        _buildDilemmaCard(
          id: 2,
          title: '🎮 2. Pasatiempos & Narrativa',
          desc: 'Si pudieras elegir un superpoder sobre tus obras favoritas:',
          optA: '🧠 Amnesia Selectiva (Revivir de cero)',
          pctA: 52,
          optB: '⏳ 3 Horas Diarias de Pausa Mundial',
          pctB: 48,
          choice: _dilemmaChoice2,
          onVote: (c) => setState(() => _dilemmaChoice2 = c),
        ),
        const SizedBox(height: 14),

        _buildDilemmaCard(
          id: 3,
          title: '🔋 3. Batería Social',
          desc: '¿Qué habilidad cotidiana te resultaría más útil?',
          optA: '🛡️ Escudo de Invisibilidad Social',
          pctA: 58,
          optB: '⚡ Recarga Instantánea en 5 minutos',
          pctB: 42,
          choice: _dilemmaChoice3,
          onVote: (c) => setState(() => _dilemmaChoice3 = c),
        ),
      ],
    );
  }

  Widget _buildDilemmaCard({
    required int id,
    required String title,
    required String desc,
    required String optA,
    required int pctA,
    required String optB,
    required int pctB,
    required String? choice,
    required Function(String) onVote,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0x2648CAE4))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF90E0EF))),
            const SizedBox(height: 4),
            Text(desc, style: const TextStyle(fontSize: 12, color: Colors.white70)),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => onVote('A'),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: choice == 'A' ? const Color(0x3348CAE4) : const Color(0xFF0B132B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: choice == 'A' ? const Color(0xFF48CAE4) : Colors.white12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(optA, style: const TextStyle(fontSize: 12)),
                    Text(choice == 'A' ? '✓ $pctA%' : '$pctA%', style: TextStyle(fontWeight: FontWeight.bold, color: choice == 'A' ? const Color(0xFF48CAE4) : Colors.white60, fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => onVote('B'),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: choice == 'B' ? const Color(0x3348CAE4) : const Color(0xFF0B132B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: choice == 'B' ? const Color(0xFF48CAE4) : Colors.white12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(optB, style: const TextStyle(fontSize: 12)),
                    Text(choice == 'B' ? '✓ $pctB%' : '$pctB%', style: TextStyle(fontWeight: FontWeight.bold, color: choice == 'B' ? const Color(0xFF48CAE4) : Colors.white60, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 4. PÁGINA: CREACIÓN EN SILENCIO (Historias por Líneas) ---
  Widget _buildCoopStoryPage() {
    final sentenceController = TextEditingController();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('🎨 Creación en Silencio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Cada viajero agrega una frase que continúa en la siguiente línea.', style: TextStyle(fontSize: 12, color: Colors.white60)),
        const SizedBox(height: 16),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: Supabase.instance.client
              .from('story_sentences')
              .stream(primaryKey: ['id'])
              .order('created_at', ascending: true),
          builder: (context, snapshot) {
            const prologue = 'Había una vez un pequeño conejo plateado que encontró un reloj que no medía las horas, sino los momentos de calma.';
            final List<Widget> lines = [];

            lines.add(
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0x330077B6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF48CAE4)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📖 Inicio de la Crónica', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF48CAE4))),
                    SizedBox(height: 4),
                    Text(prologue, style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFFCAF0F8))),
                  ],
                ),
              ),
            );

            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              for (var item in snapshot.data!) {
                final author = item['author']?.toString() ?? 'Viajero';
                final sentence = item['sentence']?.toString().trim() ?? '';
                if (sentence.isNotEmpty && !sentence.contains('pequeño conejo plateado')) {
                  lines.add(
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C2541),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x3348CAE4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(author, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF90E0EF))),
                          const SizedBox(height: 4),
                          Text('"$sentence"', style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.white)),
                        ],
                      ),
                    ),
                  );
                }
              }
            }

            return Column(children: lines);
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: sentenceController,
                decoration: InputDecoration(
                  hintText: 'Agrega tu frase...',
                  hintStyle: const TextStyle(fontSize: 12, color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF1C2541),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                      'sentence': txt,
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

  // --- 5. PÁGINA: DIARIO PRIVADO ---
  Widget _buildDiarioPage() {
    final journalController = TextEditingController();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('📖 Mi Diario de Gotas Privadas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Tus reflexiones personales guardadas solo en tu teléfono.', style: TextStyle(fontSize: 12, color: Colors.white60)),
        const SizedBox(height: 14),
        TextField(
          controller: journalController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: '¿Qué momento de calma tuviste hoy?...',
            hintStyle: const TextStyle(fontSize: 12, color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF1C2541),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0077B6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final txt = journalController.text.trim();
              if (txt.isNotEmpty) {
                setState(() {
                  _privateJournal.insert(0, {
                    'text': txt,
                    'date': 'Hoy',
                  });
                });
                journalController.clear();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✨ Guardado en tu diario personal.')));
              }
            },
            child: const Text('Guardar Nota', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ),
        const SizedBox(height: 16),
        ..._privateJournal.map((entry) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0x3348CAE4))),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(entry['text']!, style: const TextStyle(fontSize: 13, height: 1.4)),
              ),
            )),
      ],
    );
  }

  // --- 6. PÁGINA: PERFIL Y ESPACIO SEGURO ---
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
              label: const Text('Editar'),
              onPressed: _openProfileEditorModal,
            )
          ],
        ),
        const SizedBox(height: 14),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0x3348CAE4))),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0x3348CAE4),
                  child: Text(_myAvatar, style: const TextStyle(fontSize: 30)),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_myUsername, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    const Text('Cuenta Activa en este Dispositivo', style: TextStyle(fontSize: 11, color: Color(0xFF48CAE4))),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Banner Apoyo
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0x33FF5E5B), Color(0x1A0077B6)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x66FF5E5B)),
          ),
          child: Row(
            children: [
              const Text('💛', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Apoyar el Proyecto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFFFD166))),
                    Text('Ko-fi y Binance Pay activos.', style: TextStyle(fontSize: 11, color: Colors.white70)),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5E5B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _showSupportModal,
                child: const Text('Apoyar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ],
    );
  }

  void _openProfileEditorModal() {
    String tempAvatar = _myAvatar;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C2541),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (c, setM) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌱 Personalizar mi Avatar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Puedes cambiar tu avatar ilustrado cuando desees:', style: TextStyle(fontSize: 12, color: Colors.white60)),
              const SizedBox(height: 12),
              SizedBox(
                height: 140,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 6, mainAxisSpacing: 6),
                  itemCount: _availableAvatars.length,
                  itemBuilder: (cx, i) {
                    final av = _availableAvatars[i];
                    final isSel = tempAvatar == av;
                    return GestureDetector(
                      onTap: () => setM(() => tempAvatar = av),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0x3348CAE4) : const Color(0xFF0B132B),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isSel ? const Color(0xFF48CAE4) : Colors.white12, width: isSel ? 2 : 1),
                        ),
                        child: Center(child: Text(av, style: const TextStyle(fontSize: 18))),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B132B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Nombre de Usuario (Permanente):', style: TextStyle(fontSize: 10, color: Colors.white60)),
                        Text(_myUsername, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0x3348CAE4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('🔒 Bloqueado', style: TextStyle(fontSize: 10, color: Color(0xFF48CAE4), fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF48CAE4), foregroundColor: const Color(0xFF0B132B)),
                  onPressed: () async {
                    try {
                      await Supabase.instance.client.from('profiles').update({
                        'avatar': tempAvatar,
                      }).eq('username', _myUsername);

                      await Supabase.instance.client.from('drops').update({
                        'avatar': tempAvatar,
                      }).eq('author', _myUsername);
                    } catch (_) {}

                    setState(() {
                      _myAvatar = tempAvatar;
                    });
                    Navigator.pop(ctx);
                    _fetchLiveDrops();
                  },
                  child: const Text('Guardar Avatar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showSupportModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C2541),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('💛 Apoyar Gotas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFD166))),
            const SizedBox(height: 6),
            const Text('Elige tu método de aporte voluntario:', style: TextStyle(fontSize: 12, color: Colors.white70)),
            const SizedBox(height: 14),
            ListTile(
              tileColor: const Color(0xFF0B132B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFFF5E5B))),
              leading: const Text('☕', style: TextStyle(fontSize: 20)),
              title: const Text('Ko-fi (1 USD / Tarjetas / PayPal)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.copy, size: 16, color: Colors.white60),
              onTap: () {
                Clipboard.setData(const ClipboardData(text: 'https://ko-fi.com/haseonick'));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📋 Enlace de Ko-fi copiado: https://ko-fi.com/haseonick')));
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              tileColor: const Color(0xFF0B132B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFF3BA2F))),
              leading: const Text('⚡', style: TextStyle(fontSize: 20)),
              title: const Text('Binance Pay (Usuario: haseonick)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.copy, size: 16, color: Colors.white60),
              onTap: () {
                Clipboard.setData(const ClipboardData(text: 'haseonick'));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📋 Usuario de Binance Pay copiado: haseonick')));
              },
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ajustar Batería Social', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListTile(
              leading: const Text('⚡', style: TextStyle(fontSize: 20)),
              title: const Text('Alta (100%) - Con ganas de charlar'),
              onTap: () {
                setState(() => _socialBattery = '⚡ Alta (100%)');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Text('☕', style: TextStyle(fontSize: 20)),
              title: const Text('Tranquilo (60%) - Respuestas lentas'),
              onTap: () {
                setState(() => _socialBattery = '☕ Tranquilo (60%)');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Text('🪫', style: TextStyle(fontSize: 20)),
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
