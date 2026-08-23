import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'words.dart';

void main() {
  runApp(const CodenamesApp());
}

// ---------------- مدیریت صدا ----------------
class SoundManager {
  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _music = AudioPlayer();

  void _play(String file) {
    try {
      _player.play(AssetSource('audio/$file')).catchError((_) {});
    } catch (_) {}
  }

  void playFlip() => _play('flip.mp3');
  void playCorrect() => _play('correct.mp3');
  void playWrong() => _play('wrong.mp3');
  void playWin() => _play('win.mp3');
  void playLose() => _play('lose.mp3');

  void startTheme() {
    try {
      _music.setReleaseMode(ReleaseMode.loop);
      _music.setVolume(0.35);
      _music.play(AssetSource('audio/theme.mp3')).catchError((_) {});
    } catch (_) {}
  }
}

final SoundManager sounds = SoundManager();

IO.Socket createSocket() {
  return IO.io(
    'http://localhost:3000',
    IO.OptionBuilder().setTransports(['websocket']).enableForceNew().build(),
  );
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
class MainMenu extends StatelessWidget {
  const MainMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/menu_bg.png'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'اسم رمز',
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'بازی حدس کلمات',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 40),
                _buildButton('🌐 بازی آنلاین', Colors.blue, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OnlineLobby()),
                  );
                }),
                const SizedBox(height: 12),
                _buildButton('📚 آموزش', Colors.orange, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TutorialPage()),
                  );
                }),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String text, Color color, VoidCallback? onTap) {
    return SizedBox(
      width: 280,
      height: 54,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 6,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

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
                color: Color(0xFF2F6FD0), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text('$n',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(children: spans),
              style: const TextStyle(
                  color: Colors.white, fontSize: 14, height: 1.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardSample(
      String img, Color border, Color titleColor, String title, String desc) {
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
                    color: Colors.black54, blurRadius: 6, offset: Offset(0, 3)),
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
                color: titleColor, fontWeight: FontWeight.bold, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(
                color: Colors.white70, fontSize: 11, height: 1.7),
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
          title: const Text('آموزش اسم رمز',
              style: TextStyle(color: Colors.white)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _sectionTitle('🕵️ اسم رمز چیست؟'),
              _box([
                const Text(
                  'دو تیم قرمز و آبی؛ هر تیم یک سرنخ‌ده و یک حدس‌زننده دارد. هدف این است که با کمک سرنخ‌ده، همه کلمات تیم خود را قبل از حریف پیدا کنید!',
                  style:
                      TextStyle(color: Colors.white, fontSize: 15, height: 1.9),
                  textAlign: TextAlign.center,
                ),
              ]),
              const SizedBox(height: 24),
              _sectionTitle('📜 قوانین بازی'),
              _box([
                _rule(1, [
                  const TextSpan(
                      text:
                          'سرنخ‌ده، رنگ کارت‌ها را می‌بیند و یک کلمه + یک عدد می‌دهد (حداکثر ۱۵ کاراکتر با احتساب فاصله، بدون عدد، انگلیسی و کلمه روی میز).'),
                ]),
                _rule(2, [
                  const TextSpan(
                      text:
                          'سرنخ‌ده ۹۰ ثانیه وقت دارد؛ حدس‌زننده ۳۰ ثانیه به ازای هر عدد گفته‌شده (سرنخ ۲ = ۶۰ ثانیه). دیر بجنبی، نوبت می‌سوزه!'),
                ]),
                _rule(3, [
                  const TextSpan(text: 'کارت تیم خودت = '),
                  const TextSpan(
                      text: 'ادامه',
                      style: TextStyle(
                          color: Color(0xFF66BB6A),
                          fontWeight: FontWeight.bold)),
                  const TextSpan(text: '، کارت خنثی = '),
                  const TextSpan(
                      text: 'ادامه',
                      style: TextStyle(
                          color: Color(0xFF66BB6A),
                          fontWeight: FontWeight.bold)),
                  const TextSpan(text: '، کارت حریف = '),
                  const TextSpan(
                      text: 'سوختن نوبت',
                      style: TextStyle(
                          color: Color(0xFFFFB74D),
                          fontWeight: FontWeight.bold)),
                  const TextSpan(text: '، آدمکش = '),
                  const TextSpan(
                      text: 'باخت فوری!',
                      style: TextStyle(
                          color: Color(0xFFEF5350),
                          fontWeight: FontWeight.bold)),
                ]),
                _rule(4, [
                  const TextSpan(text: 'نوبت اول با تیمی است که ۹ کارت دارد.'),
                ]),
                _rule(5, [
                  const TextSpan(
                      text:
                          'حدس‌زننده فقط به تعداد عدد سرنخ می‌تواند درست حدس بزند.'),
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
                    _cardSample('assets/images/red_1.png', red, red,
                        'کارت تیم قرمز', 'کارت‌های تیم قرمز را پیدا کنید.'),
                    _cardSample('assets/images/blue_1.png', blue, blue,
                        'کارت تیم آبی', 'کارت‌های تیم آبی را پیدا کنید.'),
                    _cardSample('assets/images/by_1.png', tan, Colors.white70,
                        'کارت خنثی', 'بی‌خطر است، می‌توانید ادامه دهید.'),
                    _cardSample(
                        'assets/images/blue_2.png',
                        blue,
                        Colors.white70,
                        'کارت حریف',
                        'حدس اشتباه، نوبت شما تمام می‌شود.'),
                    _cardSample(
                        'assets/images/assassin.png',
                        black,
                        const Color(0xFFEF5350),
                        'آدمکش',
                        'اگر این کارت را بزنید، تیم شما فوراً می‌بازد!'),
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
        (_) => setState(() => _status = '❌ خطا در اتصال! سرور روشنه؟'));
    _socket.on('players', (list) {
      setState(() {
        _players =
            (list as List).map((e) => Map<String, dynamic>.from(e)).toList();
      });
    });
    _socket.on('setup', (data) {
      _applySetup((data['assignments'] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList());
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

  void _createRoom() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _status = 'اول اسمت رو بنویس!');
      return;
    }
    _socket.emitWithAck('create_room', {'name': name}, ack: (res) {
      setState(() {
        _roomCode = res['code'];
        _isHost = true;
      });
    });
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
    _socket.emit('setup', {'assignments': assignments});
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
        ),
      ),
    );
  }

  Widget _chip(String id, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(_nameOf(id),
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _draggableChip(String id) {
    return Draggable<String>(
      data: id,
      feedback:
          Material(color: Colors.transparent, child: _chip(id, Colors.amber)),
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
          title:
              const Text('بازی آنلاین', style: TextStyle(color: Colors.white)),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_status,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 15)),
                const SizedBox(height: 20),
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
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _createRoom,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 16)),
                    child: const Text('🛠️ ساخت اتاق جدید',
                        style: TextStyle(fontSize: 17, color: Colors.white)),
                  ),
                  const SizedBox(height: 20),
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
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _joinRoom,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green),
                        child: const Text('ورود',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 10),
                    decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(_roomCode!,
                        style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 6)),
                  ),
                  const SizedBox(height: 16),
                  Text('بازیکن‌ها (${_players.length}/4):',
                      style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _players
                        .map((p) => _chip(p['id'], Colors.grey))
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  if (_isHost && _players.length == 4) ...[
                    const Text('بازیکن‌ها رو بکش و رها کن:',
                        style: TextStyle(color: Colors.white)),
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
                        Column(children: [
                          const Text('تیم ۱',
                              style: TextStyle(color: Colors.orange)),
                          _slot('t1s', 'سرنخ‌ده', Colors.orange),
                          _slot('t1g', 'حدس‌زننده', Colors.orange),
                        ]),
                        const SizedBox(width: 20),
                        Column(children: [
                          const Text('تیم ۲',
                              style: TextStyle(color: Colors.teal)),
                          _slot('t2s', 'سرنخ‌ده', Colors.teal),
                          _slot('t2g', 'حدس‌زننده', Colors.teal),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: allAssigned ? _start : null,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 14)),
                      child: const Text('🚀 شروع بازی',
                          style: TextStyle(color: Colors.white, fontSize: 17)),
                    ),
                  ] else if (_isHost)
                    const Text('منتظر بازیکن‌های بیشتر...',
                        style: TextStyle(color: Colors.white70))
                  else
                    const Text('منتظر تنظیم تیم‌ها توسط میزبان...',
                        style: TextStyle(color: Colors.white70)),
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

  const GameBoard({
    super.key,
    this.online = false,
    this.myTeam = 'red',
    this.role = 'guesser',
    this.isHost = false,
    this.socket,
    this.roomCode,
  });

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> with TickerProviderStateMixin {
  final List<String> _words = [];
  final List<String> _cardColors = [];
  final List<bool> _revealed = [];
  final List<String> _cardArt = [];
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
  int _turnStart = 0;
  int _clueStart = 0;
  int _remainingSec = 90;
  Timer? _tickTimer;

  late AnimationController _shakeController;
  double _shakeDx = 0;

  @override
  void initState() {
    super.initState();
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

    if (widget.online) {
      _ready = false;
      _spymasterView = widget.role == 'spymaster';
      _tickTimer = Timer.periodic(
          const Duration(milliseconds: 250), (_) => _updateTimer());
      widget.socket!.on('board', _onBoard);
      widget.socket!.on('state', _onState);
      widget.socket!.on('player_left', (_) {
        setState(() => _opponentLeft = true);
      });
      _lastSocketId = widget.socket!.id;
      widget.socket!.on('connect', (_) {
        final newId = widget.socket!.id;
        if (_lastSocketId != null && newId != _lastSocketId) {
          widget.socket!.emit(
              'rejoin', {'room': widget.roomCode, 'oldId': _lastSocketId});
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
    _clueController.dispose();
    if (widget.online) widget.socket!.disconnect();
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
          _winner = newWinner;
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

  void _startNewGame() {
    final random = Random();

    final shuffledWords = List<String>.from(persianWords)..shuffle(random);
    _words
      ..clear()
      ..addAll(shuffledWords.take(25));

    final colors = <String>[
      for (int i = 0; i < 9; i++) 'red',
      for (int i = 0; i < 8; i++) 'blue',
      for (int i = 0; i < 7; i++) 'neutral',
      'assassin',
    ]..shuffle(random);

    _cardColors
      ..clear()
      ..addAll(colors);

    _cardArt
      ..clear()
      ..addAll(
          [for (int i = 0; i < 25; i++) _randomArt(_cardColors[i], random)]);

    _revealed
      ..clear()
      ..addAll(List.filled(25, false));

    _currentTeam = 'red';
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
    return _spymasterView;
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
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('سرنخ حداکثر ۱۵ کاراکتر!')));
      return;
    }
    if (' '.allMatches(w).length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حداکثر یک فاصله مجاز است!')));
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
    setState(() {
      _currentTeam = _currentTeam == 'red' ? 'blue' : 'red';
      _clue = null;
      _clueNumber = 1;
      _guessesUsed = 0;
      _turnStart = DateTime.now().millisecondsSinceEpoch;
    });
    if (widget.online) _sync();
  }

  void _tapCard(int index) {
    if (_winner != null || _revealed[index]) return;
    if (widget.online && widget.role != 'guesser') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('فقط حدس‌زننده تیم جاری می‌تونه کارت بزنه!')));
      return;
    }
    if (widget.online && widget.myTeam != _currentTeam) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('نوبت تیم شما نیست!')));
      return;
    }
    if (_clue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('اول سرنخ‌ده باید سرنخ بدهد!')));
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
      if (_remaining(_currentTeam) == 0) {
        sounds.playWin();
        setState(() => _winner = _currentTeam);
      } else {
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
          Positioned(
            top: 6,
            right: 6,
            child: Icon(Icons.person, size: 26, color: const Color(0xFFCDBA96)),
          ),
          Positioned(
            left: 5,
            right: 5,
            bottom: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
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

  Widget _turnBanner() {
    final color = _currentTeam == 'red' ? Colors.red : Colors.blue;
    String text;
    if (_clue == null) {
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
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        const Text('قرمز: ', style: TextStyle(color: Colors.white)),
        _scoreChip(Colors.red, _remaining('red')),
        const SizedBox(width: 20),
        const Text('آبی: ', style: TextStyle(color: Colors.white)),
        _scoreChip(Colors.blue, _remaining('blue')),
        const SizedBox(width: 20),
        if (_clue != null && _winner == null)
          TextButton(
            onPressed: _endTurn,
            child: const Text(
              'پایان نوبت',
              style: TextStyle(color: Colors.white70),
            ),
          ),
      ],
    );
  }

  Widget _winnerOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_assassinHit ? '💀' : '🏆',
                style: const TextStyle(fontSize: 70)),
            const SizedBox(height: 16),
            Text(
              'تیم ${_teamName(_winner!)} برنده شد!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_assassinHit)
              const Text(
                'آدم‌کش رو شد!',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            const SizedBox(height: 30),
            if (!widget.online || widget.isHost)
              ElevatedButton(
                onPressed: () => setState(() => _startNewGame()),
                child: const Text('بازی دوباره'),
              )
            else
              const Text(
                'منتظر شروع دوباره توسط میزبان...',
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
        appBar: AppBar(
          backgroundColor: const Color(0xFF2D1B4E),
          leading: IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: () {
              if (widget.online) widget.socket!.emit('leave');
              Navigator.pop(context);
            },
          ),
          title: Text(
            widget.online
                ? 'اتاق ${widget.roomCode ?? ''} | تیم ${_teamName(widget.myTeam)}'
                : 'صفحه بازی',
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            if (!widget.online)
              IconButton(
                icon: Icon(
                  _spymasterView ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white,
                ),
                onPressed: () =>
                    setState(() => _spymasterView = !_spymasterView),
              ),
            if (!widget.online || widget.isHost)
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () => setState(() => _startNewGame()),
              ),
          ],
        ),
        bottomNavigationBar: Container(
          color: const Color(0xFF2D1B4E),
          padding: const EdgeInsets.all(10),
          child: _showClueUI() ? _clueForm() : _playBar(),
        ),
        body: Stack(
          children: [
            Transform.translate(
              offset: Offset(_shakeDx, 0),
              child: Column(
                children: [
                  _turnBanner(),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: _ready
                            ? GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(8),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 5,
                                  mainAxisSpacing: 6,
                                  crossAxisSpacing: 6,
                                  childAspectRatio: 1.3,
                                ),
                                itemCount: 25,
                                itemBuilder: (context, index) {
                                  return FlipCard(
                                    revealed: _revealed[index],
                                    onTap: () => _tapCard(index),
                                    front: _hiddenCard(
                                        _words[index], _cardColors[index]),
                                    back: _revealedCard(_words[index],
                                        _cardColors[index], _cardArt[index]),
                                  );
                                },
                              )
                            : const _WaitingView(),
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
                    child: Text('📡 اتصال قطع شد؛ در حال بازگشت...',
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)),
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
                      _winner = _pendingWinner;
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
