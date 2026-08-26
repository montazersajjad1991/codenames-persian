import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'words.dart';

final SoundManager sounds = SoundManager();

IO.Socket createSocket() {
  return IO.io('http://10.0.2.2:3000', <String, dynamic>{
    'transports': ['websocket'],
    'autoConnect': true,
  });
}

Future<void> _setPortrait() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  } catch (_) {
    // روی ویندوز/وب پشتیبانی نمی‌شود
  }
}

Future<void> _setLandscape() async {
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // قفل کامل جهت صفحه و مخفی کردن نوارهای سیستم
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // جلوگیری از چرخش خودکار
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  } catch (_) {
    // روی ویندوز/وب پشتیبانی نمی‌شود
  }
}

void main() async {
  await _setPortrait(); // اپ در حالت عمودی شروع می‌شود
  sounds.startTheme();
  runApp(const CodenamesApp());
}

// ---------------- مدیریت صدا ----------------
class SoundManager {
  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _music = AudioPlayer();
  bool _isMuted = false;
  bool _themeStarted = false;

  bool get isMuted => _isMuted;

  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      _music.pause();
    } else {
      if (_themeStarted) {
        _music.resume().catchError((_) {});
      } else {
        startTheme();
      }
    }
  }

  void _play(String file) {
    if (_isMuted) return;
    try {
      _player.play(AssetSource('audio/$file')).catchError((_) {});

      // ترفند جلوگیری از قطع موزیک پس‌زمینه در اندروید/وب
      // بلافاصله بعد از پخش افکت، دستور ادامه پخش موزیک ارسال می‌شود
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!_isMuted && _themeStarted) {
          _music.resume().catchError((_) {});
        }
      });
    } catch (_) {}
  }

  void playFlip() => _play('flip.mp3');
  void playCorrect() => _play('correct.mp3');
  void playWrong() => _play('wrong.mp3');
  void playWin() => _play('win.mp3');
  void playLose() => _play('lose.mp3');

  void startTheme() {
    if (_isMuted || _themeStarted) return;
    _themeStarted = true;
    try {
      _music.setReleaseMode(ReleaseMode.loop);
      _music.setVolume(0.35);
      _music.play(AssetSource('audio/theme.mp3')).catchError((_) {});
    } catch (_) {}
  }
}

class CodenamesApp extends StatelessWidget {
  const CodenamesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'اسم رمز',
      debugShowCheckedModeBanner: false,
      home: const MainMenu(),
    );
  }
}

// ---------------- منوی اصلی ----------------
class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // بک‌گراند
            Image.asset(
              'assets/images/menu_bg.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
            // لایه گرادیان تیره برای خوانایی بهتر
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.25),
                    Colors.black.withOpacity(0.65),
                  ],
                ),
              ),
            ),
            // محتوا
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // عنوان با انیمیشن
                      FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _controller,
                          curve:
                              const Interval(0.0, 0.4, curve: Curves.easeOut),
                        ),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, -0.2),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _controller,
                            curve:
                                const Interval(0.0, 0.4, curve: Curves.easeOut),
                          )),
                          child: _buildTitle(),
                        ),
                      ),
                      const SizedBox(height: 48),
                      // دکمه‌ها با انیمیشن ورود تدریجی
                      _buildMenuButton(
                        text: 'بازی آنلاین ۴ نفره',
                        subtitle: 'با دوستانت از راه دور بازی کن',
                        icon: Icons.wifi,
                        gradient: const [Color(0xFF1E88E5), Color(0xFF1565C0)],
                        delay: 200,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const OnlineLobby()),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildMenuButton(
                        text: 'بازی دورهمی (آفلاین)',
                        subtitle: 'یک گوشی، چند نفر',
                        icon: Icons.people,
                        gradient: const [Color(0xFF43A047), Color(0xFF2E7D32)],
                        delay: 350,
                        onTap: () => _askHandsOffline(context),
                      ),
                      const SizedBox(height: 16),
                      _buildMenuButton(
                        text: 'آموزش',
                        subtitle: 'قوانین و ترفندها',
                        icon: Icons.school,
                        gradient: const [Color(0xFFFB8C00), Color(0xFFEF6C00)],
                        delay: 500,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const TutorialPage()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        const Text(
          'اسم رمز',
          style: TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                  color: Colors.black54, blurRadius: 20, offset: Offset(0, 4)),
              Shadow(
                  color: Color(0xFFE8B33C),
                  blurRadius: 40,
                  offset: Offset(0, 0)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.black54, Colors.black38],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white24),
          ),
          child: const Text(
            'بازی حدس کلمات',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuButton({
    required String text,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
    int delay = 0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 800 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 40 * (1 - value)),
            child: child,
          ),
        );
      },
      child: SizedBox(
        width: double.infinity,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: gradient[0].withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            text,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_back_ios,
                        color: Colors.white70, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _askHandsOffline(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF252538),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFFE8B33C), size: 24),
              SizedBox(width: 8),
              Text(
                'چند دست بازی می‌کنید؟',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🎮 راهنمای شروع بازی:',
                style: TextStyle(
                    color: Color(0xFFE8B33C),
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                '۱. مشخص کنید کدام تیم قرمز و کدام تیم آبی است',
                style:
                    TextStyle(color: Colors.white70, fontSize: 12, height: 1.6),
              ),
              const Text(
                '۲. در هر تیم، یک نفر سرنخ‌ده و یک نفر حدس‌زننده باشد',
                style:
                    TextStyle(color: Colors.white70, fontSize: 12, height: 1.6),
              ),
              const Text(
                '۳. تیمی که بیشترین دست را ببرد، برنده بازی است',
                style:
                    TextStyle(color: Colors.white70, fontSize: 12, height: 1.6),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '💡 نکته: می‌توانید با دکمه چشم در بالای صفحه، کارت‌ها را ببینید (مخصوص سرنخ‌ده)',
                  style: TextStyle(
                      color: Colors.orange, fontSize: 11, height: 1.4),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GameBoard(maxHands: 3),
                  ),
                );
              },
              child: const Text(
                '۳ دست',
                style: TextStyle(color: Colors.blue, fontSize: 17),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GameBoard(maxHands: 5),
                  ),
                );
              },
              child: const Text(
                '۵ دست',
                style: TextStyle(color: Colors.blue, fontSize: 17),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ---------------- آموزش ----------------

// ---------------- آموزش ----------------
class TutorialPage extends StatelessWidget {
  const TutorialPage({super.key});

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFFE8B33C),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _box(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF252538),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3A3A55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _rule(int n, List<InlineSpan> spans) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFF2F6FD0),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$n',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(children: spans),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardSample(
    String img,
    Color border,
    Color titleColor,
    String title,
    String desc,
  ) {
    return SizedBox(
      width: 110,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: border, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(img, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              height: 1.7,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFC62828);
    const blue = Color(0xFF1E88E5);
    const tan = Color(0xFFB9A77F);
    const black = Color(0xFF424242);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF14141F),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2D1B4E),
          title: const Text(
            'آموزش اسم رمز',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _sectionTitle('🕵️ اسم رمز چیست؟'),
              _box([
                const Text(
                  'دو تیم قرمز و آبی؛ هر تیم یک سرنخ‌ده و یک حدس‌زننده دارد. هدف این است که با کمک سرنخ‌ده، همه کلمات تیم خود را قبل از حریف پیدا کنید!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.9,
                  ),
                  textAlign: TextAlign.center,
                ),
              ]),
              const SizedBox(height: 24),
              _sectionTitle('📜 قوانین بازی'),
              _box([
                _rule(1, [
                  const TextSpan(
                    text:
                        'سرنخ‌ده، رنگ کارت‌ها را می‌بیند و یک کلمه + یک عدد می‌دهد (حداکثر ۱۵ کاراکتر با احتساب فاصله، بدون عدد، انگلیسی و کلمه روی میز).',
                  ),
                ]),
                _rule(2, [
                  const TextSpan(
                    text:
                        'سرنخ‌ده ۹۰ ثانیه وقت دارد؛ حدس‌زننده ۳۰ ثانیه به ازای هر عدد گفته‌شده (سرنخ ۲ = ۶۰ ثانیه). دیر بجنبی، نوبت می‌سوزه!',
                  ),
                ]),
                _rule(3, [
                  const TextSpan(text: 'کارت تیم خودت = '),
                  const TextSpan(
                    text: 'ادامه',
                    style: TextStyle(
                      color: Color(0xFF66BB6A),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: '، کارت خنثی = '),
                  const TextSpan(
                    text: 'ادامه',
                    style: TextStyle(
                      color: Color(0xFF66BB6A),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: '، کارت حریف = '),
                  const TextSpan(
                    text: 'سوختن نوبت',
                    style: TextStyle(
                      color: Color(0xFFFFB74D),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: '، آدمکش = '),
                  const TextSpan(
                    text: 'باخت فوری!',
                    style: TextStyle(
                      color: Color(0xFFEF5350),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ]),
                _rule(4, [
                  const TextSpan(text: 'نوبت اول با تیمی است که ۹ کارت دارد.'),
                ]),
                _rule(5, [
                  const TextSpan(
                    text:
                        'حدس‌زننده فقط به تعداد عدد سرنخ می‌تواند درست حدس بزند.',
                  ),
                ]),
              ]),
              const SizedBox(height: 24),
              _sectionTitle('🎨 کارت‌ها'),
              _box([
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 16,
                  children: [
                    _cardSample(
                      'assets/images/red_1.png',
                      red,
                      red,
                      'کارت تیم قرمز',
                      'کارت‌های تیم قرمز را پیدا کنید.',
                    ),
                    _cardSample(
                      'assets/images/blue_1.png',
                      blue,
                      blue,
                      'کارت تیم آبی',
                      'کارت‌های تیم آبی را پیدا کنید.',
                    ),
                    _cardSample(
                      'assets/images/by_1.png',
                      tan,
                      Colors.white70,
                      'کارت خنثی',
                      'بی‌خطر است، می‌توانید ادامه دهید.',
                    ),
                    _cardSample(
                      'assets/images/blue_2.png',
                      blue,
                      Colors.white70,
                      'کارت حریف',
                      'حدس اشتباه، نوبت شما تمام می‌شود.',
                    ),
                    _cardSample(
                      'assets/images/assassin.png',
                      black,
                      const Color(0xFFEF5350),
                      'آدمکش',
                      'اگر این کارت را بزنید، تیم شما فوراً می‌بازد!',
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- لابی آنلاین ۴ نفره ----------------
class OnlineLobby extends StatefulWidget {
  const OnlineLobby({super.key});

  @override
  State<OnlineLobby> createState() => _OnlineLobbyState();
}

class _OnlineLobbyState extends State<OnlineLobby> {
  late IO.Socket _socket;
  String? _roomCode;
  bool _isHost = false;
  bool _navigated = false;
  String _status = 'در حال اتصال به سرور...';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _joinController = TextEditingController();
  bool _isPublic = true;
  List<String> _friends = [];
  final TextEditingController _friendIdController = TextEditingController();
  String _mode = 'main';
  int _maxHands = 3;
  List<Map<String, dynamic>> _publicRooms = [];

  List<Map<String, dynamic>> _players = [];
  final Map<String, String?> _slots = {
    't1s': null,
    't1g': null,
    't2s': null,
    't2g': null,
  };

  @override
  void initState() {
    super.initState();
    _socket = createSocket();
    _socket.onConnect((_) => setState(() => _status = 'متصل به سرور ✅'));
    _socket.onConnectError(
      (_) => setState(() => _status = '❌ خطا در اتصال! سرور روشنه؟'),
    );
    _socket.on('players', (list) {
      setState(() {
        _players =
            (list as List).map((e) => Map<String, dynamic>.from(e)).toList();
      });
    });
    _socket.on('setup', (data) {
      _applySetup(
        (data['assignments'] as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
      );
    });
  }

  String _myId() => _socket.id ?? '';

  String _nameOf(String id) {
    for (final p in _players) {
      if (p['id'] == id) return p['name'];
    }
    return '؟';
  }

  List<String> _poolIds() {
    final used = _slots.values.whereType<String>().toSet();
    return _players
        .map((p) => p['id'] as String)
        .where((id) => !used.contains(id))
        .toList();
  }

  void _fetchRooms() {
    _socket.emitWithAck(
      'list_rooms',
      {},
      ack: (res) {
        if (res != null && res['rooms'] != null) {
          setState(() {
            _publicRooms = (res['rooms'] as List)
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          });
        }
      },
    );
  }

  void _createRoom() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _status = 'اول اسمت رو بنویس!');
      return;
    }
    // سرور خودش کد ۵ رقمی رندوم می‌سازد، ما فقط نام و حالت عمومی/خصوصی را می‌فرستیم
    _socket.emitWithAck(
      'create_room',
      {'name': name, 'isPublic': _isPublic},
      ack: (res) {
        setState(() {
          _roomCode = res['code'];
          _isHost = true;
        });
      },
    );
  }

  void _addFriend() {
    final friendId = _friendIdController.text.trim();
    if (friendId.isNotEmpty && !_friends.contains(friendId)) {
      setState(() => _friends.add(friendId));
      _friendIdController.clear();
      _socket.emit('add_friend', {
        'friendId': friendId,
      }); // ارسال به سرور (اگر پشتیبانی کند)
    }
  }

  void _removeFriend(String friendId) {
    setState(() => _friends.remove(friendId));
    _socket.emit('remove_friend', {'friendId': friendId});
  }

  void _joinRoom() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _status = 'اول اسمت رو بنویس!');
      return;
    }
    _socket.emitWithAck(
      'join_room',
      {'code': _joinController.text, 'name': name},
      ack: (res) {
        if (res['error'] != null) {
          setState(() => _status = res['error']);
        } else {
          setState(() => _roomCode = res['code']);
        }
      },
    );
  }

  void _joinRoomById(String code) {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _status = 'اول اسمت رو بنویس!');
      return;
    }
    _socket.emitWithAck(
      'join_room',
      {'code': code, 'name': name},
      ack: (res) {
        if (res['error'] != null) {
          setState(() => _status = res['error']);
        } else {
          setState(() => _roomCode = res['code']);
        }
      },
    );
  }

  void _askHands(VoidCallback onStart) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF252538),
          title: const Text(
            'چند دست بازی می‌کنید؟',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'تیمی که بیشترین دست رو ببره، برندهٔ بازیه.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _maxHands = 3);
                onStart();
              },
              child: const Text(
                '۳ دست',
                style: TextStyle(color: Colors.blue, fontSize: 17),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _maxHands = 5);
                onStart();
              },
              child: const Text(
                '۵ دست',
                style: TextStyle(color: Colors.blue, fontSize: 17),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _start() {
    final firstRed = Random().nextBool();
    final t1 = firstRed ? 'red' : 'blue';
    final t2 = firstRed ? 'blue' : 'red';
    final assignments = <Map<String, dynamic>>[];
    void add(String slot, String team, String role) {
      final id = _slots[slot];
      if (id != null) assignments.add({'id': id, 'team': team, 'role': role});
    }

    add('t1s', t1, 'spymaster');
    add('t1g', t1, 'guesser');
    add('t2s', t2, 'spymaster');
    add('t2g', t2, 'guesser');
    _socket.emit('setup', {'assignments': assignments, 'maxHands': _maxHands});
    _applySetup(assignments);
  }

  void _applySetup(List<Map<String, dynamic>> assignments) {
    if (_navigated) return;
    String team = 'red';
    String role = 'guesser';
    for (final a in assignments) {
      if (a['id'] == _myId()) {
        team = a['team'];
        role = a['role'];
      }
    }
    _navigated = true;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameBoard(
          online: true,
          myTeam: team,
          role: role,
          isHost: _isHost,
          socket: _socket,
          roomCode: _roomCode,
          maxHands: _maxHands,
        ),
      ),
    );
  }

  Widget _chip(String id, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _nameOf(id),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _draggableChip(String id) {
    return Draggable<String>(
      data: id,
      feedback: Material(
        color: Colors.transparent,
        child: _chip(id, Colors.amber),
      ),
      childWhenDragging: const SizedBox.shrink(),
      child: _chip(id, Colors.amber),
    );
  }

  Widget _slot(String key, String label, Color color) {
    final id = _slots[key];
    return DragTarget<String>(
      onAccept: (d) {
        setState(() {
          _slots.updateAll((k, v) => v == d ? null : v);
          _slots[key] = d;
        });
      },
      builder: (context, candidate, rejected) {
        return Container(
          width: 160,
          height: 56,
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.25),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: id == null
                ? Text(label, style: TextStyle(color: color, fontSize: 12))
                : _draggableChip(id),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final allAssigned = _slots.values.every((v) => v != null);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1E1E2E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2D1B4E),
          title: const Text(
            'بازی آنلاین ۴ نفره',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _status,
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D1B4E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF5D4B8A)),
                  ),
                  child: const Text(
                    '🎮 این بازی ۴ نفره است: ۲ تیم ۲ نفره\nهر تیم: ۱ سرنخ‌ده + ۱ حدس‌زننده',
                    style: TextStyle(color: Colors.white, height: 1.6),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                // بخش مدیریت دوستان
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '👥 لیست دوستان',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _friendIdController,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'آیدی دوست...',
                                hintStyle: TextStyle(color: Colors.white54),
                                isDense: true,
                                filled: true,
                                fillColor: Colors.white10,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _addFriend,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                            child: const Text(
                              'افزودن',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_friends.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _friends
                              .map(
                                (f) => Chip(
                                  label: Text(
                                    f,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                  ),
                                  backgroundColor: Colors.blueGrey,
                                  deleteIcon: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  onDeleted: () => _removeFriend(f),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_roomCode == null) ...[
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'اسم تو',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_mode == 'main') ...[
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () => setState(() => _mode = 'create'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          '🏠 ساخت اتاق جدید',
                          style: TextStyle(fontSize: 17, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () => setState(() => _mode = 'join'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          '🔑 پیوستن با کد اتاق',
                          style: TextStyle(fontSize: 17, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _mode = 'list');
                          _fetchRooms();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          '📋 دیدن اتاق‌های عمومی',
                          style: TextStyle(fontSize: 17, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                  if (_mode == 'create') ...[
                    const Text(
                      'یک کد ۵ رقمی رندوم به صورت خودکار برای اتاق شما ساخته می‌شود.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: _isPublic,
                          onChanged: (v) => setState(() => _isPublic = v!),
                        ),
                        const Text(
                          'عمومی (بقیه بتونن پیداش کنن)',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                    if (!_isPublic)
                      const Text(
                        '🔒 خصوصی: فقط با کد وارد می‌شن',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _createRoom,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          '✅ ساخت اتاق',
                          style: TextStyle(fontSize: 17, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() => _mode = 'main'),
                      child: const Text(
                        '↩️ برگشت',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                  if (_mode == 'join') ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _joinController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'کد اتاق',
                              hintStyle: const TextStyle(color: Colors.white38),
                              filled: true,
                              fillColor: Colors.white10,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _joinRoom,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: const Text(
                            'ورود',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() => _mode = 'main'),
                      child: const Text(
                        '↩️ برگشت',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                  if (_mode == 'list') ...[
                    const Text(
                      'اتاق‌های عمومی:',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    if (_publicRooms.isEmpty)
                      const Text(
                        'فعلاً اتاق عمومی‌ای ساخته نشده 😕',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ..._publicRooms.map(
                      (r) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${r['roomName']}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '👥 ${r['players']}/4 بازیکن',
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => _joinRoomById('${r['code']}'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: const Text(
                                'ورود',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: _fetchRooms,
                          child: const Text(
                            '🔄 تازه‌سازی',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _mode = 'main'),
                          child: const Text(
                            '↩️ برگشت',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ],
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _roomCode!,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'بازیکن‌ها (${_players.length}/4):',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _players
                        .map((p) => _chip(p['id'], Colors.grey))
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  if (_isHost && _players.length == 4) ...[
                    const Text(
                      'بازیکن‌ها رو بکش و رها کن:',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    DragTarget<String>(
                      onAccept: (d) {
                        setState(() {
                          _slots.updateAll((k, v) => v == d ? null : v);
                        });
                      },
                      builder: (context, candidate, rejected) {
                        return Wrap(
                          spacing: 8,
                          children: _poolIds()
                              .map((id) => _draggableChip(id))
                              .toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            const Text(
                              'تیم ۱',
                              style: TextStyle(color: Colors.orange),
                            ),
                            _slot('t1s', 'سرنخ‌ده', Colors.orange),
                            _slot('t1g', 'حدس‌زننده', Colors.orange),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Column(
                          children: [
                            const Text(
                              'تیم ۲',
                              style: TextStyle(color: Colors.teal),
                            ),
                            _slot('t2s', 'سرنخ‌ده', Colors.teal),
                            _slot('t2g', 'حدس‌زننده', Colors.teal),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed:
                          allAssigned ? () => _askHands(() => _start()) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 14,
                        ),
                      ),
                      child: const Text(
                        '🚀 شروع بازی',
                        style: TextStyle(color: Colors.white, fontSize: 17),
                      ),
                    ),
                  ] else if (_isHost)
                    const Text(
                      'منتظر بازیکن‌های بیشتر...',
                      style: TextStyle(color: Colors.white70),
                    )
                  else
                    const Text(
                      'منتظر تنظیم تیم‌ها توسط میزبان...',
                      style: TextStyle(color: Colors.white70),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- صفحه انتظار نویر ----------------
class _WaitingView extends StatefulWidget {
  const _WaitingView();

  @override
  State<_WaitingView> createState() => _WaitingViewState();
}

class _WaitingViewState extends State<_WaitingView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFB9A77F), width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/waiting.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 24),
          FadeTransition(
            opacity: _pulse,
            child: const Text(
              'در انتظار شروع بازی توسط میزبان...',
              style: TextStyle(
                color: Color(0xFFE8D8B8),
                fontSize: 16,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black, blurRadius: 6)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- بزرگ‌نمایی کارت ----------------
class _ZoomOverlay extends StatefulWidget {
  final String img;
  final String word;
  final Color strip;
  final VoidCallback onDone;

  const _ZoomOverlay({
    required this.img,
    required this.word,
    required this.strip,
    required this.onDone,
  });

  @override
  State<_ZoomOverlay> createState() => _ZoomOverlayState();
}

class _ZoomOverlayState extends State<_ZoomOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.1, end: 1.0), weight: 35),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.1), weight: 30),
    ]).animate(_c);
    _c.forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width * 0.75;
    final h = w * 2 / 3;
    return Center(
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: w,
          height: h > size.height * 0.75 ? size.height * 0.75 : h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.strip, width: 4),
            boxShadow: const [
              BoxShadow(
                color: Colors.black87,
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(widget.img, fit: BoxFit.cover),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    color: widget.strip,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    child: Text(
                      widget.word,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- کارت با انیمیشن فلپ ----------------
class FlipCard extends StatefulWidget {
  final bool revealed;
  final Widget front;
  final Widget back;
  final VoidCallback onTap;

  const FlipCard({
    super.key,
    required this.revealed,
    required this.front,
    required this.back,
    required this.onTap,
  });

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    if (widget.revealed) _controller.value = 1;
  }

  @override
  void didUpdateWidget(FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.revealed && !oldWidget.revealed) {
      sounds.playFlip();
      _controller.forward(from: 0);
    }
    if (!widget.revealed && oldWidget.revealed) {
      _controller.reverse(from: 1);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final v = _controller.value;
        final showBack = v >= 0.5;
        final double scaleX = showBack ? (v - 0.5) * 2 : 1 - v * 2;
        return GestureDetector(
          onTap: widget.onTap,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..scale(scaleX.clamp(0.0, 1.0), 1.0, 1.0),
            child: showBack ? widget.back : widget.front,
          ),
        );
      },
    );
  }
}

// ---------------- صفحه بازی ----------------
class GameBoard extends StatefulWidget {
  final bool online;
  final String myTeam;
  final String role;
  final bool isHost;
  final IO.Socket? socket;
  final String? roomCode;
  final int maxHands;

  const GameBoard({
    super.key,
    this.online = false,
    this.myTeam = 'red',
    this.role = 'guesser',
    this.isHost = false,
    this.socket,
    this.roomCode,
    this.maxHands = 3,
  });

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> with TickerProviderStateMixin {
  final List<String> _words = [];
  final List<String> _cardColors = [];
  final List<bool> _revealed = [];
  final List<String> _cardArt = [];
  final List<double> _cardRotations = []; // برای چرخش طبیعی و دستی کارت‌ها
  final TextEditingController _clueController = TextEditingController();
  bool _spymasterView = false;
  String _currentTeam = 'red';
  String? _clue;
  int _clueNumber = 1;
  int _selectedNumber = 1;
  int _guessesUsed = 0;
  String? _winner;
  bool _assassinHit = false;
  bool _ready = true;
  bool _opponentLeft = false;
  bool _reconnecting = false;
  String? _lastSocketId;
  String? _zoomImg;
  String _zoomWord = '';
  Color _zoomStrip = Colors.black;
  String? _pendingWinner;
  int _maxHands = 3;
  int _redWins = 0;
  int _blueWins = 0;
  int _hand = 1;
  String? _matchWinner;
  int _turnStart = 0;
  int _clueStart = 0;
  int _remainingSec = 90;
  Timer? _tickTimer;

  late AnimationController _shakeController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _turnBannerPulseController;
  late Animation<double> _turnBannerPulseAnimation;
  double _shakeDx = 0;
  bool _showTurnChangeMessage = false;

  @override
  void initState() {
    super.initState();
    _setLandscape(); // وقتی وارد بازی می‌شویم، حالت افقی فعال شود
    _maxHands = widget.maxHands;
    sounds.startTheme();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addListener(() {
        setState(() {
          final t = _shakeController.value;
          _shakeDx = sin(t * pi * 6) * 10 * (1 - t);
        });
      });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _turnBannerPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _turnBannerPulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
          parent: _turnBannerPulseController, curve: Curves.easeInOut),
    );

    if (widget.online) {
      _ready = false;
      _spymasterView = widget.role == 'spymaster';
      _tickTimer = Timer.periodic(
        const Duration(milliseconds: 250),
        (_) => _updateTimer(),
      );
      widget.socket!.on('board', _onBoard);
      widget.socket!.on('state', _onState);
      widget.socket!.on('player_left', (_) {
        setState(() => _opponentLeft = true);
      });
      _lastSocketId = widget.socket!.id;
      widget.socket!.on('connect', (_) {
        final newId = widget.socket!.id;
        if (_lastSocketId != null && newId != _lastSocketId) {
          widget.socket!.emit('rejoin', {
            'room': widget.roomCode,
            'oldId': _lastSocketId,
          });
        }
        _lastSocketId = newId;
        if (mounted) setState(() => _reconnecting = false);
      });
      widget.socket!.on('disconnect', (_) {
        if (mounted) setState(() => _reconnecting = true);
      });
      if (widget.isHost) {
        _startNewGame();
        _ready = true;
      }
    } else {
      _startNewGame();
    }
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _shakeController.dispose();
    _pulseController.dispose();
    _turnBannerPulseController.dispose();
    _clueController.dispose();
    if (widget.online) widget.socket!.disconnect();
    _setPortrait(); // وقتی از بازی خارج می‌شویم، دوباره عمودی شود
    super.dispose();
  }

  void _onBoard(dynamic data) {
    setState(() {
      _words
        ..clear()
        ..addAll(List<String>.from(data['words']));
      _cardColors
        ..clear()
        ..addAll(List<String>.from(data['colors']));
      _cardArt
        ..clear()
        ..addAll(List<String>.from(data['art']));
      _revealed
        ..clear()
        ..addAll(List.filled(25, false));
      _currentTeam = 'red';
      _clue = null;
      _clueNumber = 1;
      _guessesUsed = 0;
      _winner = null;
      _assassinHit = false;
      _spymasterView = widget.role == 'spymaster';
      _ready = true;
    });
  }

  void _onState(dynamic data) {
    int? newIdx;
    setState(() {
      final newRevealed = List<bool>.from(data['revealed']);
      for (int i = 0; i < 25; i++) {
        if (newRevealed[i] && !_revealed[i]) {
          newIdx = i;
          sounds.playFlip();
        }
      }
      _revealed
        ..clear()
        ..addAll(newRevealed);
      _currentTeam = data['team'];
      _clue = data['clue'];
      _clueNumber = data['number'];
      final newWinner = data['winner'];
      if (newWinner != null && _winner == null) {
        if (data['assassin'] == true) {
          sounds.playLose();
          _pendingWinner = newWinner;
        } else {
          sounds.playWin();
          _setWinner(newWinner);
          _shakeController.forward(from: 0);
        }
      }
      _assassinHit = data['assassin'];
      _turnStart = data['turnStart'] ?? _turnStart;
      _clueStart = data['clueStart'] ?? _clueStart;
    });
    if (newIdx != null) _showZoom(newIdx!);
  }

  void _sync() {
    widget.socket!.emit('state', {
      'revealed': _revealed,
      'team': _currentTeam,
      'clue': _clue,
      'number': _clueNumber,
      'winner': _winner,
      'assassin': _assassinHit,
      'turnStart': _turnStart,
      'clueStart': _clueStart,
    });
  }

  void _emitBoard() {
    widget.socket!.emit('board', {
      'words': _words,
      'colors': _cardColors,
      'art': _cardArt,
    });
  }

  int get _needWins => (_maxHands ~/ 2) + 1;

  void _setWinner(String w) {
    _winner = w;
    if (w == 'red') {
      _redWins++;
    } else {
      _blueWins++;
    }
    if (_redWins >= _needWins || _blueWins >= _needWins) {
      _matchWinner = _redWins > _blueWins ? 'red' : 'blue';
    }
  }

  void _nextHand() {
    _hand++;
    _winner = null;
    _startNewGame();
  }

  void _resetMatch() {
    _redWins = 0;
    _blueWins = 0;
    _hand = 1;
    _matchWinner = null;
    _winner = null;
    _startNewGame();
  }

  void _startNewGame() {
    final random = Random();

    final shuffledWords = List<String>.from(persianWords)..shuffle(random);
    _words
      ..clear()
      ..addAll(shuffledWords.take(25));

    // تعداد کارت قرمز و آبی به صورت رندوم (۸ یا ۹)
    final redCount = random.nextBool() ? 9 : 8;
    final blueCount = redCount == 9 ? 8 : 9;

    final colors = <String>[
      for (int i = 0; i < redCount; i++) 'red',
      for (int i = 0; i < blueCount; i++) 'blue',
      for (int i = 0; i < 7; i++) 'neutral',
      'assassin',
    ]..shuffle(random);

    // تیمی که ۹ کارت دارد، بازی را شروع می‌کند
    _currentTeam = redCount == 9 ? 'red' : 'blue';

    _cardColors
      ..clear()
      ..addAll(colors);

    _cardArt
      ..clear()
      ..addAll([
        for (int i = 0; i < 25; i++) _randomArt(_cardColors[i], random),
      ]);

    _cardRotations
      ..clear()
      ..addAll(List.generate(25, (i) {
        // ۸۰٪ کارت‌ها صاف، ۲۰٪ کارت‌ها کج
        if (random.nextDouble() < 0.8) {
          return 0.0; // صاف
        } else {
          return (random.nextDouble() - 0.5) *
              0.2; // کج: بین -0.1 تا 0.1 رادیان
        }
      }));

    _revealed
      ..clear()
      ..addAll(List.filled(25, false));

    _clue = null;
    _clueNumber = 1;
    _guessesUsed = 0;
    _winner = null;
    _assassinHit = false;
    _clueController.clear();
    _turnStart = DateTime.now().millisecondsSinceEpoch;
    _clueStart = _turnStart;

    if (widget.online && widget.isHost) {
      _emitBoard();
      _sync();
    }
  }

  String _randomArt(String color, Random random) {
    switch (color) {
      case 'red':
        return 'assets/images/red_${1 + random.nextInt(3)}.png';
      case 'blue':
        return 'assets/images/blue_${1 + random.nextInt(3)}.png';
      case 'neutral':
        return 'assets/images/by_${1 + random.nextInt(2)}.png';
      default:
        return 'assets/images/assassin.png';
    }
  }

  Color _stripFor(String colorCode) {
    switch (colorCode) {
      case 'red':
        return const Color(0xFFB71C1C);
      case 'blue':
        return const Color(0xFF1565C0);
      case 'neutral':
        return const Color(0xFF8A7A55);
      default:
        return Colors.black;
    }
  }

  void _showZoom(int index) {
    setState(() {
      _zoomImg = _cardArt[index];
      _zoomWord = _words[index];
      _zoomStrip = _stripFor(_cardColors[index]);
    });
  }

  String _teamName(String team) => team == 'red' ? 'قرمز' : 'آبی';

  int _remaining(String color) {
    int count = 0;
    for (int i = 0; i < _cardColors.length; i++) {
      if (_cardColors[i] == color && !_revealed[i]) count++;
    }
    return count;
  }

  void _updateTimer() {
    if (!widget.online || _winner != null || !_ready) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final int duration =
        _clue == null ? 90 : 30 * (_clueNumber < 1 ? 1 : _clueNumber);
    final start = _clue == null ? _turnStart : _clueStart;
    final remaining = duration - (now - start) ~/ 1000;
    if (remaining != _remainingSec) {
      setState(() => _remainingSec = remaining);
    }
    if (remaining <= 0) {
      final acting = (_clue == null && widget.role == 'spymaster' ||
              _clue != null && widget.role == 'guesser') &&
          widget.myTeam == _currentTeam;
      if (acting) _endTurn();
    }
  }

  bool _showClueUI() {
    if (widget.online) {
      return widget.role == 'spymaster' &&
          _currentTeam == widget.myTeam &&
          _winner == null;
    }
    return false;
  }

  void _trySubmitClue() {
    final w = _clueController.text.trim();
    if (w.isEmpty) return;
    if (w.length < 2) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('سرنخ حداقل ۲ کاراکتر!')));
      return;
    }
    if (w.length > 15) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('سرنخ حداکثر ۱۵ کاراکتر!')));
      return;
    }
    if (' '.allMatches(w).length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حداکثر یک فاصله مجاز است!')),
      );
      return;
    }
    if (RegExp(r'[a-zA-Z]').hasMatch(w)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('کلمه انگلیسی ممنوع!')));
      return;
    }
    if (RegExp(r'[0-9۰-۹]').hasMatch(w)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('عدد در سرنخ ممنوع!')));
      return;
    }
    if (_words.contains(w)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('این کلمه روی میز است!')));
      return;
    }
    setState(() {
      _clue = w;
      _clueNumber = _selectedNumber;
      _guessesUsed = 0;
      if (!widget.online) _spymasterView = false;
      _clueController.clear();
      _clueStart = DateTime.now().millisecondsSinceEpoch;
    });
    if (widget.online) _sync();
  }

  void _endTurn() {
    final oldTeam = _currentTeam;
    setState(() {
      _currentTeam = _currentTeam == 'red' ? 'blue' : 'red';
      _clue = null;
      _clueNumber = 1;
      _guessesUsed = 0;
      _turnStart = DateTime.now().millisecondsSinceEpoch;
    });
    if (widget.online) _sync();

    // نمایش پیام "نوبت عوض شد" و تپش دکمه
    _showTurnChangeMessage = true;
    _pulseController.repeat(reverse: true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showTurnChangeMessage = false;
        });
        _pulseController.stop();
        _pulseController.reset();
      }
    });
  }

  void _tapCard(int index) {
    if (_winner != null || _revealed[index]) return;
    if (widget.online && widget.role != 'guesser') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فقط حدس‌زننده تیم جاری می‌تونه کارت بزنه!'),
        ),
      );
      return;
    }
    if (widget.online && widget.myTeam != _currentTeam) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('نوبت تیم شما نیست!')));
      return;
    }
    if (widget.online && _clue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اول سرنخ‌ده باید سرنخ بدهد!')),
      );
      return;
    }

    setState(() => _revealed[index] = true);
    _showZoom(index);
    final color = _cardColors[index];

    if (color == 'assassin') {
      sounds.playLose();
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0);
      setState(() {
        _assassinHit = true;
        _pendingWinner = _currentTeam == 'red' ? 'blue' : 'red';
      });
      if (widget.online) _sync();
      return;
    }

    if (color == _currentTeam) {
      sounds.playCorrect();
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0);

      // چک کردن برنده شدن بلافاصله بعد از زدن کارت درست
      if (_remaining(_currentTeam) == 0) {
        sounds.playWin();
        setState(() => _setWinner(_currentTeam));
        if (widget.online) _sync();
        return;
      }

      if (widget.online) {
        _guessesUsed++;
        if (_guessesUsed >= _clueNumber) {
          setState(() {
            _currentTeam = _currentTeam == 'red' ? 'blue' : 'red';
            _clue = null;
            _clueNumber = 1;
            _guessesUsed = 0;
            _turnStart = DateTime.now().millisecondsSinceEpoch;
          });
        }
      }
    } else if (color == 'neutral') {
      sounds.playWrong();
    } else {
      sounds.playWrong();
      HapticFeedback.mediumImpact();
      setState(() {
        _currentTeam = _currentTeam == 'red' ? 'blue' : 'red';
        _clue = null;
        _clueNumber = 1;
        _guessesUsed = 0;
        _turnStart = DateTime.now().millisecondsSinceEpoch;
      });
    }

    if (widget.online) _sync();
  }

  Widget _hiddenCard(String word, String colorCode) {
    final spyColor = colorCode == 'red'
        ? Colors.red
        : colorCode == 'blue'
            ? Colors.blue
            : colorCode == 'assassin'
                ? Colors.black
                : const Color(0xFFD9C69A);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8D8B8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _spymasterView ? spyColor : const Color(0xFFB9A77F),
          width: _spymasterView ? 3 : 2,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(Icons.person, size: 26, color: const Color(0xFFCDBA96)),
          ),
          Positioned(
            left: 5,
            right: 5,
            top: 4,
            child: Transform.rotate(
              angle: 3.14159,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    word,
                    style: const TextStyle(
                      color: Color(0xFF4A4A4A),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 5,
            right: 5,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  word,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          if (_spymasterView)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: spyColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _revealedCard(String word, String colorCode, String img) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _stripFor(colorCode), width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(img, fit: BoxFit.cover),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: _stripFor(colorCode),
                padding: const EdgeInsets.symmetric(vertical: 4),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    word,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreChip(Color color, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _resultChip(Color color, int count) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _turnBanner() {
    final color = _currentTeam == 'red' ? Colors.red : Colors.blue;
    String text;
    if (!widget.online) {
      text =
          'نوبت تیم ${_teamName(_currentTeam)} | سرنخ رو بلند بگید، بعد کارت بزنید';
    } else if (_clue == null) {
      text = 'نوبت تیم ${_teamName(_currentTeam)} | سرنخ‌ده سرنخ بده';
    } else {
      text = 'سرنخ: «$_clue» $_clueNumber | حدس بزنید!';
    }
    if (widget.online && _currentTeam == widget.myTeam && _winner == null) {
      text += ' (نوبت شما)';
    }
    if (widget.online && _winner == null) {
      text += ' | ⏱ $_remainingSec';
    }
    return Container(
      width: double.infinity,
      color: color,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _clueForm() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _clueController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'کلمه سرنخ...',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        DropdownButton<int>(
          value: _selectedNumber,
          dropdownColor: const Color(0xFF2D1B4E),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          items: [
            for (int i = 0; i <= 9; i++)
              DropdownMenuItem(value: i, child: Text('$i')),
          ],
          onChanged: (v) => setState(() => _selectedNumber = v ?? 1),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _trySubmitClue,
          child: const Text('ثبت سرنخ'),
        ),
      ],
    );
  }

  Widget _playBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'دست $_hand از $_maxHands | برد قرمز $_redWins : $_blueWins آبی | ',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const Text('قرمز: ', style: TextStyle(color: Colors.white)),
        _scoreChip(Colors.red, _remaining('red')),
        const SizedBox(width: 20),
        const Text('آبی: ', style: TextStyle(color: Colors.white)),
        _scoreChip(Colors.blue, _remaining('blue')),
        const SizedBox(width: 20),
        if ((widget.online ? _clue != null : true) && _winner == null)
          TextButton(
            onPressed: _endTurn,
            child: const Text(
              '🔚 پایان نوبت',
              style: TextStyle(color: Colors.white70),
            ),
          ),
      ],
    );
  }

  Widget _winnerOverlay() {
    final isFinal = _matchWinner != null;
    final shownWinner = isFinal ? _matchWinner! : _winner!;
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isFinal ? '🏆' : (_assassinHit ? '💀' : '🎉'),
              style: const TextStyle(fontSize: 70),
            ),
            const SizedBox(height: 16),
            Text(
              isFinal
                  ? 'تیم ${_teamName(shownWinner)} برندهٔ بازی شد!'
                  : 'تیم ${_teamName(shownWinner)} برندهٔ دست $_hand شد!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_assassinHit && !isFinal)
              const Text(
                'آدم‌کش رو شد!',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            const SizedBox(height: 16),
            Text(
              'نتیجه: قرمز $_redWins — $_blueWins آبی (از $_maxHands دست)',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 30),
            if (!widget.online || widget.isHost)
              ElevatedButton(
                onPressed: () => setState(() {
                  if (isFinal) {
                    _resetMatch();
                  } else {
                    _nextHand();
                  }
                }),
                child: Text(isFinal ? '🔄 بازی دوباره از اول' : '▶️ دست بعد'),
              )
            else
              const Text(
                'منتظر شروع دست بعد توسط میزبان...',
                style: TextStyle(color: Colors.white70),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1E1E2E),
        body: Stack(
          children: [
            Transform.translate(
              offset: Offset(_shakeDx, 0),
              child: Row(
                // تغییر از Column به Row برای چیدمان ۸۰/۲۰
                children: [
                  // ۸۰٪ سمت راست: گرید کارت‌ها (در RTL اولین فرزند سمت راست است)
                  Expanded(
                    flex: 8,
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: _ready
                          ? GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(4),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 5,
                                mainAxisSpacing: 6,
                                crossAxisSpacing: 6,
                                childAspectRatio:
                                    1.8, // فیت شدن کامل ۵ ردیف در لنداسکیپ
                              ),
                              itemCount: 25,
                              itemBuilder: (context, index) {
                                return Transform.rotate(
                                  angle:
                                      _cardRotations[index], // اعمال چرخش طبیعی
                                  child: FlipCard(
                                    revealed: _revealed[index],
                                    onTap: () => _tapCard(index),
                                    front: _hiddenCard(
                                      _words[index],
                                      _cardColors[index],
                                    ),
                                    back: _revealedCard(
                                      _words[index],
                                      _cardColors[index],
                                      _cardArt[index],
                                    ),
                                  ),
                                );
                              },
                            )
                          : const _WaitingView(),
                    ),
                  ),
                  // ۲۰٪ سمت چپ: پنل کنترل
                  Expanded(
                    flex: 2,
                    child: Container(
                      color: const Color(0xFF252538),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          // دکمه‌های کنترل: خروج کنار چشم و صدا
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.exit_to_app,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                                onPressed: () {
                                  if (widget.online)
                                    widget.socket!.emit('leave');
                                  Navigator.pop(context);
                                },
                              ),
                              if (!widget.online)
                                IconButton(
                                  icon: Icon(
                                    _spymasterView
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.white70,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                    () => _spymasterView = !_spymasterView,
                                  ),
                                ),
                              IconButton(
                                icon: Icon(
                                  sounds.isMuted
                                      ? Icons.volume_off
                                      : Icons.volume_up,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                                onPressed: () {
                                  sounds.toggleMute();
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                          if (widget.online)
                            Text(
                              'اتاق ${widget.roomCode ?? ''} | تیم ${_teamName(widget.myTeam)}',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                              ),
                            ),

                          const SizedBox(height: 8),
                          // بنر نوبت با ضربان
                          ScaleTransition(
                            scale: _turnBannerPulseAnimation,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _currentTeam == 'red'
                                      ? [Colors.red, Colors.red.shade700]
                                      : [Colors.blue, Colors.blue.shade700],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_currentTeam == 'red'
                                            ? Colors.red
                                            : Colors.blue)
                                        .withOpacity(0.5),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Text(
                                _clue == null
                                    ? 'نوبت: ${_teamName(_currentTeam)}'
                                    : 'سرنخ: $_clue ($_clueNumber)',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  shadows: [
                                    Shadow(
                                        color: Colors.black45,
                                        blurRadius: 4,
                                        offset: Offset(0, 2)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // نمایش شماره دست
                          Text(
                            'دست $_hand',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // نمایش نتیجه با بیضی‌های رنگی
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _resultChip(Colors.red, _redWins),
                              const Text(
                                '-',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 16),
                              ),
                              _resultChip(Colors.blue, _blueWins),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // تعداد کارت‌های باقی‌مانده (کوچک‌تر)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text(
                                '${_remaining('red')} کارت',
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 10),
                              ),
                              Text(
                                '${_remaining('blue')} کارت',
                                style: const TextStyle(
                                    color: Colors.blue, fontSize: 10),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // فرم سرنخ یا دکمه پایان نوبت
                          if (_showClueUI()) ...[
                            TextField(
                              controller: _clueController,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText: 'سرنخ...',
                                hintStyle: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                                filled: true,
                                fillColor: Colors.white10,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButton<int>(
                              value: _selectedNumber,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF2D1B4E),
                              style: const TextStyle(color: Colors.white),
                              items: [
                                for (int i = 0; i <= 9; i++)
                                  DropdownMenuItem(
                                    value: i,
                                    child: Text(
                                      '$i',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                              ],
                              onChanged: (v) =>
                                  setState(() => _selectedNumber = v ?? 1),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _trySubmitClue,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                ),
                                child: const Text(
                                  'ثبت',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ] else if (_winner == null) ...[
                            // پیام "نوبت عوض شد" که محو می‌شود
                            if (_showTurnChangeMessage)
                              Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  '✓ نوبت عوض شد',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            // دکمه پایان نوبت با تپش
                            ScaleTransition(
                              scale: _showTurnChangeMessage
                                  ? _pulseAnimation
                                  : const AlwaysStoppedAnimation(1.0),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _endTurn,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    elevation: _showTurnChangeMessage ? 8 : 2,
                                  ),
                                  child: const Text(
                                    '🔚 پایان نوبت',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          if (widget.online && _winner == null)
                            Text(
                              '⏱ $_remainingSec',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_reconnecting)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: const Center(
                    child: Text(
                      '📡 اتصال قطع شد؛ در حال بازگشت...',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            if (_zoomImg != null)
              _ZoomOverlay(
                img: _zoomImg!,
                word: _zoomWord,
                strip: _zoomStrip,
                onDone: () {
                  setState(() {
                    _zoomImg = null;
                    if (_pendingWinner != null) {
                      _setWinner(_pendingWinner!);
                      _pendingWinner = null;
                      _shakeController.forward(from: 0);
                    }
                  });
                },
              ),
            if (_winner != null) _winnerOverlay(),
            if (_opponentLeft)
              Container(
                color: Colors.black87,
                child: const Center(
                  child: Text(
                    '😔 حریف از اتاق خارج شد',
                    style: TextStyle(color: Colors.white, fontSize: 22),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
