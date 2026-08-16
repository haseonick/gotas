import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- CONFIGURACIÓN DE SUPABASE EN VIVO ---
const String supabaseUrl = 'https://cfkaqkeohyphdcnvcnsv.supabase.co';
const String supabaseAnonKey = 'sb_publishable_E7NPno9DbRRJYuSVlOmwtA_bvVWxcWK';

// --- VERSIÓN ACTUAL DE LA APP ---
const String currentAppVersion = '1.0.0'; 

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
  int _onlineCount = 1;
  RealtimeChannel? _presenceChannel;
  bool _isRegistered = false;
  bool _isCheckingSession = true;

  // Variables para el Onboarding / Login
  int _onboardingStep = 0; 
  String _onboardingAvatar = '🐺';
  final TextEditingController _onboardingNameController = TextEditingController();
  final TextEditingController _loginEmailController = TextEditingController();
  bool _isAuthLoading = false;

  String _myUsername = '';
  String _myAvatar = '🐺';

  // Votaciones de Dilemas
  String? _dilemmaChoice1;
  String? _dilemmaChoice2;
  String? _dilemmaChoice3;

  // Filtros de las vistas
  String _currentDropsFilter = 'all';
  String _currentAlmasFilter = 'friends';
  String _currentBuzonFilter = 'sent';

  List<dynamic> _savedDropIds = [];
  List<Map<String, dynamic>> _liveDrops = [];
  bool _isLoadingDrops = true;

  List<Map<String, String>> _privateJournal = [];
  List<Map<String, String>> _mySentReplies = [];
  List<Map<String, String>> _myFriendsList = [];
  List<Map<String, dynamic>> _directLetters = [];

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
    _checkForUpdates(); 
    _loadSavedSession();
    _subscribeToLiveChanges();
    _initPresenceTracker();
  }

  Future<void> _checkForUpdates() async {
    try {
      final data = await Supabase.instance.client.from('app_config').select().limit(1).maybeSingle();
      if (data != null) {
        final latestVersion = data['latest_version']?.toString();
        final isMandatory = data['is_mandatory'] as bool? ?? false;
        
        if (latestVersion != null && latestVersion != currentAppVersion) {
          if (mounted) _showUpdateDialog(latestVersion, isMandatory);
        }
      }
    } catch (e) { debugPrint('Error comprobando actualizaciones: $e'); }
  }

  void _showUpdateDialog(String latestVersion, bool isMandatory) {
    showDialog(
      context: context,
      barrierDismissible: !isMandatory,
      builder: (ctx) => WillPopScope(
        onWillPop: () async => !isMandatory,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1C2541),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF48CAE4), width: 1.5)),
          title: const Row(children: [Text('🚀', style: TextStyle(fontSize: 24)), SizedBox(width: 10), Expanded(child: Text('Nueva versión disponible', style: TextStyle(color: Color(0xFFCAF0F8), fontSize: 16, fontWeight: FontWeight.bold)))]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('La versión $latestVersion de Gotas está lista.', style: const TextStyle(color: Colors.white, fontSize: 14)),
              const SizedBox(height: 8),
              Text(isMandatory ? 'Esta actualización es obligatoria para asegurar tu conexión al backend.' : 'Te recomendamos actualizar para disfrutar de más calma y nuevas funciones.', style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.4)),
              const SizedBox(height: 14),
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF0B132B), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)), child: const Text('Link de descarga:\nhttps://haseonick.github.io/gotas/', style: TextStyle(fontSize: 12, color: Color(0xFF48CAE4))))
            ],
          ),
          actions: [
            if (!isMandatory) TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Más tarde', style: TextStyle(color: Colors.white60))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0077B6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () {
                Clipboard.setData(const ClipboardData(text: 'https://haseonick.github.io/gotas/'));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🔗 Enlace copiado en el portapapeles')));
                if (!isMandatory) Navigator.pop(ctx);
              },
              child: const Text('Copiar Link 🔗', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUser = prefs.getString('gotas_user_name');
      final savedAvatar = prefs.getString('gotas_user_avatar');
      final savedReg = prefs.getBool('gotas_user_registered') ?? false;

      _dilemmaChoice1 = prefs.getString('gotas_dilemma_1');
      _dilemmaChoice2 = prefs.getString('gotas_dilemma_2');
      _dilemmaChoice3 = prefs.getString('gotas_dilemma_3');

      final journalStr = prefs.getString('gotas_journal');
      if (journalStr != null) {
        final List decoded = jsonDecode(journalStr);
        _privateJournal = decoded.map((e) => Map<String, String>.from(e)).toList();
      }

      final repliesStr = prefs.getString('gotas_sent_replies');
      if (repliesStr != null) {
        final List decoded = jsonDecode(repliesStr);
        _mySentReplies = decoded.map((e) => Map<String, String>.from(e)).toList();
      }

      final savedDropsStr = prefs.getString('gotas_saved_drops');
      if (savedDropsStr != null) {
        _savedDropIds = jsonDecode(savedDropsStr);
      }

      final friendsStr = prefs.getString('gotas_friends');
      if (friendsStr != null) {
        final List decodedF = jsonDecode(friendsStr);
        _myFriendsList = decodedF.map((e) => Map<String, String>.from(e)).toList();
      }

      if (mounted) {
        setState(() {
          if (savedUser != null && savedUser.isNotEmpty && savedReg) {
            _myUsername = savedUser;
            _myAvatar = savedAvatar ?? '🐺';
            _isRegistered = true;
          } else {
            _isRegistered = false;
          }
            _isCheckingSession = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingSession = false);
      }
    }

    _fetchLiveDrops();
    if (_isRegistered) {
      _fetchDirectLetters();
    }
  }

  final List<Map<String, dynamic>> _starterCommunityDrops = [
    {
      'id': 1,
      'author': 'Yuki',
      'location': '🇯🇵 Kioto, Japón',
      'avatar': '🦊',
      'topic': 'Videojuegos & Paz',
      'content': 'Me gusta construir granjas en Minecraft mientras escucho lluvia. ¿Tienes algún rincón donde te sientas en paz?',
    }
  ];

  Future<void> _fetchLiveDrops() async {
    setState(() => _isLoadingDrops = true);
    try {
      final data = await Supabase.instance.client
          .from('drops')
          .select()
          .order('created_at', ascending: false);
      if (mounted) {
        final List<Map<String, dynamic>> fetched = List<Map<String, dynamic>>.from(data);
        setState(() {
          _liveDrops = fetched.isNotEmpty ? fetched : _starterCommunityDrops;
          _isLoadingDrops = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (_liveDrops.isEmpty) _liveDrops = _starterCommunityDrops;
          _isLoadingDrops = false;
        });
      }
    }
  }

  Future<void> _fetchDirectLetters() async {
    try {
      final data = await Supabase.instance.client
          .from('direct_letters')
          .select()
          .or('recipient.eq.$_myUsername,sender.eq.$_myUsername')
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _directLetters = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (_) {}
  }

  void _subscribeToLiveChanges() {
    try {
      Supabase.instance.client
          .channel('public:drops_and_letters')
          .onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'drops', callback: (payload) => _fetchLiveDrops())
          .onPostgresChanges(event: PostgresChangeEvent.insert, schema: 'public', table: 'direct_letters', callback: (payload) => _fetchDirectLetters())
          .subscribe();
    } catch (_) {}
  }

  void _initPresenceTracker() {
    try {
      final userKey = '${_myUsername.isNotEmpty ? _myUsername : 'Viajero'}_${math.Random().nextInt(99999)}';
      _presenceChannel = Supabase.instance.client.channel('gotas_online_room');

      _presenceChannel!
        .onPresenceSync((_) {
          final state = _presenceChannel!.presenceState();
          if (mounted) setState(() => _onlineCount = math.max(1, state.length));
        })
        .onPresenceJoin((_) {
          final state = _presenceChannel!.presenceState();
          if (mounted) setState(() => _onlineCount = math.max(1, state.length));
        })
        .onPresenceLeave((_) {
          final state = _presenceChannel!.presenceState();
          if (mounted) setState(() => _onlineCount = math.max(1, state.length));
        })
        .subscribe((status, [error]) async {
          if (status == RealtimeSubscribeStatus.subscribed) {
            await _presenceChannel!.track({
              'user': _myUsername,
              'avatar': _myAvatar,
              'online_at': DateTime.now().toIso8601String(),
            });
          }
        });
    } catch (_) {}
  }

  String _generateRandomName() {
    final sustantivos = ['Caminante', 'Zorro', 'Búho', 'Gato', 'Conejo', 'Lobo', 'Viajero', 'Eco', 'Bruma', 'Nómada', 'Lector', 'Panda', 'Erizo', 'Ciervo', 'Rana', 'Pingüino', 'Tortuga'];
    final adjetivos = ['Silencioso', 'Sereno', 'Tranquilo', 'Nocturno', 'Calmo', 'Lofi', 'Pacífico', 'Suave', 'Astral', 'Zen', 'Pensativo', 'Solitario'];
    final rand = math.Random();
    return '${sustantivos[rand.nextInt(sustantivos.length)]}${adjetivos[rand.nextInt(adjetivos.length)]}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingSession) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF48CAE4))));
    }

    if (!_isRegistered) return _buildOnboardingScreen();

    final List<Widget> pages = [
      _buildGotasPage(),
      _buildAlmasPage(),
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
            const Text('Gotas', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFCAF0F8))),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: const Color(0x2606D6A0), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x6606D6A0))),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('●', style: TextStyle(color: Color(0xFF06D6A0), fontSize: 9)),
                  const SizedBox(width: 4),
                  Text('$_onlineCount', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.favorite, color: Color(0xFFFF5E5B)), tooltip: 'Apoyar el proyecto', onPressed: _showSupportModal),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ActionChip(
              backgroundColor: const Color(0xFF1C2541),
              side: const BorderSide(color: Color(0x3348CAE4)),
              label: Text(_socialBattery, style: const TextStyle(fontSize: 11, color: Color(0xFF90E0EF))),
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
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Almas'),
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

  // ==========================================
  // PANTALLA INICIAL OBLIGATORIA (ONBOARDING)
  // ==========================================
  Widget _buildOnboardingScreen() {
    Widget content;
    
    if (_onboardingStep == 0) {
      content = _buildStep0Choice();
    } else if (_onboardingStep == 1) {
      content = _buildStep1Create();
    } else {
      content = _buildStep2LoginEmailDirect(); // Nueva recuperación directa
    }

    return Scaffold(
      body: Container(
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
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Card(
                key: ValueKey<int>(_onboardingStep),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: Color(0xFF48CAE4), width: 1.5),
                ),
                color: const Color(0xFF1C2541),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep0Choice() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const WaterDropIcon(size: 54),
        const SizedBox(height: 16),
        const Text('Bienvenido a Gotas', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        const Text('Un refugio digital de baja presión.\nConecta a tu propio ritmo.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.white60, height: 1.4)),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF48CAE4),
              foregroundColor: const Color(0xFF0B132B),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => setState(() => _onboardingStep = 1),
            child: const Text('Comenzar como Nuevo Viajero 🌊', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF48CAE4),
              side: const BorderSide(color: Color(0xFF48CAE4)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => setState(() => _onboardingStep = 2),
            child: const Text('Ya tengo una cuenta (Recuperar) 🔄', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ),
      ],
    );
  }

  Widget _buildStep1Create() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white70), onPressed: () => setState(() => _onboardingStep = 0)),
        ),
        const WaterDropIcon(size: 32),
        const SizedBox(height: 12),
        const Text('Crear Identidad', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: const Color(0xFF0B132B), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x3348CAE4))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(radius: 20, backgroundColor: const Color(0x3348CAE4), child: Text(_onboardingAvatar, style: const TextStyle(fontSize: 20))),
              const SizedBox(width: 12),
              Text(_onboardingNameController.text.isNotEmpty ? _onboardingNameController.text : 'Escribe tu alias...', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _onboardingNameController.text.isNotEmpty ? Colors.white : Colors.white38)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Align(alignment: Alignment.centerLeft, child: Text('1. Elige tu Avatar:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF90E0EF)))),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 6, mainAxisSpacing: 6),
            itemCount: _availableAvatars.length,
            itemBuilder: (c, i) {
              final av = _availableAvatars[i];
              final isSel = _onboardingAvatar == av;
              return GestureDetector(
                onTap: () => setState(() => _onboardingAvatar = av),
                child: Container(
                  decoration: BoxDecoration(color: isSel ? const Color(0x3348CAE4) : const Color(0xFF0B132B), borderRadius: BorderRadius.circular(10), border: Border.all(color: isSel ? const Color(0xFF48CAE4) : Colors.white12, width: isSel ? 2 : 1)),
                  child: Center(child: Text(av, style: const TextStyle(fontSize: 18))),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        const Align(alignment: Alignment.centerLeft, child: Text('2. Tu Nombre o Apodo:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF90E0EF)))),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _onboardingNameController,
                onChanged: (v) => setState(() {}),
                decoration: InputDecoration(hintText: 'Ej: ZorroAzul...', hintStyle: const TextStyle(fontSize: 12, color: Colors.white38), filled: true, fillColor: const Color(0xFF0B132B), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0077B6), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () => setState(() => _onboardingNameController.text = _generateRandomName()),
              child: const Text('🎲 Aleatorio', style: TextStyle(fontSize: 11, color: Colors.white)),
            )
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF48CAE4), foregroundColor: const Color(0xFF0B132B), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            onPressed: () {
              final name = _onboardingNameController.text.trim();
              if (name.length < 3) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Escribe un nombre de al menos 3 letras.')));
                return;
              }
              showDialog(
                context: context,
                builder: (c) => AlertDialog(
                  backgroundColor: const Color(0xFF1C2541),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF48CAE4))),
                  title: const Row(children: [Text('🔒', style: TextStyle(fontSize: 22)), SizedBox(width: 8), Text('¿Estás seguro?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFCAF0F8)))]),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Tu nombre será definitivo y permanente.', style: TextStyle(fontSize: 13, color: Colors.white70)),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(color: const Color(0xFF0B132B), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF48CAE4))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Text(_onboardingAvatar, style: const TextStyle(fontSize: 22)), const SizedBox(width: 10), Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white))],
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c), child: const Text('Revisar', style: TextStyle(color: Colors.white60))),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0077B6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () async {
                        Navigator.pop(c);
                        try {
                          await Supabase.instance.client.from('profiles').insert({'username': name, 'avatar': _onboardingAvatar});
                        } catch (_) {}
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('gotas_user_name', name);
                        await prefs.setString('gotas_user_avatar', _onboardingAvatar);
                        await prefs.setBool('gotas_user_registered', true);
                        setState(() {
                          _myUsername = name;
                          _myAvatar = _onboardingAvatar;
                          _isRegistered = true;
                        });
                        _fetchLiveDrops();
                        _fetchDirectLetters();
                      },
                      child: const Text('Sí, confirmar 💧', style: TextStyle(color: Colors.white)),
                    )
                  ],
                ),
              );
            },
            child: const Text('Comenzar 💧', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        )
      ],
    );
  }

  // --- LA NUEVA RECUPERACIÓN DIRECTA (Sin Código) ---
  Widget _buildStep2LoginEmailDirect() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white70), onPressed: () => setState(() => _onboardingStep = 0)),
        ),
        const Text('🔄 Recuperar Cuenta', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        const Text('Ingresa el correo que vinculaste para recuperar a tu viajero y entrar al instante.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.white60, height: 1.5)),
        const SizedBox(height: 24),
        TextField(
          controller: _loginEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'tu-correo@ejemplo.com',
            filled: true,
            fillColor: const Color(0xFF0B132B),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF48CAE4), foregroundColor: const Color(0xFF0B132B), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            onPressed: _isAuthLoading ? null : () async {
              final email = _loginEmailController.text.trim();
              if (email.isEmpty || !email.contains('@')) return;
              
              setState(() => _isAuthLoading = true);
              
              try {
                // Buscamos directamente en la tabla profiles
                final data = await Supabase.instance.client.from('profiles').select().eq('email', email).maybeSingle();
                
                if (data != null) {
                  final name = data['username'];
                  final av = data['avatar'] ?? '🐺';
                  
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('gotas_user_name', name);
                  await prefs.setString('gotas_user_avatar', av);
                  await prefs.setBool('gotas_user_registered', true);

                  setState(() {
                    _myUsername = name;
                    _myAvatar = av;
                    _isRegistered = true;
                    _isAuthLoading = false;
                  });
                  
                  _fetchLiveDrops();
                  _fetchDirectLetters();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✨ ¡Bienvenido de vuelta, $name!')));
                } else {
                  setState(() => _isAuthLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ No encontramos ninguna cuenta vinculada a este correo.')));
                }
              } catch (e) {
                setState(() => _isAuthLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Error de conexión. Intenta de nuevo.')));
              }
            },
            child: _isAuthLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFF0B132B), strokeWidth: 2)) 
              : const Text('Recuperar Viajero', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        )
      ],
    );
  }
  // ==========================================


  // --- PÁGINA: ALMAS AFINES (Agrupación e Hilo de Papel) ---
  Widget _buildAlmasPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('👥 Almas Afines', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('${_myFriendsList.length} guardados', style: const TextStyle(fontSize: 12, color: Color(0xFF48CAE4))),
          ],
        ),
        const SizedBox(height: 4),
        const Text('Viajeros con los que sentiste afinidad. Tu lista es 100% privada.', style: TextStyle(fontSize: 12, color: Colors.white60)),
        const SizedBox(height: 16),

        // Filtros (ChoiceChips)
        Row(
          children: [
            ChoiceChip(
              label: const Text('🌱 Mis Almas Afines'),
              selected: _currentAlmasFilter == 'friends',
              onSelected: (s) => setState(() => _currentAlmasFilter = 'friends'),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('✉️ Hilo de Cartas Directas'),
              selected: _currentAlmasFilter == 'letters',
              onSelected: (s) => setState(() => _currentAlmasFilter = 'letters'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_currentAlmasFilter == 'friends') ...[
          if (_myFriendsList.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1C2541),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x2648CAE4)),
              ),
              child: const Column(
                children: [
                  Text('🌱', style: TextStyle(fontSize: 32)),
                  SizedBox(height: 8),
                  Text('Aún no tienes Almas Afines guardadas.', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Abre cualquier carta que te inspire y toca "🌱 Conectar" para guardar al autor aquí.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.white60)),
                ],
              ),
            )
          else
            ..._myFriendsList.map((fr) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0x3348CAE4))),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0x3348CAE4),
                          child: Text(fr['avatar'] ?? '🐺', style: const TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(fr['username'] ?? 'Viajero', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              const Text('Alma Afín', style: TextStyle(fontSize: 11, color: Color(0xFF90E0EF))),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0077B6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _openCorrespondenceSheet(fr['username'] ?? '', fr['avatar'] ?? '🐺'),
                          child: const Text('Abrir Hilo de Papel', style: TextStyle(fontSize: 11, color: Colors.white)),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16, color: Colors.white38),
                          onPressed: () async {
                            setState(() => _myFriendsList.removeWhere((f) => f['username'] == fr['username']));
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString('gotas_friends', jsonEncode(_myFriendsList));
                          },
                        )
                      ],
                    ),
                  ),
                )),
        ] else ...[
          Builder(
            builder: (context) {
              // Lógica de Agrupación de Cartas
              final Map<String, Map<String, dynamic>> convos = {};
              for (var letter in _directLetters) {
                final isMine = letter['sender'] == _myUsername;
                final otherUser = isMine ? letter['recipient'] : letter['sender'];
                final otherAvatar = isMine ? '💧' : (letter['sender_avatar'] ?? '🐺');
                
                if (!convos.containsKey(otherUser)) {
                  convos[otherUser] = {
                    'username': otherUser,
                    'avatar': otherAvatar,
                    'lastMessage': letter['content'],
                  };
                }
              }
              final groupedList = convos.values.toList();

              if (groupedList.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: const Color(0xFF1C2541), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x2648CAE4))),
                  child: const Column(
                    children: [
                      Text('📭', style: TextStyle(fontSize: 32)),
                      SizedBox(height: 8),
                      Text('No tienes correspondencia iniciada.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white60)),
                    ],
                  ),
                );
              }

              return Column(
                children: groupedList.map((convo) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0x3348CAE4))),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(backgroundColor: const Color(0x3348CAE4), child: Text(convo['avatar'] ?? '🐺')),
                            const SizedBox(width: 10),
                            Text('Correspondencia con ${convo['username']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF48CAE4))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFF0B132B), borderRadius: BorderRadius.circular(10)),
                          child: Text('Última carta: "${convo['lastMessage']}"', style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.white70), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0077B6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            onPressed: () => _openCorrespondenceSheet(convo['username'], convo['avatar']),
                            child: const Text('Abrir Hilo de Papel', style: TextStyle(color: Colors.white, fontSize: 11)),
                          ),
                        )
                      ],
                    ),
                  ),
                )).toList(),
              );
            }
          ),
        ]
      ],
    );
  }

  // --- MODAL DE CORRESPONDENCIA EN TIEMPO REAL ---
  void _openCorrespondenceSheet(String recipient, String avatar) {
    final letterController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C2541),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.75, // 75% de la pantalla
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Text(avatar, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(recipient, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      const Text('Nuestra Correspondencia Lenta', style: TextStyle(fontSize: 12, color: Color(0xFF48CAE4))),
                    ],
                  ),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white60), onPressed: () => Navigator.pop(ctx))
                ],
              ),
              const SizedBox(height: 16),
              
              // Hilo de Cartas (En Tiempo Real)
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: Supabase.instance.client
                      .from('direct_letters')
                      .stream(primaryKey: ['id'])
                      .order('created_at', ascending: true),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF48CAE4)));
                    }
                    
                    // Filtrar solo los mensajes entre Yo y Recipient
                    final threadLetters = snapshot.data!.where((l) => 
                      (l['sender'] == _myUsername && l['recipient'] == recipient) ||
                      (l['sender'] == recipient && l['recipient'] == _myUsername)
                    ).toList();

                    if (threadLetters.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🕊️', style: TextStyle(fontSize: 40)),
                            const SizedBox(height: 10),
                            Text('Este es el inicio de tu correspondencia con $recipient.\nAnímate a escribirle la primera carta.', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: threadLetters.length,
                      itemBuilder: (context, index) {
                        final letter = threadLetters[index];
                        final isMine = letter['sender'] == _myUsername;
                        
                        return Align(
                          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(ctx).size.width * 0.8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isMine ? const Color(0x1A48CAE4) : const Color(0xCC0B132B),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: isMine ? const Color(0x4D48CAE4) : const Color(0x33FFFFFF)),
                            ),
                            child: Column(
                              crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Text(isMine ? 'Tu carta' : 'Carta de ${letter['sender']}', style: const TextStyle(fontSize: 10, color: Colors.white54)),
                                const SizedBox(height: 4),
                                Text('"${letter['content']}"', style: const TextStyle(fontSize: 14, color: Colors.white, fontStyle: FontStyle.italic)),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              
              // Caja de Envío
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B132B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextField(
                      controller: letterController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Escribe tu siguiente carta con serenidad...',
                        hintStyle: TextStyle(fontSize: 12, color: Colors.white38),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0077B6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: Size.zero,
                      ),
                      onPressed: () async {
                        final text = letterController.text.trim();
                        if (text.isNotEmpty) {
                          try {
                            await Supabase.instance.client.from('direct_letters').insert({
                              'sender': _myUsername,
                              'sender_avatar': _myAvatar,
                              'recipient': recipient,
                              'content': text,
                            });
                            letterController.clear();
                          } catch (_) {}
                        }
                      },
                      child: const Text('Enviar Carta ✉️', style: TextStyle(color: Colors.white, fontSize: 12)),
                    )
                  ],
                )
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- 1. PÁGINA: GOTAS ---
  Widget _buildGotasPage() {
    List<Map<String, dynamic>> drops = _liveDrops;
    
    // Aplicar filtro de Almas Afines o Guardadas
    if (_currentDropsFilter == 'saved') {
      drops = drops.where((d) => _savedDropIds.contains(d['id'])).toList();
    } else if (_currentDropsFilter == 'friends') {
      final friendNames = _myFriendsList.map((f) => f['username']).toList();
      drops = drops.where((d) => friendNames.contains(d['author'])).toList();
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

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('🌊 Todas'),
                  selected: _currentDropsFilter == 'all',
                  onSelected: (s) => setState(() => _currentDropsFilter = 'all'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('👥 Almas Afines'),
                  selected: _currentDropsFilter == 'friends',
                  onSelected: (s) => setState(() => _currentDropsFilter = 'friends'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text('🔖 Guardadas (${_savedDropIds.length})'),
                  selected: _currentDropsFilter == 'saved',
                  onSelected: (s) => setState(() => _currentDropsFilter = 'saved'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_isLoadingDrops)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
          else if (drops.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: Text(
                  'No hay cartas en esta sección. Ajusta tus filtros o añade Almas Afines.',
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
      builder: (ctx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          final author = drop['author']?.toString() ?? 'Viajero';
          final isAlreadyFriend = _myFriendsList.any((f) => f['username'] == author);

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              left: 20, right: 20, top: 20,
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
                        Row(
                          children: [
                            Text(author, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(width: 8),
                            if (author != _myUsername)
                              InkWell(
                                onTap: () async {
                                  final av = drop['avatar']?.toString() ?? '🐺';
                                  setState(() {
                                    if (isAlreadyFriend) {
                                      _myFriendsList.removeWhere((f) => f['username'] == author);
                                    } else {
                                      _myFriendsList.add({'username': author, 'avatar': av});
                                    }
                                  });
                                  setModalState(() {}); // Actualiza el botón dentro del modal
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.setString('gotas_friends', jsonEncode(_myFriendsList));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(isAlreadyFriend ? 'Retirado de Almas Afines.' : '🌱 ¡$author añadido a tus Almas Afines!')),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isAlreadyFriend ? const Color(0x3348CAE4) : const Color(0x2606D6A0),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isAlreadyFriend ? const Color(0xFF48CAE4) : const Color(0xFF06D6A0)),
                                  ),
                                  child: Text(
                                    isAlreadyFriend ? '✓ Alma Afín' : '🌱 Conectar',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isAlreadyFriend ? const Color(0xFF48CAE4) : const Color(0xFF06D6A0),
                                      fontWeight: FontWeight.bold
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Text(drop['location']?.toString() ?? 'Mundo', style: const TextStyle(fontSize: 11, color: Colors.white60)),
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
                  width: double.infinity,
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

                // ZONA DE RESPUESTAS LENTAS OBTENIDAS DE SUPABASE
                const Text('💬 Respuestas Lentas Recibidas:', style: TextStyle(color: Color(0xFF90E0EF), fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: FutureBuilder<List<dynamic>>(
                    future: Supabase.instance.client
                        .from('drop_replies')
                        .select()
                        .eq('drop_id', drop['id'])
                        .order('created_at', ascending: true),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator()));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Text('Aún no hay respuestas en esta gota. ¡Sé el primero en responder con calma!', style: TextStyle(color: Colors.white60, fontSize: 12));
                      }
                      return ListView(
                        shrinkWrap: true,
                        children: snapshot.data!.map((r) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0x330077B6),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0x3348CAE4))
                            ),
                            child: Text.rich(TextSpan(children: [
                               TextSpan(text: '${r['author'] ?? 'Viajero'}: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF48CAE4), fontSize: 12)),
                               TextSpan(text: r['content'], style: const TextStyle(color: Colors.white, fontSize: 12)),
                            ])),
                        )).toList(),
                      );
                    }
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
                      onPressed: () async {
                        final dropId = drop['id'];
                        if (dropId != null && !_savedDropIds.contains(dropId)) {
                          setState(() => _savedDropIds.add(dropId));
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('gotas_saved_drops', jsonEncode(_savedDropIds));
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

                          final replyObj = {
                            'topic': drop['topic']?.toString() ?? 'Carta',
                            'author': drop['author']?.toString() ?? 'Viajero',
                            'text': text,
                          };

                          setState(() {
                            _mySentReplies.insert(0, replyObj);
                          });

                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('gotas_sent_replies', jsonEncode(_mySentReplies));

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
          );
        }
      ),
    );
  }

  void _openNewDropDialog() {
    final locationController = TextEditingController();
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
          left: 20, right: 20, top: 20,
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
              controller: locationController,
              decoration: InputDecoration(
                labelText: 'Ubicación (Ej: 🇻🇪 Anzoátegui, o "En mi cuarto")',
                labelStyle: const TextStyle(color: Color(0xFF90E0EF), fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF0B132B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: topicController,
              decoration: InputDecoration(
                labelText: 'Tema (Ej: Hábitos, Calistenia, Videojuegos)',
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
                    final location = locationController.text.trim();
                    final topic = topicController.text.trim();
                    final content = contentController.text.trim();
                    if (content.isNotEmpty) {
                      try {
                        await Supabase.instance.client.from('drops').insert({
                          'author': _myUsername,
                          'location': location.isNotEmpty ? location : 'Tu rincón seguro',
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
    List<Map<String, dynamic>> myPublishedDrops = _liveDrops.where((d) => d['author'] == _myUsername).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('📬 Mi Buzón de Ecos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Historial de tus huellas y correspondencia.', style: TextStyle(fontSize: 12, color: Colors.white60)),
        const SizedBox(height: 16),

        Row(
          children: [
            ChoiceChip(
              label: const Text('📨 Respuestas Enviadas'),
              selected: _currentBuzonFilter == 'sent',
              onSelected: (s) => setState(() => _currentBuzonFilter = 'sent'),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('🌊 Mis Gotas'),
              selected: _currentBuzonFilter == 'mydrops',
              onSelected: (s) => setState(() => _currentBuzonFilter = 'mydrops'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_currentBuzonFilter == 'sent') ...[
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
        ] else ...[
          if (myPublishedDrops.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1C2541),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x2648CAE4)),
              ),
              child: const Column(
                children: [
                  Text('🌊', style: TextStyle(fontSize: 32)),
                  SizedBox(height: 8),
                  Text('No has publicado gotas aún.', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Pulsa el botón flotante "+ Enviar Gota" para escribir tu primera publicación.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.white60)),
                ],
              ),
            )
          else
            ...myPublishedDrops.map((drop) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: GestureDetector(
                onTap: () => _openReadAndReplyDialog(drop),
                child: DropCard(
                  author: 'Tú (${drop['avatar']})',
                  location: drop['location']?.toString() ?? 'Mundo',
                  avatar: drop['avatar']?.toString() ?? '🐺',
                  topic: drop['topic']?.toString() ?? 'Pensamiento',
                  snippet: drop['content']?.toString() ?? '',
                ),
              ),
            ))
        ]
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
          onVote: (c) async {
            setState(() => _dilemmaChoice1 = c);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('gotas_dilemma_1', c);
          },
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
          onVote: (c) async {
            setState(() => _dilemmaChoice2 = c);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('gotas_dilemma_2', c);
          },
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
          onVote: (c) async {
            setState(() => _dilemmaChoice3 = c);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('gotas_dilemma_3', c);
          },
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

  // --- 4. PÁGINA: CREACIÓN EN SILENCIO ---
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

  // --- 5. PÁGINA: DIARIO PRIVADO (Persistente) ---
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
            onPressed: () async {
              final txt = journalController.text.trim();
              if (txt.isNotEmpty) {
                setState(() {
                  _privateJournal.insert(0, {
                    'text': txt,
                    'date': 'Hoy',
                  });
                });
                journalController.clear();
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('gotas_journal', jsonEncode(_privateJournal));
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
              label: const Text('Cambiar Avatar'),
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
                    const Text('🔒 Nombre Permanente', style: TextStyle(fontSize: 11, color: Color(0xFF48CAE4))),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Tarjeta de Respaldo
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0x330077B6), Color(0x1A48CAE4)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x3348CAE4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text('🛡️', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 8),
                  Text('Respaldar mi Cuenta (Opcional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Vincula tu correo para recuperar tu viajero y tus cartas guardadas si reinstalas la app o cambias de teléfono.',
                style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0077B6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _showBackupAccountModal(),
                  child: const Text('Vincular Correo Electrónico', style: TextStyle(color: Colors.white)),
                ),
              )
            ],
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

                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('gotas_user_avatar', tempAvatar);

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

  void _showBackupAccountModal() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C2541),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF48CAE4)),
        ),
        title: const Text('🛡️ Respaldar Cuenta', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingresa tu correo. Esto no será público, solo se usará para recuperación.', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'tu-correo@ejemplo.com',
                hintStyle: const TextStyle(fontSize: 12, color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF0B132B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF48CAE4)),
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isNotEmpty && email.contains('@')) {
                try {
                  await Supabase.instance.client.from('profiles').upsert({
                    'username': _myUsername,
                    'avatar': _myAvatar,
                    'email': email,
                  }, onConflict: 'username');
                  
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✨ Cuenta vinculada exitosamente a $email')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Este correo ya podría estar en uso.')));
                }
              }
            },
            child: const Text('Vincular', style: TextStyle(color: Color(0xFF0B132B), fontWeight: FontWeight.bold)),
          )
        ],
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
