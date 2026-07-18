import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const KararCarkiApp());

/// Pastel renk paleti - dilimler bu renkler arasından seçilir.
const List<Color> pastelColors = [
  Color(0xFFFFADAD),
  Color(0xFFFFD6A5),
  Color(0xFFFDFFB6),
  Color(0xFFCAFFBF),
  Color(0xFF9BF6FF),
  Color(0xFFA0C4FF),
  Color(0xFFBDB2FF),
  Color(0xFFFFC6FF),
  Color(0xFFFFCFD2),
  Color(0xFFB5EAD7),
];

class KararCarkiApp extends StatefulWidget {
  const KararCarkiApp({super.key});

  @override
  State<KararCarkiApp> createState() => _KararCarkiAppState();
}

class _KararCarkiAppState extends State<KararCarkiApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      _themeMode = (_themeMode == ThemeMode.dark) ? ThemeMode.light : ThemeMode.dark;
    });
  }

  bool get _isDark => _themeMode == ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Karar Çarkı',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF6F3FB),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121016),
      ),
      home: HomeShell(onToggleTheme: _toggleTheme, isDark: _isDark),
    );
  }
}

/// Ana iskelet: AppBar + alt menü
class HomeShell extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDark;

  const HomeShell({super.key, required this.onToggleTheme, required this.isDark});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tabIndex = 0;
  static const _titles = ['Karar Çarkı', 'Zar At', 'Yazı Tura', 'Sayı Üret', 'Diğer Araçlar'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_tabIndex]),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Temayı değiştir',
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: const [
          WheelScreen(),
          DiceScreen(),
          CoinFlipScreen(),
          RandomNumberScreen(),
          MoreToolsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.donut_large_outlined), selectedIcon: Icon(Icons.donut_large), label: 'Çark'),
          NavigationDestination(icon: Icon(Icons.casino_outlined), selectedIcon: Icon(Icons.casino), label: 'Zar'),
          NavigationDestination(icon: Icon(Icons.monetization_on_outlined), selectedIcon: Icon(Icons.monetization_on), label: 'Yazı Tura'),
          NavigationDestination(icon: Icon(Icons.pin_outlined), selectedIcon: Icon(Icons.pin), label: 'Sayı'),
          NavigationDestination(icon: Icon(Icons.apps_outlined), selectedIcon: Icon(Icons.apps), label: 'Diğer'),
        ],
      ),
    );
  }
}

// =============================================================
// 1. ÇARK EKRANI
// =============================================================

class WheelScreen extends StatefulWidget {
  const WheelScreen({super.key});

  @override
  State<WheelScreen> createState() => _WheelScreenState();
}

class _WheelScreenState extends State<WheelScreen> with SingleTickerProviderStateMixin {
  final List<String> _options = ['Pizza', 'Sushi', 'Burger', 'Salata'];
  final TextEditingController _textController = TextEditingController();

  late AnimationController _controller;
  late Animation<double> _animation;

  double _currentRotation = 0;
  String? _winner;
  bool _isSpinning = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) _onSpinComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _addOption() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _options.add(text);
      _winner = null;
      _textController.clear();
    });
  }

  void _removeOption(int index) {
    setState(() {
      _options.removeAt(index);
      _winner = null;
    });
  }

  void _spin() {
    if (_options.length < 2 || _isSpinning) return;
    final random = Random();
    final int fullTurns = 5 + random.nextInt(5);
    final double randomStopAngle = random.nextDouble() * 2 * pi;
    final double targetRotation = _currentRotation + (fullTurns * 2 * pi) + randomStopAngle;

    _animation = Tween<double>(begin: _currentRotation, end: targetRotation)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));

    setState(() {
      _isSpinning = true;
      _winner = null;
    });

    _controller.reset();
    _controller.forward();
  }

  void _onSpinComplete() {
    final double finalAngle = _animation.value;
    _currentRotation = finalAngle % (2 * pi);

    final sliceAngle = 2 * pi / _options.length;

    double u = (-_currentRotation) % (2 * pi);
    if (u < 0) u += 2 * pi;

    final index = (u / sliceAngle).floor() % _options.length;

    setState(() {
      _isSpinning = false;
      _winner = _options[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _winner != null
                ? Padding(
                    key: ValueKey(_winner),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Card(
                      elevation: 0,
                      color: scheme.primaryContainer,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        child: Text(
                          'Kazanan: $_winner ',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: scheme.onPrimaryContainer,
                              ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox(height: 8),
          ),
          const SizedBox(height: 12),
          Expanded(
            flex: 5,
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = min(constraints.maxWidth, constraints.maxHeight) * 0.9;
                  return SizedBox(
                    width: size,
                    height: size,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 24,
                                spreadRadius: 2,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            final angle = _isSpinning ? _animation.value : _currentRotation;
                            return Transform.rotate(angle: angle, child: child);
                          },
                          child: CustomPaint(
                            size: Size(size, size),
                            painter: WheelPainter(options: _options),
                          ),
                        ),
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: scheme.surface,
                            border: Border.all(color: scheme.primary, width: 3),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 8),
                            ],
                          ),
                          child: Icon(Icons.casino, color: scheme.primary),
                        ),
                        Positioned(
                          top: -6,
                          child: CustomPaint(
                            size: const Size(36, 40),
                            painter: PointerPainter(color: scheme.primary),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: _options.isEmpty
                ? const Center(child: Text('Henüz seçenek yok'))
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _options.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      return InputChip(
                        label: Text(_options[index]),
                        labelStyle: const TextStyle(color: Colors.black87),
                        backgroundColor: pastelColors[index % pastelColors.length],
                        onDeleted: _isSpinning ? null : () => _removeOption(index),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
          Card(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          enabled: !_isSpinning,
                          decoration: InputDecoration(
                            hintText: 'Yeni seçenek yaz...',
                            filled: true,
                            fillColor: scheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onSubmitted: (_) => _addOption(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonalIcon(
                        onPressed: _isSpinning ? null : _addOption,
                        icon: const Icon(Icons.add),
                        label: const Text('Ekle'),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: (_options.length < 2 || _isSpinning) ? null : _spin,
                      icon: const Icon(Icons.replay_circle_filled),
                      label: Text(
                        _isSpinning ? 'Dönüyor...' : 'Çevir',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WheelPainter extends CustomPainter {
  final List<String> options;
  WheelPainter({required this.options});

  @override
  void paint(Canvas canvas, Size size) {
    if (options.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sliceAngle = 2 * pi / options.length;

    for (int i = 0; i < options.length; i++) {
      final startAngle = i * sliceAngle - pi / 2;
      final paint = Paint()..color = pastelColors[i % pastelColors.length];

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(Rect.fromCircle(center: center, radius: radius), startAngle, sliceAngle, false)
        ..close();
      canvas.drawPath(path, paint);
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      final textAngle = startAngle + sliceAngle / 2;
      final textRadius = radius * 0.62;
      final textOffset = Offset(
        center.dx + textRadius * cos(textAngle),
        center.dy + textRadius * sin(textAngle),
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: options[i],
          style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      );
      textPainter.layout(maxWidth: radius * 0.7);

      canvas.save();
      canvas.translate(textOffset.dx, textOffset.dy);
      canvas.rotate(textAngle + pi / 2);
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    }

    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  @override
  bool shouldRepaint(covariant WheelPainter oldDelegate) => oldDelegate.options != options;
}

class PointerPainter extends CustomPainter {
  final Color color;
  PointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawShadow(path, Colors.black, 4, true);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant PointerPainter oldDelegate) => false;
}

// =============================================================
// 2. ZAR EKRANI
// =============================================================

class DiceScreen extends StatefulWidget {
  const DiceScreen({super.key});

  @override
  State<DiceScreen> createState() => _DiceScreenState();
}

class _DiceScreenState extends State<DiceScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotX;
  late Animation<double> _rotY;
  late Animation<double> _rotZ;
  late Animation<double> _bounce;

  int _value = 1;
  int _displayValue = 1;
  bool _isRolling = false;
  int _lastBucket = -1;
  final Random _random = Random();

  static const int _rollBuckets = 9;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));

    _controller.addListener(() {
      if (!_isRolling) return;
      final bucket = (_controller.value * _rollBuckets).floor();
      if (bucket != _lastBucket) {
        _lastBucket = bucket;
        setState(() {
          _displayValue = (bucket >= _rollBuckets - 1) ? _value : 1 + _random.nextInt(6);
        });
      }
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isRolling = false;
          _displayValue = _value;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _roll() {
    if (_isRolling) return;
    final newValue = 1 + _random.nextInt(6);
    _lastBucket = -1;

    final turnsX = 3 + _random.nextInt(2);
    final turnsY = 2 + _random.nextInt(2);

    _rotX = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: turnsX * 2 * pi + 0.35).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 85,
      ),
      TweenSequenceItem(
        tween: Tween(begin: turnsX * 2 * pi + 0.35, end: turnsX * 2 * pi).chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
    ]).animate(_controller);

    _rotY = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: turnsY * 2 * pi - 0.3).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 85,
      ),
      TweenSequenceItem(
        tween: Tween(begin: turnsY * 2 * pi - 0.3, end: turnsY * 2 * pi).chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
    ]).animate(_controller);

    _rotZ = Tween<double>(begin: 0, end: (_random.nextBool() ? 1 : -1) * 0.12).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.7, 1.0, curve: Curves.elasticOut)),
    );

    _bounce = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.92).chain(CurveTween(curve: Curves.easeIn)), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.05).chain(CurveTween(curve: Curves.easeOut)), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 20),
    ]).animate(_controller);

    setState(() {
      _isRolling = true;
      _value = newValue;
      _displayValue = 1 + _random.nextInt(6);
    });

    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Column(
        children: [
          const Spacer(),
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final rx = _isRolling ? _rotX.value : 0.0;
                final ry = _isRolling ? _rotY.value : 0.0;
                final rz = _isRolling ? _rotZ.value : 0.0;
                final scale = _isRolling ? _bounce.value : 1.0;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.003)
                    ..rotateX(rx)
                    ..rotateY(ry)
                    ..rotateZ(rz)
                    ..scale(scale),
                  child: child,
                );
              },
              child: DiceFace(value: _displayValue, color: scheme.primary),
            ),
          ),
          const SizedBox(height: 28),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              _isRolling ? 'Zar atılıyor...' : 'Sonuç: $_value',
              key: ValueKey(_isRolling ? 'rolling' : _value),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isRolling ? null : _roll,
                icon: const Icon(Icons.casino),
                label: const Text('Zar At', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DiceFace extends StatelessWidget {
  final int value;
  final Color color;
  static const double _dieSize = 140;

  const DiceFace({super.key, required this.value, required this.color});

  static const Map<int, List<List<int>>> _dots = {
    1: [[1, 1]],
    2: [[0, 0], [2, 2]],
    3: [[0, 0], [1, 1], [2, 2]],
    4: [[0, 0], [0, 2], [2, 0], [2, 2]],
    5: [[0, 0], [0, 2], [1, 1], [2, 0], [2, 2]],
    6: [[0, 0], [0, 2], [1, 0], [1, 2], [2, 0], [2, 2]],
  };

  @override
  Widget build(BuildContext context) {
    final positions = _dots[value] ?? _dots[1]!;
    return Container(
      width: _dieSize,
      height: _dieSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, color.withOpacity(0.35)],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 12)),
          BoxShadow(color: color.withOpacity(0.4), blurRadius: 30, spreadRadius: -6),
        ],
        border: Border.all(color: Colors.white, width: 3),
      ),
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(9, (index) {
          final row = index ~/ 3;
          final col = index % 3;
          final hasDot = positions.any((p) => p[0] == row && p[1] == col);
          return Center(
            child: hasDot
                ? Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 4)],
                    ),
                  )
                : const SizedBox.shrink(),
          );
        }),
      ),
    );
  }
}

// =============================================================
// 3. YAZI TURA EKRANI
// =============================================================

class CoinFlipScreen extends StatefulWidget {
  const CoinFlipScreen({super.key});

  @override
  State<CoinFlipScreen> createState() => _CoinFlipScreenState();
}

class _CoinFlipScreenState extends State<CoinFlipScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _angle;

  bool _isFlipping = false;
  bool _resultIsHeads = true;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isFlipping = false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_isFlipping) return;
    final isHeads = _random.nextBool();

    int halfTurns = 9 + _random.nextInt(6);
    final bool endsHeads = halfTurns % 2 == 0;
    if (endsHeads != isHeads) halfTurns += 1;

    _angle = Tween<double>(begin: 0, end: halfTurns * pi)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    setState(() {
      _isFlipping = true;
      _resultIsHeads = isHeads;
    });

    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const Spacer(),
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final angle = _isFlipping ? _angle.value : (_resultIsHeads ? 0.0 : pi);
                final showHeads = cos(angle) >= 0;
                final scaleX = cos(angle).abs().clamp(0.05, 1.0);
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..scale(scaleX, 1.0),
                  child: CoinFace(isHeads: showHeads),
                );
              },
            ),
          ),
          const SizedBox(height: 28),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              _isFlipping ? 'Havada dönüyor...' : 'Sonuç: ${_resultIsHeads ? 'Yazı' : 'Tura'}',
              key: ValueKey(_isFlipping ? 'flipping' : _resultIsHeads),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isFlipping ? null : _flip,
                icon: const Icon(Icons.monetization_on),
                label: const Text('Parayı At', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CoinFace extends StatelessWidget {
  final bool isHeads;
  static const double _coinSize = 170;

  const CoinFace({super.key, required this.isHeads});

  @override
  Widget build(BuildContext context) {
    final Color base = isHeads ? const Color(0xFFF0CD6B) : const Color(0xFFD7DBE0);
    final Color dark = isHeads ? const Color(0xFFB9862A) : const Color(0xFF8D93A0);

    return Container(
      width: _coinSize,
      height: _coinSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [base, dark],
          center: const Alignment(-0.3, -0.35),
          radius: 0.95,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.85), width: 5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 10)),
          BoxShadow(color: dark.withOpacity(0.4), blurRadius: 24, spreadRadius: -6),
        ],
      ),
      child: Center(
        child: Container(
          width: _coinSize - 34,
          height: _coinSize - 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.55), width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isHeads ? Icons.star_rounded : Icons.shield_moon_rounded,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(height: 4),
              Text(
                isHeads ? '1 ₺' : 'TÜRK LİRASI',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: isHeads ? 26 : 12,
                  letterSpacing: 1,
                ),
              ),
              Text(
                isHeads ? 'YAZI' : 'TURA',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// 4. RANDOM SAYI ÜRETİCİ EKRANI
// =============================================================

class RandomNumberScreen extends StatefulWidget {
  const RandomNumberScreen({super.key});

  @override
  State<RandomNumberScreen> createState() => _RandomNumberScreenState();
}

class _RandomNumberScreenState extends State<RandomNumberScreen> {
  final TextEditingController _minController = TextEditingController(text: '1');
  final TextEditingController _maxController = TextEditingController(text: '100');
  final Random _random = Random();

  int? _result;
  bool _isGenerating = false;

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_isGenerating) return;
    final minVal = int.tryParse(_minController.text.trim());
    final maxVal = int.tryParse(_maxController.text.trim());
    if (minVal == null || maxVal == null) return;

    final lo = min(minVal, maxVal);
    final hi = max(minVal, maxVal);

    setState(() => _isGenerating = true);

    const steps = 14;
    for (int i = 0; i < steps; i++) {
      await Future.delayed(Duration(milliseconds: 35 + i * 6));
      if (!mounted) return;
      setState(() => _result = lo + _random.nextInt(hi - lo + 1));
    }

    if (!mounted) return;
    setState(() {
      _result = lo + _random.nextInt(hi - lo + 1);
      _isGenerating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Spacer(),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 120),
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: Container(
                key: ValueKey(_result),
                width: 220,
                height: 220,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [scheme.primary, scheme.tertiary],
                  ),
                  boxShadow: [
                    BoxShadow(color: scheme.primary.withOpacity(0.4), blurRadius: 30, spreadRadius: 2),
                  ],
                ),
                child: Text(
                  _result?.toString() ?? '?',
                  style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
            ),
            const Spacer(),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minController,
                            keyboardType: TextInputType.number,
                            enabled: !_isGenerating,
                            decoration: InputDecoration(
                              labelText: 'Min',
                              filled: true,
                              fillColor: scheme.surfaceContainerHighest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _maxController,
                            keyboardType: TextInputType.number,
                            enabled: !_isGenerating,
                            decoration: InputDecoration(
                              labelText: 'Max',
                              filled: true,
                              fillColor: scheme.surfaceContainerHighest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isGenerating ? null : _generate,
                        icon: const Icon(Icons.shuffle),
                        label: Text(
                          _isGenerating ? 'Üretiliyor...' : 'Sayı Üret',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// 5. DİĞER ARAÇLAR MENÜSÜ
// =============================================================

class MoreToolsScreen extends StatelessWidget {
  const MoreToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tools = <_ToolItem>[
      _ToolItem(
        'Renk Seçici',
        'Rastgele renk üretir',
        Icons.palette,
        const Color(0xFFFFADAD),
        (ctx) => const ColorPickerScreen(),
      ),
      _ToolItem(
        'Harf Seçici',
        'A-Z arası rastgele harf',
        Icons.abc,
        const Color(0xFFCAFFBF),
        (ctx) => const LetterPickerScreen(),
      ),
      _ToolItem(
        'Slot Makinesi',
        '3 makaralı eğlence',
        Icons.casino,
        const Color(0xFFA0C4FF),
        (ctx) => const SlotMachineScreen(),
      ),
      _ToolItem(
        'Şişe Çevirme',
        'Parti oyunları için',
        Icons.sports_bar,
        const Color(0xFFFFD6A5),
        (ctx) => const BottleSpinScreen(),
      ),
      _ToolItem(
        'Taş Kağıt Makas',
        'Klasik el oyunu',
        Icons.gesture,
        const Color(0xFFFFC6FF),
        (ctx) => const RockPaperScissorsScreen(),
      ),
    ];

    return SafeArea(
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.95,
        ),
        itemCount: tools.length,
        itemBuilder: (context, index) => _ToolCard(tool: tools[index]),
      ),
    );
  }
}

class _ToolItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;
  _ToolItem(this.title, this.subtitle, this.icon, this.color, this.builder);
}

class _ToolCard extends StatelessWidget {
  final _ToolItem tool;
  const _ToolCard({required this.tool});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: tool.builder)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(shape: BoxShape.circle, color: tool.color.withOpacity(0.6)),
                child: Icon(tool.icon, size: 32, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              Text(
                tool.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                tool.subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// 6. RENK SEÇİCİ EKRANI
// =============================================================

class ColorPickerScreen extends StatefulWidget {
  const ColorPickerScreen({super.key});

  @override
  State<ColorPickerScreen> createState() => _ColorPickerScreenState();
}

class _ColorPickerScreenState extends State<ColorPickerScreen> {
  final Random _random = Random();
  Color _color = pastelColors[0];
  bool _isGenerating = false;

  String get _hex => '#${_color.value.toRadixString(16).substring(2).toUpperCase()}';

  Color _randomColor() =>
      Color.fromARGB(255, _random.nextInt(256), _random.nextInt(256), _random.nextInt(256));

  Future<void> _generate() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);
    const steps = 10;
    for (int i = 0; i < steps; i++) {
      await Future.delayed(Duration(milliseconds: 30 + i * 8));
      if (!mounted) return;
      setState(() => _color = _randomColor());
    }
    if (!mounted) return;
    setState(() {
      _color = _randomColor();
      _isGenerating = false;
    });
  }

  void _copyHex() {
    Clipboard.setData(ClipboardData(text: _hex));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$_hex kopyalandı'), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = ThemeData.estimateBrightnessForColor(_color);
    final textColor = brightness == Brightness.dark ? Colors.white : Colors.black87;
    return Scaffold(
      appBar: AppBar(title: const Text('Renk Seçici')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Spacer(),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: _color,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _color.withOpacity(0.5), blurRadius: 30, spreadRadius: 2)],
                  border: Border.all(color: Colors.white, width: 4),
                ),
                alignment: Alignment.center,
                child: Text(
                  _hex,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _copyHex,
                icon: const Icon(Icons.copy),
                label: const Text('Kodu Kopyala'),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isGenerating ? null : _generate,
                  icon: const Icon(Icons.palette),
                  label: Text(
                    _isGenerating ? 'Üretiliyor...' : 'Renk Üret',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// 7. HARF SEÇİCİ EKRANI
// =============================================================

class LetterPickerScreen extends StatefulWidget {
  const LetterPickerScreen({super.key});

  @override
  State<LetterPickerScreen> createState() => _LetterPickerScreenState();
}

class _LetterPickerScreenState extends State<LetterPickerScreen> {
  static const String _alphabet = 'ABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVYZ';
  final Random _random = Random();
  String _letter = 'A';
  bool _isGenerating = false;

  Future<void> _generate() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);
    const steps = 12;
    for (int i = 0; i < steps; i++) {
      await Future.delayed(Duration(milliseconds: 30 + i * 7));
      if (!mounted) return;
      setState(() => _letter = _alphabet[_random.nextInt(_alphabet.length)]);
    }
    if (!mounted) return;
    setState(() {
      _letter = _alphabet[_random.nextInt(_alphabet.length)];
      _isGenerating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Harf Seçici')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Spacer(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 120),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: Container(
                  key: ValueKey(_letter),
                  width: 200,
                  height: 200,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [scheme.primary, scheme.tertiary],
                    ),
                    boxShadow: [
                      BoxShadow(color: scheme.primary.withOpacity(0.4), blurRadius: 30, spreadRadius: 2),
                    ],
                  ),
                  child: Text(
                    _letter,
                    style: const TextStyle(fontSize: 84, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isGenerating ? null : _generate,
                  icon: const Icon(Icons.text_fields),
                  label: Text(
                    _isGenerating ? 'Seçiliyor...' : 'Harf Seç',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// 8. SLOT MAKİNESİ EKRANI
// =============================================================

enum SlotSymbol {
  diamond(Icons.diamond_rounded, 'Elmas', [Color(0xFF80F3FF), Color(0xFF00B2FE)]),
  star(Icons.star_rounded, 'Yıldız', [Color(0xFFFFE57F), Color(0xFFFFB300)]),
  bell(Icons.notifications_active_rounded, 'Zil', [Color(0xFFFFD180), Color(0xFFFF6D00)]),
  bolt(Icons.bolt_rounded, 'Şimşek', [Color(0xFFFFEA00), Color(0xFFFF9100)]),
  heart(Icons.favorite_rounded, 'Kalp', [Color(0xFFFF8A80), Color(0xFFFF1744)]);

  final IconData icon;
  final String label;
  final List<Color> colors;

  const SlotSymbol(this.icon, this.label, this.colors);
}

class SlotMachineScreen extends StatefulWidget {
  const SlotMachineScreen({super.key});

  @override
  State<SlotMachineScreen> createState() => _SlotMachineScreenState();
}

class _SlotMachineScreenState extends State<SlotMachineScreen> with SingleTickerProviderStateMixin {
  final Random _random = Random();
  late FixedExtentScrollController _controller1;
  late FixedExtentScrollController _controller2;
  late FixedExtentScrollController _controller3;
  late AnimationController _leverController;
  late Animation<double> _leverAnimation;

  bool _isSpinning = false;
  String _message = 'Şansını Dene!';
  bool _isJackpot = false;
  bool _isTwoSame = false;

  @override
  void initState() {
    super.initState();
    _controller1 = FixedExtentScrollController(initialItem: 1000);
    _controller2 = FixedExtentScrollController(initialItem: 1000);
    _controller3 = FixedExtentScrollController(initialItem: 1000);

    _leverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _leverAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _leverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    _leverController.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    if (_isSpinning) return;
    setState(() {
      _isSpinning = true;
      _message = 'Makaralar Dönüyor...';
      _isJackpot = false;
      _isTwoSame = false;
    });

    final int item1Offset = 25 + _random.nextInt(10);
    final int item2Offset = item1Offset + 12 + _random.nextInt(10);
    final int item3Offset = item2Offset + 12 + _random.nextInt(10);

    final int target1 = _controller1.selectedItem + item1Offset;
    final int target2 = _controller2.selectedItem + item2Offset;
    final int target3 = _controller3.selectedItem + item3Offset;

    final f1 = _controller1.animateToItem(
      target1,
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeOutCubic,
    );
    final f2 = _controller2.animateToItem(
      target2,
      duration: const Duration(milliseconds: 2200),
      curve: Curves.easeOutCubic,
    );
    final f3 = _controller3.animateToItem(
      target3,
      duration: const Duration(milliseconds: 3000),
      curve: Curves.easeOutBack,
    );

    await Future.wait([f1, f2, f3]);

    if (!mounted) return;

    final symbol1 = SlotSymbol.values[target1 % SlotSymbol.values.length];
    final symbol2 = SlotSymbol.values[target2 % SlotSymbol.values.length];
    final symbol3 = SlotSymbol.values[target3 % SlotSymbol.values.length];

    setState(() {
      _isSpinning = false;
      final allSame = symbol1 == symbol2 && symbol2 == symbol3;
      final twoSame = symbol1 == symbol2 || symbol2 == symbol3 || symbol1 == symbol3;

      if (allSame) {
        _isJackpot = true;
        _message = 'BÜYÜK İKRAMİYE! 🎉\n3x ${symbol1.label}!';
      } else if (twoSame) {
        _isTwoSame = true;
        _message = 'Tebrikler! İki Eşleşme ✨';
      } else {
        _message = 'Tekrar Dene! 🍀';
      }
    });
  }

  Widget _buildSlotIcon(SlotSymbol symbol) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: symbol.colors.map((c) => c.withOpacity(0.12)).toList(),
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: symbol.colors[0].withOpacity(0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: symbol.colors,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(bounds),
            child: Icon(
              symbol.icon,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            symbol.label,
            style: TextStyle(
              color: symbol.colors[0],
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReel(FixedExtentScrollController controller) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        height: 180,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.black26 : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: scheme.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: 80,
            physics: const NeverScrollableScrollPhysics(),
            diameterRatio: 1.1,
            useMagnifier: true,
            magnification: 1.15,
            overAndUnderCenterOpacity: 0.4,
            childDelegate: ListWheelChildLoopingListDelegate(
              children: SlotSymbol.values.map((sym) => _buildSlotIcon(sym)).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLever() {
    return GestureDetector(
      onTap: () {
        if (_isSpinning) return;
        _leverController.animateTo(1.0, duration: const Duration(milliseconds: 180)).then((_) {
          _spin();
          _leverController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.bounceOut,
          );
        });
      },
      onVerticalDragStart: (details) {
        if (_isSpinning) return;
        _leverController.value = 0.0;
      },
      onVerticalDragUpdate: (details) {
        if (_isSpinning) return;
        final double pullAmount = (details.localPosition.dy / 170.0).clamp(0.0, 1.0);
        _leverController.value = pullAmount;
      },
      onVerticalDragEnd: (details) {
        if (_isSpinning) return;
        if (_leverController.value > 0.65) {
          _leverController.animateTo(1.0, duration: const Duration(milliseconds: 80)).then((_) {
            _spin();
            _leverController.animateTo(
              0.0,
              duration: const Duration(milliseconds: 450),
              curve: Curves.bounceOut,
            );
          });
        } else {
          _leverController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      },
      child: AnimatedBuilder(
        animation: _leverAnimation,
        builder: (context, child) {
          return CustomPaint(
            size: const Size(54, 210),
            painter: SlotLeverPainter(pullProgress: _leverAnimation.value),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Slot Makinesi')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [const Color(0xFF1E1B24), const Color(0xFF2C1E38)]
                                  : [const Color(0xFFECE6F6), const Color(0xFFD6C8EC)],
                            ),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                            border: Border.all(color: scheme.primary.withOpacity(0.3), width: 1.5),
                          ),
                          child: Text(
                            '🍀 ŞANS SLOTU 🍀',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              color: scheme.primary,
                              shadows: [
                                Shadow(
                                  color: scheme.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF141218) : Colors.white,
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                            border: Border.all(color: scheme.primary.withOpacity(0.3), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: scheme.primary.withOpacity(0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Row(
                                children: [
                                  _buildReel(_controller1),
                                  _buildReel(_controller2),
                                  _buildReel(_controller3),
                                ],
                              ),
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.black.withOpacity(isDark ? 0.75 : 0.45),
                                          Colors.transparent,
                                          Colors.transparent,
                                          Colors.black.withOpacity(isDark ? 0.75 : 0.45),
                                        ],
                                        stops: const [0.0, 0.22, 0.78, 1.0],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildLever(),
                ],
              ),
              const SizedBox(height: 28),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                decoration: BoxDecoration(
                  color: _isJackpot
                      ? const Color(0xFFFFF9C4)
                      : (_isTwoSame ? scheme.primaryContainer : scheme.surfaceContainerHighest),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isJackpot
                        ? const Color(0xFFFBC02D)
                        : (_isTwoSame ? scheme.primary : scheme.outlineVariant.withOpacity(0.5)),
                    width: 1.5,
                  ),
                  boxShadow: _isJackpot
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFBC02D).withOpacity(0.4),
                            blurRadius: 12,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                ),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _isJackpot
                          ? const Color(0xFF5D4037)
                          : (_isTwoSame ? scheme.onPrimaryContainer : scheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSpinning ? null : _spin,
                  icon: const Icon(Icons.casino),
                  label: Text(
                    _isSpinning ? 'DÖNÜYOR...' : 'ÇEVİR',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: _isSpinning ? 0 : 4,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class SlotLeverPainter extends CustomPainter {
  final double pullProgress;
  SlotLeverPainter({required this.pullProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final pivotX = w / 2;
    final pivotY = h - 25;

    final socketPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.grey[400]!, Colors.grey[700]!, Colors.grey[900]!],
      ).createShader(Rect.fromCircle(center: Offset(pivotX, pivotY), radius: 18))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(pivotX, pivotY), 18, socketPaint);
    canvas.drawCircle(
      Offset(pivotX, pivotY),
      18,
      Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    final double startAngle = -pi / 2;
    final double endAngle = 0.05 * pi;
    final double angle = startAngle + pullProgress * (endAngle - startAngle);

    final double rodLength = h - 55;
    final double targetX = pivotX + rodLength * cos(angle);
    final double targetY = pivotY + rodLength * sin(angle);

    final rodPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.grey[300]!, Colors.grey[600]!, Colors.grey[800]!],
      ).createShader(Rect.fromPoints(Offset(pivotX, pivotY), Offset(targetX, targetY)))
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(pivotX, pivotY), Offset(targetX, targetY), rodPaint);

    final rodHighlight = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final hOffsetX = 2 * cos(angle - pi / 2);
    final hOffsetY = 2 * sin(angle - pi / 2);
    canvas.drawLine(
      Offset(pivotX + hOffsetX, pivotY + hOffsetY),
      Offset(targetX + hOffsetX, targetY + hOffsetY),
      rodHighlight,
    );

    final double knobRadius = 16;
    final knobCenter = Offset(targetX, targetY);

    final knobPaint = Paint()
      ..shader = RadialGradient(
        colors: const [
          Color(0xFFFF8A80),
          Color(0xFFFF1744),
          Color(0xFFB71C1C),
        ],
        center: const Alignment(-0.35, -0.35),
        radius: 0.9,
      ).createShader(Rect.fromCircle(center: knobCenter, radius: knobRadius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      knobCenter + const Offset(2, 3),
      knobRadius,
      Paint()..color = Colors.black.withOpacity(0.2),
    );

    canvas.drawCircle(knobCenter, knobRadius, knobPaint);
    canvas.drawCircle(
      knobCenter,
      knobRadius,
      Paint()
        ..color = const Color(0xFF880E4F).withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant SlotLeverPainter oldDelegate) =>
      oldDelegate.pullProgress != pullProgress;
}

// =============================================================
// 9. ŞİŞE ÇEVİRME EKRANI
// =============================================================

class BottleSpinScreen extends StatefulWidget {
  const BottleSpinScreen({super.key});

  @override
  State<BottleSpinScreen> createState() => _BottleSpinScreenState();
}

class _BottleSpinScreenState extends State<BottleSpinScreen> with SingleTickerProviderStateMixin {
  final List<String> _names = ['Sen', 'Ahmet', 'Ayşe', 'Mehmet'];
  final TextEditingController _textController = TextEditingController();

  late AnimationController _controller;
  late Animation<double> _animation;

  double _currentRotation = 0;
  String? _winner;
  bool _isSpinning = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) _onSpinComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _addName() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _names.add(text);
      _winner = null;
      _textController.clear();
    });
  }

  void _removeName(int index) {
    if (_names.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az 2 kişi kalmalıdır.')),
      );
      return;
    }
    setState(() {
      _names.removeAt(index);
      _winner = null;
    });
  }

  void _spin() {
    if (_names.length < 2 || _isSpinning) return;
    final random = Random();
    final int fullTurns = 6 + random.nextInt(4);
    final double randomStopAngle = random.nextDouble() * 2 * pi;
    final double targetRotation = _currentRotation + (fullTurns * 2 * pi) + randomStopAngle;

    _animation = Tween<double>(begin: _currentRotation, end: targetRotation)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));

    setState(() {
      _isSpinning = true;
      _winner = null;
    });

    _controller.reset();
    _controller.forward();
  }

  void _onSpinComplete() {
    final double finalAngle = _animation.value;
    _currentRotation = finalAngle % (2 * pi);

    final sliceAngle = 2 * pi / _names.length;

    double u = _currentRotation % (2 * pi);
    if (u < 0) u += 2 * pi;
    final index = (u / sliceAngle).floor() % _names.length;

    setState(() {
      _isSpinning = false;
      _winner = _names[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sliceAngle = 2 * pi / _names.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Şişe Çevirme')),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _winner != null
                  ? Padding(
                      key: ValueKey(_winner),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Card(
                        elevation: 0,
                        color: scheme.primaryContainer,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                          child: Text(
                            'Şişe: $_winner 🍾',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: scheme.onPrimaryContainer,
                                ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox(height: 8),
            ),
            const SizedBox(height: 12),
            Expanded(
              flex: 5,
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = min(constraints.maxWidth, constraints.maxHeight) * 0.9;
                    return SizedBox(
                      width: size,
                      height: size,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? const Color(0xFF1D1B20) : const Color(0xFFF3EDF7),
                              border: Border.all(
                                color: scheme.primary.withOpacity(0.15),
                                width: 8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: size * 0.75,
                            height: size * 0.75,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.transparent,
                              border: Border.all(
                                color: scheme.primary.withOpacity(0.06),
                                width: 2,
                              ),
                            ),
                          ),
                          for (int i = 0; i < _names.length; i++)
                            Builder(builder: (context) {
                              final angle = i * sliceAngle - pi / 2 + sliceAngle / 2;
                              final r = size / 2 * 0.76;
                              final isWinner = _winner == _names[i];
                              return Positioned(
                                left: size / 2 + r * cos(angle) - 45,
                                top: size / 2 + r * sin(angle) - 20,
                                width: 90,
                                height: 40,
                                child: AnimatedScale(
                                  scale: isWinner ? 1.15 : 1.0,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.elasticOut,
                                  child: Container(
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isWinner
                                          ? scheme.primaryContainer
                                          : (isDark ? Colors.white12 : Colors.white),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isWinner ? scheme.primary : Colors.black12,
                                        width: isWinner ? 2 : 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isWinner
                                              ? scheme.primary.withOpacity(0.3)
                                              : Colors.black.withOpacity(0.05),
                                          blurRadius: isWinner ? 8 : 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      _names[i],
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isWinner
                                            ? scheme.onPrimaryContainer
                                            : (isDark ? Colors.white70 : Colors.black87),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              final angle = _isSpinning ? _animation.value : _currentRotation;
                              final wobble = _isSpinning
                                  ? sin(_controller.value * 32) * 5 * (1.0 - _controller.value)
                                  : 0.0;
                              return Transform.translate(
                                offset: Offset(wobble, wobble / 2),
                                child: Transform.rotate(
                                  angle: angle,
                                  child: child,
                                ),
                              );
                            },
                            child: CustomPaint(
                              size: Size(size * 0.38, size * 0.38),
                              painter: BottlePainter(color: scheme.primary),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: _names.isEmpty
                  ? const Center(child: Text('Henüz kişi yok'))
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _names.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        return InputChip(
                          label: Text(_names[index]),
                          labelStyle: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                          backgroundColor:
                              pastelColors[index % pastelColors.length].withOpacity(isDark ? 0.3 : 0.8),
                          onDeleted: _isSpinning ? null : () => _removeName(index),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            Card(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            enabled: !_isSpinning,
                            decoration: InputDecoration(
                              hintText: 'İsim ekle...',
                              filled: true,
                              fillColor: scheme.surfaceContainerHighest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            onSubmitted: (_) => _addName(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonalIcon(
                          onPressed: _isSpinning ? null : _addName,
                          icon: const Icon(Icons.add),
                          label: const Text('Ekle'),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: (_names.length < 2 || _isSpinning) ? null : _spin,
                        icon: const Icon(Icons.sports_bar),
                        label: Text(
                          _isSpinning ? 'DÖNÜYOR...' : 'ŞİŞEYİ ÇEVİR',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                        ),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BottlePainter extends CustomPainter {
  final Color color;
  BottlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final shadowPath = Path();
    final sBodyWidth = w * 0.28;
    final sBodyHeight = h * 0.52;
    final sBodyRect = Rect.fromLTWH((w - sBodyWidth) / 2 + 3, h * 0.4 + 4, sBodyWidth, sBodyHeight);
    shadowPath.addRRect(RRect.fromRectAndRadius(sBodyRect, Radius.circular(sBodyWidth / 2)));

    final sNeckWidth = w * 0.12;
    final sNeckHeight = h * 0.44;
    final sNeckRect = Rect.fromLTWH((w - sNeckWidth) / 2 + 3, 4, sNeckWidth, sNeckHeight);
    shadowPath.addRRect(RRect.fromRectAndRadius(sNeckRect, Radius.circular(sNeckWidth / 2)));

    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withOpacity(0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    final path = Path();

    final neckWidth = w * 0.12;
    final neckHeight = h * 0.44;
    final neckRect = Rect.fromLTWH((w - neckWidth) / 2, 0, neckWidth, neckHeight);

    final bodyWidth = w * 0.28;
    final bodyHeight = h * 0.52;
    final bodyRect = Rect.fromLTWH((w - bodyWidth) / 2, h * 0.4, bodyWidth, bodyHeight);

    path.addRRect(RRect.fromRectAndRadius(neckRect, Radius.circular(neckWidth / 2.2)));
    path.addRRect(RRect.fromRectAndRadius(bodyRect, Radius.circular(bodyWidth / 2.5)));

    final glassGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF2E7D32),
        const Color(0xFF1B5E20),
        const Color(0xFF0C2B0E),
      ],
      stops: const [0.0, 0.65, 1.0],
    );

    final glassPaint = Paint()
      ..shader = glassGradient.createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, glassPaint);

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF071F08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final collarPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFD54F), Color(0xFFFFB300), Color(0xFFD84315)],
      ).createShader(Rect.fromLTWH((w - neckWidth) / 2, h * 0.12, neckWidth, 8))
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH((w - neckWidth * 1.15) / 2, h * 0.12, neckWidth * 1.15, 6),
        const Radius.circular(1.5),
      ),
      collarPaint,
    );

    final capPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFE082), Color(0xFFFFC107), Color(0xFFFF8F00)],
      ).createShader(Rect.fromLTWH((w - neckWidth * 1.2) / 2, 0, neckWidth * 1.2, 14))
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH((w - neckWidth * 1.25) / 2, 0, neckWidth * 1.25, 12),
        const Radius.circular(3),
      ),
      capPaint,
    );

    final labelWidth = bodyWidth * 0.78;
    final labelHeight = bodyHeight * 0.38;
    final labelRect = Rect.fromLTWH((w - labelWidth) / 2, h * 0.52, labelWidth, labelHeight);
    final labelPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFF9C4), Color(0xFFFBC02D), Color(0xFFF57F17)],
      ).createShader(labelRect)
      ..style = PaintingStyle.fill;

    final labelRRect = RRect.fromRectAndRadius(labelRect, const Radius.circular(6));
    canvas.drawRRect(labelRRect, labelPaint);
    canvas.drawRRect(
      labelRRect,
      Paint()
        ..color = const Color(0xFF6D4C41)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final starPath = Path();
    final scx = w / 2;
    final scy = h * 0.52 + labelHeight / 2;
    const double starSize = 9;
    for (int i = 0; i < 5; i++) {
      final double angle = i * 4 * pi / 5 - pi / 2;
      final double x = scx + starSize * cos(angle);
      final double y = scy + starSize * sin(angle);
      if (i == 0) {
        starPath.moveTo(x, y);
      } else {
        starPath.lineTo(x, y);
      }
    }
    starPath.close();
    canvas.drawPath(starPath, Paint()..color = const Color(0xFF3E2723));

    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH((w - bodyWidth) / 2 + 4, h * 0.42, 4.5, bodyHeight * 0.65),
        const Radius.circular(2),
      ),
      highlightPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH((w - neckWidth) / 2 + 2, 14, 2, neckHeight * 0.55),
        const Radius.circular(1),
      ),
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant BottlePainter oldDelegate) => oldDelegate.color != color;
}

// =============================================================
// 10. TAŞ KAĞIT MAKAS EKRANI (DÜZELTİLMİŞ VE ÇALIŞIR)
// =============================================================

// =============================================================
// 10. TAŞ KAĞIT MAKAS EKRANI - YENİDEN TASARLANDI
// =============================================================
//
// KULLANIM: Bu blok, orijinal dosyandaki
//   "// 10. TAŞ KAĞIT MAKAS EKRANI (DÜZELTİLMİŞ VE ÇALIŞIR)"
// yorumundan itibaren dosyanın SONUNA kadar olan her şeyin
// (enum RPSChoice, RockPaperScissorsScreen, RPSHandPainter dahil)
// yerine geçer. Başka hiçbir yeri değiştirmene gerek yok.
// İhtiyaç duyduğu importlar (dart:math, material, services)
// zaten dosyanın en üstünde mevcut.

enum RPSChoice { rock, paper, scissors }

extension RPSChoiceX on RPSChoice {
  /// Gerçek el ifadesi: ✊ yumruk (taş), ✋ düz açık el (kağıt), ✌️ iki parmak (makas)
  String get emoji {
    switch (this) {
      case RPSChoice.rock:
        return '✊';
      case RPSChoice.paper:
        return '✋';
      case RPSChoice.scissors:
        return '✌️';
    }
  }

  String get label {
    switch (this) {
      case RPSChoice.rock:
        return 'TAŞ';
      case RPSChoice.paper:
        return 'KAĞIT';
      case RPSChoice.scissors:
        return 'MAKAS';
    }
  }

  List<Color> get palette {
    switch (this) {
      case RPSChoice.rock:
        return const [Color(0xFFFF9E6D), Color(0xFFE64A19)];
      case RPSChoice.paper:
        return const [Color(0xFF6FB8FF), Color(0xFF1565C0)];
      case RPSChoice.scissors:
        return const [Color(0xFFD98CE8), Color(0xFF6A1B9A)];
    }
  }
}

enum _RoundOutcome { none, win, lose, draw }

class RockPaperScissorsScreen extends StatefulWidget {
  const RockPaperScissorsScreen({super.key});

  @override
  State<RockPaperScissorsScreen> createState() => _RockPaperScissorsScreenState();
}

class _RockPaperScissorsScreenState extends State<RockPaperScissorsScreen>
    with TickerProviderStateMixin {
  final Random _random = Random();

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  late final AnimationController _revealController;
  late final Animation<double> _revealAnim;

  late final AnimationController _vsController;

  RPSChoice? _selectedChoice;
  RPSChoice? _playerChoice;
  RPSChoice? _computerChoice;

  bool _isPlaying = false;
  bool _showResult = false;
  String? _countdownText;

  int _playerScore = 0;
  int _computerScore = 0;
  int _draws = 0;

  _RoundOutcome _outcome = _RoundOutcome.none;

  static const List<String> _countdownSteps = ['TAŞ', 'KAĞIT', 'MAKAS', 'ÇEKİLİŞ!'];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _pulseAnim = CurvedAnimation(parent: _pulseController, curve: Curves.easeOutBack);

    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _revealAnim = CurvedAnimation(parent: _revealController, curve: Curves.elasticOut);

    _vsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _revealController.dispose();
    _vsController.dispose();
    super.dispose();
  }

  void _selectChoice(RPSChoice choice) {
    if (_isPlaying) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedChoice = choice;
      _showResult = false;
      _outcome = _RoundOutcome.none;
      _playerChoice = null;
      _computerChoice = null;
    });
  }

  Future<void> _play() async {
    if (_isPlaying) return;
    if (_selectedChoice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen önce bir seçim yapın'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    setState(() {
      _isPlaying = true;
      _showResult = false;
      _outcome = _RoundOutcome.none;
      _computerChoice = null;
    });

    for (final step in _countdownSteps) {
      if (!mounted) return;
      setState(() => _countdownText = step);
      HapticFeedback.lightImpact();
      _pulseController.reset();
      await _pulseController.forward();
      await Future.delayed(const Duration(milliseconds: 160));
    }

    if (!mounted) return;

    final computer = RPSChoice.values[_random.nextInt(3)];
    final outcome = _resolve(_selectedChoice!, computer);

    setState(() {
      _isPlaying = false;
      _countdownText = null;
      _playerChoice = _selectedChoice;
      _computerChoice = computer;
      _outcome = outcome;
      _showResult = true;
      if (outcome == _RoundOutcome.win) _playerScore++;
      if (outcome == _RoundOutcome.lose) _computerScore++;
      if (outcome == _RoundOutcome.draw) _draws++;
    });

    switch (outcome) {
      case _RoundOutcome.win:
        HapticFeedback.mediumImpact();
        break;
      case _RoundOutcome.lose:
        HapticFeedback.lightImpact();
        break;
      default:
        HapticFeedback.selectionClick();
    }

    _revealController.reset();
    await _revealController.forward();
  }

  _RoundOutcome _resolve(RPSChoice player, RPSChoice computer) {
    if (player == computer) return _RoundOutcome.draw;
    final beats = {
      RPSChoice.rock: RPSChoice.scissors,
      RPSChoice.paper: RPSChoice.rock,
      RPSChoice.scissors: RPSChoice.paper,
    };
    return beats[player] == computer ? _RoundOutcome.win : _RoundOutcome.lose;
  }

  void _resetScore() {
    HapticFeedback.selectionClick();
    setState(() {
      _playerScore = 0;
      _computerScore = 0;
      _draws = 0;
    });
  }

  String get _resultTitle {
    switch (_outcome) {
      case _RoundOutcome.win:
        return 'Kazandınız!';
      case _RoundOutcome.lose:
        return 'Bilgisayar Kazandı';
      case _RoundOutcome.draw:
        return 'Berabere';
      case _RoundOutcome.none:
        return 'Seçiminizi yapın';
    }
  }

  Color get _resultColor {
    final scheme = Theme.of(context).colorScheme;
    switch (_outcome) {
      case _RoundOutcome.win:
        return const Color(0xFF22C55E);
      case _RoundOutcome.lose:
        return const Color(0xFFEF4444);
      case _RoundOutcome.draw:
        return const Color(0xFFF59E0B);
      case _RoundOutcome.none:
        return scheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Taş Kağıt Makas')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            children: [
              _buildScoreBar(scheme),
              const SizedBox(height: 20),
              Expanded(child: _buildBattleArea(scheme, isDark)),
              const SizedBox(height: 16),
              _buildResultBanner(scheme),
              const SizedBox(height: 18),
              Row(
                children: RPSChoice.values
                    .map((c) => _buildChoiceButton(c, scheme))
                    .toList(),
              ),
              const SizedBox(height: 14),
              _buildPlayButton(scheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreBar(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            scheme.primaryContainer.withOpacity(0.7),
            scheme.surfaceContainerHighest,
          ],
        ),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _scoreColumn('SİZ', _playerScore, scheme.primary, leading: _playerScore >= _computerScore && _playerScore > 0),
          _scoreDivider(scheme),
          _scoreColumn('BERABERE', _draws, const Color(0xFFF59E0B)),
          _scoreDivider(scheme),
          _scoreColumn('BİLGİSAYAR', _computerScore, const Color(0xFFF87171), leading: _computerScore > _playerScore),
        ],
      ),
    );
  }

  Widget _scoreDivider(ColorScheme scheme) =>
      Container(height: 40, width: 1, color: scheme.outline.withOpacity(0.25));

  Widget _scoreColumn(String label, int score, Color color, {bool leading = false}) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading) const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Text('👑', style: TextStyle(fontSize: 12)),
            ),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          score.toString(),
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color),
        ),
      ],
    );
  }

  Widget _buildBattleArea(ColorScheme scheme, bool isDark) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          children: [
            Expanded(
              child: _PlayerCard(
                title: 'BİLGİSAYAR',
                choice: _computerChoice,
                accent: const Color(0xFFF87171),
                isWinner: _showResult && _outcome == _RoundOutcome.lose,
                revealAnim: _revealAnim,
                showResult: _showResult,
                resultColor: _resultColor,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            _buildVsBadge(scheme),
            const SizedBox(width: 8),
            Expanded(
              child: _PlayerCard(
                title: 'SİZ',
                choice: _playerChoice ?? _selectedChoice,
                accent: scheme.primary,
                isWinner: _showResult && _outcome == _RoundOutcome.win,
                revealAnim: _revealAnim,
                showResult: _showResult,
                resultColor: _resultColor,
                isDark: isDark,
              ),
            ),
          ],
        ),
        if (_isPlaying && _countdownText != null)
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.6 + _pulseAnim.value * 0.5,
                child: Opacity(
                  opacity: _pulseAnim.value.clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                _countdownText!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVsBadge(ColorScheme scheme) {
    return AnimatedBuilder(
      animation: _vsController,
      builder: (context, child) {
        final t = _vsController.value;
        final scale = 1.0 + sin(t * pi) * 0.08;
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: _showResult
                ? [_resultColor, _resultColor.withOpacity(0.55)]
                : [scheme.primary, scheme.tertiary],
          ),
          boxShadow: [
            BoxShadow(
              color: (_showResult ? _resultColor : scheme.primary).withOpacity(0.4),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          _showResult
              ? (_outcome == _RoundOutcome.win
                  ? '🏆'
                  : _outcome == _RoundOutcome.lose
                      ? '💻'
                      : '🤝')
              : 'VS',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildResultBanner(ColorScheme scheme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: _showResult ? _resultColor.withOpacity(0.14) : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _showResult ? _resultColor.withOpacity(0.5) : scheme.outlineVariant.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: Text(
          _isPlaying ? 'Kararınız veriliyor...' : _resultTitle,
          key: ValueKey('${_isPlaying}_$_outcome'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: _showResult ? _resultColor : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceButton(RPSChoice choice, ColorScheme scheme) {
    final isSelected = _selectedChoice == choice;
    final palette = choice.palette;

    return Expanded(
      child: GestureDetector(
        onTap: () => _selectChoice(choice),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(colors: palette, begin: Alignment.topLeft, end: Alignment.bottomRight)
                : null,
            color: isSelected ? null : scheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? palette[1] : scheme.outline.withOpacity(0.3),
              width: isSelected ? 2 : 1.5,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: palette[1].withOpacity(0.35), blurRadius: 16, spreadRadius: 1)]
                : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    choice.emoji,
                    style: const TextStyle(fontSize: 34),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    choice.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (isSelected)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Icon(Icons.check_circle, color: palette[1], size: 18),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayButton(ColorScheme scheme) {
    final ready = _selectedChoice != null && !_isPlaying;
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: ready
              ? LinearGradient(colors: [scheme.primary, scheme.tertiary])
              : null,
        ),
        child: FilledButton.icon(
          onPressed: ready ? _play : null,
          icon: Icon(_isPlaying ? Icons.hourglass_bottom : Icons.play_arrow),
          label: Text(
            _isPlaying
                ? 'SALLANIYOR...'
                : _selectedChoice == null
                    ? 'SEÇİM YAPIN'
                    : 'BAŞLA',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: ready ? Colors.transparent : null,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final String title;
  final RPSChoice? choice;
  final Color accent;
  final bool isWinner;
  final Animation<double> revealAnim;
  final bool showResult;
  final Color resultColor;
  final bool isDark;

  const _PlayerCard({
    required this.title,
    required this.choice,
    required this.accent,
    required this.isWinner,
    required this.revealAnim,
    required this.showResult,
    required this.resultColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            title,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accent),
          ),
        ),
        const SizedBox(height: 14),
        AnimatedBuilder(
          animation: revealAnim,
          builder: (context, child) {
            final scale = choice != null ? (0.85 + 0.15 * revealAnim.value.clamp(0.0, 1.0)) : 1.0;
            return Transform.scale(scale: scale, child: child);
          },
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (isWinner)
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: resultColor.withOpacity(0.22),
                  ),
                ),
              Container(
                width: 118,
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF27272A), const Color(0xFF3F3F46)]
                        : [Colors.white, const Color(0xFFF4F4F5)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: showResult && choice != null ? resultColor : Colors.grey.shade300,
                    width: showResult && choice != null ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: showResult && choice != null
                          ? resultColor.withOpacity(0.28)
                          : Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: choice != null
                    ? Text(
                        choice!.emoji,
                        style: const TextStyle(fontSize: 60),
                      )
                    : Icon(Icons.question_mark_rounded, size: 48, color: Colors.grey.shade400),
              ),
              if (isWinner) ...[
                const Positioned(top: -10, left: 4, child: Text('✨', style: TextStyle(fontSize: 18))),
                const Positioned(bottom: -6, right: 2, child: Text('✨', style: TextStyle(fontSize: 16))),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          choice != null ? choice!.label : '—',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: choice != null && showResult ? resultColor : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}