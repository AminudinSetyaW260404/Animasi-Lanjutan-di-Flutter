import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Efek kartu jawaban terbalik (flip) secara bergiliran.
///
/// Digunakan pada Langkah 3 modul:
/// - [StatefulWidget] dengan [SingleTickerProviderStateMixin].
/// - [AnimationController] dijalankan lewat [didUpdateWidget] ketika soal
///   berubah ([questionId] berbeda), sehingga state tidak dibuang.
/// - [AnimatedBuilder] + [Transform] dengan rotasi `rotateX` (efek perspektif).
/// - [TweenSequence] membagi flip menjadi dua fase: membalik keluar lalu
///   membalik masuk.
/// - [delayAmount] memberi jeda per kartu agar flip terjadi secara
///   bergiliran (berjenjang) antar pilihan jawaban.
/// - Controller dibuang di [dispose] sehingga tidak terjadi memory leak.
class CardFlipEffect extends StatefulWidget {
  const CardFlipEffect({
    super.key,
    required this.child,
    required this.questionId,
    this.delayAmount = 0,
    this.flipDuration = const Duration(milliseconds: 500),
  });

  /// Konten kartu (jawaban) untuk soal saat ini.
  final Widget child;

  /// Penanda soal; berubah setiap kali pindah soal -> memicu flip.
  final int questionId;

  /// Jeda (milidetik) sebelum flip berjalan, dipakai untuk efek bergiliran.
  final int delayAmount;

  /// Durasi satu kali flip.
  final Duration flipDuration;

  @override
  State<CardFlipEffect> createState() => _CardFlipEffectState();
}

class _CardFlipEffectState extends State<CardFlipEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _flipAngle;

  Timer? _flipTimer;

  /// Konten lama yang sedang dibalik keluar.
  Widget? _outgoing;

  /// True selama menunggu [delayAmount] sebelum flip dimulai.
  bool _awaitingFlip = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.flipDuration,
    );
    // Dua fase flip: 0 -> 90 derajat (keluar), lalu -90 -> 0 derajat (masuk).
    _flipAngle = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.0, end: math.pi / 2).chain(
          CurveTween(curve: Curves.easeInCubic),
        ),
        weight: 50,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: -math.pi / 2, end: 0.0).chain(
          CurveTween(curve: Curves.easeOutCubic),
        ),
        weight: 50,
      ),
    ]).animate(_controller);

    // Flip masuk bergiliran saat kartu pertama muncul.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startFlip(widget.child);
      }
    });
  }

  @override
  void didUpdateWidget(covariant CardFlipEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Jalankan animasi ketika soal berubah.
    if (oldWidget.questionId != widget.questionId) {
      _startFlip(oldWidget.child);
    }
  }

  /// Menjadwalkan flip keluar dari [outgoing] menuju konten baru,
  /// dimulai setelah jeda [CardFlipEffect.delayAmount].
  void _startFlip(Widget outgoing) {
    _flipTimer?.cancel();
    _outgoing = outgoing;
    _awaitingFlip = true;
    _flipTimer = Timer(Duration(milliseconds: widget.delayAmount), () {
      if (!mounted) {
        return;
      }
      _awaitingFlip = false;
      _controller.forward(from: 0.0).whenCompleteOrCancel(() {
        if (mounted) {
          _outgoing = null;
        }
      });
    });
  }

  @override
  void dispose() {
    _flipTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final bool showOutgoing =
            _outgoing != null && (_awaitingFlip || _controller.value < 0.5);
        final Widget content = showOutgoing ? _outgoing! : widget.child;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // efek perspektif
            ..rotateX(_flipAngle.value),
          child: content,
        );
      },
    );
  }
}
