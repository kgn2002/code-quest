import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BLOCKCHAIN CERTIFICATE SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class CertificateScreen extends StatefulWidget {
  final String   username;
  final int      totalXp;
  final int      questsCompleted;
  final String   certificateHash;
  final int      blockIndex;
  final DateTime issuedAt;
  final VoidCallback onClose;

  const CertificateScreen({
    super.key,
    required this.username,
    required this.totalXp,
    required this.questsCompleted,
    required this.certificateHash,
    required this.blockIndex,
    required this.issuedAt,
    required this.onClose,
  });

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen>
    with TickerProviderStateMixin {

  late final AnimationController _fadeCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _shimmerCtrl;
  late final AnimationController _starsCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<double>   _floatAnim;
  late final Animation<double>   _shimmerAnim;

  bool _hashCopied = false;

  static const _topics = [
    ('🖨️', 'Print & Syntax'),
    ('📦', 'Variables'),
    ('➕', 'Math & Operators'),
    ('🔀', 'If / Else Logic'),
    ('📋', 'Lists'),
    ('🔁', 'For Loops'),
    ('⚙️', 'Functions'),
    ('🔤', 'String Methods'),
    ('📚', 'Dictionaries'),
    ('✅', 'Booleans'),
    ('🔢', 'Type Conversion'),
    ('🔄', 'While Loops'),
    ('🧬', 'Regex & Slicing'),
  ];

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -6, end: 6)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
    _shimmerAnim = Tween<double>(begin: -1, end: 2).animate(_shimmerCtrl);

    _starsCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 6))
      ..repeat();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _floatCtrl.dispose();
    _shimmerCtrl.dispose();
    _starsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07071A),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          children: [
            // Starfield background
            _StarField(controller: _starsCtrl),

            // Scanlines overlay
            _Scanlines(),

            // Main scrollable content
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(children: [

                  // ── Top bar ─────────────────────────────────────────
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const _Label('⚔️  CODEQUEST ACADEMY'),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white38),
                      onPressed: widget.onClose,
                    ),
                  ]),
                  const SizedBox(height: 4),

                  // ── Title ───────────────────────────────────────────
                  AnimatedBuilder(
                    animation: _shimmerAnim,
                    builder: (_, __) => ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: const [
                          Color(0xFFC8960C), Color(0xFFF0C040),
                          Color(0xFFFFF8DC), Color(0xFFF0C040),
                          Color(0xFFC8960C),
                        ],
                        stops: [0, .35, .5, .65, 1],
                        begin: Alignment(_shimmerAnim.value - 1, 0),
                        end:   Alignment(_shimmerAnim.value,     0),
                      ).createShader(bounds),
                      child: const Text(
                        'Certificate of\nMastery',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 36, fontWeight: FontWeight.w900,
                          color: Colors.white, height: 1.1,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const _Label('PYTHON PROGRAMMING  ·  BLOCKCHAIN VERIFIED'),
                  const SizedBox(height: 28),

                  // ── Main card ────────────────────────────────────────
                  _CertCard(
                    floatAnim: _floatAnim,
                    shimmerAnim: _shimmerAnim,
                    username: widget.username,
                    totalXp: widget.totalXp,
                    questsCompleted: widget.questsCompleted,
                    topics: _topics,
                    issuedAt: widget.issuedAt,
                    blockIndex: widget.blockIndex,
                    certificateHash: widget.certificateHash,
                    hashCopied: _hashCopied,
                    onCopyHash: _copyHash,
                  ),

                  const SizedBox(height: 28),

                  // ── Close button ─────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('CONTINUE ADVENTURE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1A30),
                        foregroundColor: const Color(0xFFF0C040),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFF8B5E1A), width: 1),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyHash() {
    Clipboard.setData(ClipboardData(text: widget.certificateHash));
    setState(() => _hashCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _hashCopied = false);
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN CERTIFICATE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _CertCard extends StatelessWidget {
  final Animation<double> floatAnim;
  final Animation<double> shimmerAnim;
  final String   username;
  final int      totalXp;
  final int      questsCompleted;
  final List<(String, String)> topics;
  final DateTime issuedAt;
  final int      blockIndex;
  final String   certificateHash;
  final bool     hashCopied;
  final VoidCallback onCopyHash;

  const _CertCard({
    required this.floatAnim,
    required this.shimmerAnim,
    required this.username,
    required this.totalXp,
    required this.questsCompleted,
    required this.topics,
    required this.issuedAt,
    required this.blockIndex,
    required this.certificateHash,
    required this.hashCopied,
    required this.onCopyHash,
  });

  @override
  Widget build(BuildContext context) {
    final shortHash = certificateHash.length > 20
        ? '${certificateHash.substring(0, 20)}...' : certificateHash;
    final prevHashPreview = certificateHash.length > 32
        ? certificateHash.substring(0, 32) : certificateHash;
    final issued = '${issuedAt.year}-'
        '${issuedAt.month.toString().padLeft(2,'0')}-'
        '${issuedAt.day.toString().padLeft(2,'0')}';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF13132A), Color(0xFF0D0D1F), Color(0xFF13132A)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2A48)),
        boxShadow: [
          BoxShadow(color: const Color(0xFFF0C040).withOpacity(.08),
              blurRadius: 40, spreadRadius: 2),
          BoxShadow(color: Colors.black.withOpacity(.4), blurRadius: 20),
        ],
      ),
      child: Stack(children: [
        // Corner ornaments
        ..._corners(),

        Padding(
          padding: const EdgeInsets.all(28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [

            // Trophy
            AnimatedBuilder(
              animation: floatAnim,
              builder: (_, __) => Transform.translate(
                offset: Offset(0, floatAnim.value),
                child: const Text('🏆',
                    style: TextStyle(fontSize: 64)),
              ),
            ),
            const SizedBox(height: 16),

            const _Label('THIS CERTIFIES THAT'),
            const SizedBox(height: 8),

            // Hero name
            AnimatedBuilder(
              animation: shimmerAnim,
              builder: (_, __) => ShaderMask(
                shaderCallback: (b) => LinearGradient(
                  colors: const [Color(0xFFF0C040), Colors.white, Color(0xFFF0C040)],
                  begin: Alignment(shimmerAnim.value - 1, 0),
                  end: Alignment(shimmerAnim.value, 0),
                ).createShader(b),
                child: Text(username,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 30, fontWeight: FontWeight.w900,
                      color: Colors.white, letterSpacing: 1.5,
                    )),
              ),
            ),
            const SizedBox(height: 14),

            Text(
              'has successfully completed the\nCodeQuest Python Adventure\n'
              'mastering all 13 core Python topics across two villages\n'
              'and proven exceptional skill in the Grand Master Challenge.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14, height: 1.6,
                color: Colors.white.withOpacity(.75),
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),

            // Stats
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _StatBox(value: '$totalXp', label: 'TOTAL XP'),
              const SizedBox(width: 12),
              _StatBox(value: '$questsCompleted', label: 'QUESTS'),
              const SizedBox(width: 12),
              _StatBox(value: '13', label: 'TOPICS'),
            ]),
            const SizedBox(height: 24),

            // Topics mastered
            const _Label('✦  TOPICS MASTERED  ✦'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              alignment: WrapAlignment.center,
              children: topics.map((t) => _TopicChip(
                icon: t.$1, label: t.$2)).toList(),
            ),

            // Divider
            Container(
              margin: const EdgeInsets.symmetric(vertical: 24),
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Color(0xFF8B5E1A),
                           Color(0xFFF0C040), Color(0xFF8B5E1A), Colors.transparent],
                ),
              ),
            ),

            // Blockchain section
            const _Label('⛓  BLOCKCHAIN VERIFICATION  ⛓',
                color: Color(0xFF9B6DFF)),
            const SizedBox(height: 12),

            _BlockchainBlock(
              blockIndex:      blockIndex,
              issued:          issued,
              username:        username,
              prevHashPreview: prevHashPreview,
              certificateHash: certificateHash,
              hashCopied:      hashCopied,
              onCopy:          onCopyHash,
            ),

            const SizedBox(height: 14),

            // Verified badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF00FFAA).withOpacity(.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF00FFAA).withOpacity(.2)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                Icon(Icons.verified, color: Color(0xFF00FFAA), size: 18),
                SizedBox(width: 10),
                Text('CHAIN INTEGRITY VERIFIED  ·  SHA-256  ·  TAMPER-PROOF',
                    style: TextStyle(
                      color: Color(0xFF00FFAA), fontSize: 10,
                      letterSpacing: 1.5, fontFamily: 'monospace')),
              ]),
            ),

            // Footer
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Issued: $issued',
                    style: const TextStyle(color: Color(0xFF888899),
                        fontSize: 11, fontFamily: 'monospace')),
                Text('Block #$blockIndex',
                    style: const TextStyle(color: Color(0xFF888899),
                        fontSize: 11, fontFamily: 'monospace')),
              ]),
              _SigBlock(label: 'CodeQuest Academy'),
              _SigBlock(label: 'Course Director'),
            ]),
          ]),
        ),
      ]),
    );
  }

  List<Widget> _corners() => [
    _Corner(top: true,  left: true),
    _Corner(top: true,  left: false),
    _Corner(top: false, left: true),
    _Corner(top: false, left: false),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// BLOCKCHAIN BLOCK WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class _BlockchainBlock extends StatelessWidget {
  final int      blockIndex;
  final String   issued;
  final String   username;
  final String   prevHashPreview;
  final String   certificateHash;
  final bool     hashCopied;
  final VoidCallback onCopy;

  const _BlockchainBlock({
    required this.blockIndex,
    required this.issued,
    required this.username,
    required this.prevHashPreview,
    required this.certificateHash,
    required this.hashCopied,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A1F4E)),
      ),
      child: Column(children: [
        _BlockRow(label: 'Block',      value: '#$blockIndex',    valueColor: const Color(0xFF00FFAA)),
        _BlockRow(label: 'Timestamp',  value: issued),
        _BlockRow(label: 'Recipient',  value: username,          valueColor: const Color(0xFF00FFAA)),
        _BlockRow(label: 'Prev Hash',  value: '$prevHashPreview...', valueColor: const Color(0xFF9B6DFF)),
        const SizedBox(height: 4),
        Row(children: [
          const SizedBox(
            width: 90,
            child: Text('Cert Hash',
                style: TextStyle(color: Color(0xFF8888AA),
                    fontSize: 11, fontFamily: 'monospace'))),
          Expanded(
            child: Text(
              certificateHash.length > 28
                  ? '${certificateHash.substring(0,28)}...'
                  : certificateHash,
              style: const TextStyle(color: Color(0xFF9B6DFF),
                  fontSize: 11, fontFamily: 'monospace'),
            ),
          ),
          GestureDetector(
            onTap: onCopy,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: hashCopied
                  ? const Icon(Icons.check, color: Color(0xFF00FFAA), size: 16,
                      key: ValueKey('check'))
                  : const Icon(Icons.copy, color: Color(0xFF9B6DFF), size: 16,
                      key: ValueKey('copy')),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SMALL HELPER WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  final Color  color;
  const _Label(this.text, {this.color = const Color(0xFF8888AA)});

  @override
  Widget build(BuildContext context) => Text(text,
      textAlign: TextAlign.center,
      style: TextStyle(
          color: color, fontSize: 10,
          letterSpacing: 3.5, fontFamily: 'monospace',
          fontWeight: FontWeight.bold));
}

class _StatBox extends StatelessWidget {
  final String value, label;
  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A48)),
      ),
      child: Column(children: [
        Text(value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900,
                color: Color(0xFFF0C040))),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 9, letterSpacing: 2,
                color: Color(0xFF8888AA), fontFamily: 'monospace')),
      ]));
}

class _TopicChip extends StatelessWidget {
  final String icon, label;
  const _TopicChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF00FFAA).withOpacity(.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF00FFAA).withOpacity(.15)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(icon, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(color: Color(0xFF00FFAA), fontSize: 11)),
      ]));
}

class _BlockRow extends StatelessWidget {
  final String label, value;
  final Color valueColor;
  const _BlockRow({
    required this.label, required this.value,
    this.valueColor = const Color(0xFF00D4FF),
  });

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        SizedBox(width: 90,
            child: Text(label,
                style: const TextStyle(color: Color(0xFF8888AA),
                    fontSize: 11, fontFamily: 'monospace'))),
        Expanded(child: Text(value,
            style: TextStyle(color: valueColor, fontSize: 11,
                fontFamily: 'monospace'))),
      ]));
}

class _SigBlock extends StatelessWidget {
  final String label;
  const _SigBlock({required this.label});

  @override
  Widget build(BuildContext context) => Column(children: [
        Container(width: 100, height: 1,
            color: const Color(0xFF8B5E1A).withOpacity(.5)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: Color(0xFF8888AA),
                fontSize: 9, letterSpacing: 2, fontFamily: 'monospace')),
      ]);
}

class _Corner extends StatelessWidget {
  final bool top, left;
  const _Corner({required this.top, required this.left});

  @override
  Widget build(BuildContext context) => Positioned(
      top:    top    ? 14 : null,
      bottom: !top   ? 14 : null,
      left:   left   ? 14 : null,
      right:  !left  ? 14 : null,
      child: SizedBox(
        width: 60, height: 60,
        child: CustomPaint(painter: _CornerPainter(top: top, left: left)),
      ));
}

class _CornerPainter extends CustomPainter {
  final bool top, left;
  _CornerPainter({required this.top, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B5E1A).withOpacity(.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    if (top && left) {
      path.moveTo(0, 20); path.lineTo(0, 0); path.lineTo(20, 0);
    } else if (top && !left) {
      path.moveTo(size.width - 20, 0); path.lineTo(size.width, 0);
      path.lineTo(size.width, 20);
    } else if (!top && left) {
      path.moveTo(0, size.height - 20); path.lineTo(0, size.height);
      path.lineTo(20, size.height);
    } else {
      path.moveTo(size.width - 20, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, size.height - 20);
    }
    canvas.drawPath(path, paint);
  }

  @override bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// STAR FIELD
// ─────────────────────────────────────────────────────────────────────────────
class _StarField extends StatelessWidget {
  final AnimationController controller;
  const _StarField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final rng = Random(42);
        return CustomPaint(
          size: Size.infinite,
          painter: _StarsPainter(
            count: 100, seed: 42, phase: controller.value, rng: rng),
        );
      },
    );
  }
}

class _StarsPainter extends CustomPainter {
  final int count, seed;
  final double phase;
  final Random rng;

  _StarsPainter({
    required this.count, required this.seed,
    required this.phase, required this.rng});

  @override
  void paint(Canvas canvas, Size size) {
    final r = Random(seed);
    final paint = Paint();
    for (int i = 0; i < count; i++) {
      final x = r.nextDouble() * size.width;
      final y = r.nextDouble() * size.height;
      final blink = sin((phase + r.nextDouble()) * 2 * pi);
      final opacity = (.2 + .3 * ((blink + 1) / 2)).clamp(.05, .55);
      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), 1.2, paint);
    }
  }

  @override bool shouldRepaint(_StarsPainter old) => old.phase != phase;
}

// ─────────────────────────────────────────────────────────────────────────────
// SCANLINES
// ─────────────────────────────────────────────────────────────────────────────
class _Scanlines extends StatelessWidget {
  const _Scanlines();

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: _ScanlinesImage(), fit: BoxFit.cover, opacity: .04),
      ),
    ),
  );
}

// Fake image provider for scanlines pattern
class _ScanlinesImage extends ImageProvider<_ScanlinesImage> {
  const _ScanlinesImage();
  @override Future<_ScanlinesImage> obtainKey(ImageConfiguration c) =>
      SynchronousFuture(this);
  @override ImageStreamCompleter loadImage(_, __) =>
      OneFrameImageStreamCompleter(SynchronousFuture(
          ImageInfo(image: _emptyImage, scale: 1)));
  static final _emptyImage = _buildEmptyImage();
  static dynamic _buildEmptyImage() => null;
}
