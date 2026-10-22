import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

/// Palet warna aplikasi kuis: biru tua, putih, dan cyan.
class AppColors {
  AppColors._();

  /// Biru tua - warna utama aplikasi.
  static const Color navy = Color(0xFF0D2B55);

  /// Biru tua paling gelap untuk latar gradien.
  static const Color navyDeep = Color(0xFF061731);

  /// Biru tua lebih terang untuk aksen lembut di atas latar putih.
  static const Color navySoft = Color(0xFF1B4A82);

  /// Putih untuk kartu dan teks di atas latar gelap.
  static const Color white = Color(0xFFFFFFFF);

  /// Cyan terang untuk aksen di atas latar biru tua.
  static const Color cyan = Color(0xFF00E5FF);

  /// Cyan lebih pekat untuk ikon/teks di atas latar putih.
  static const Color cyanDeep = Color(0xFF0097A7);

  /// Latar aplikasi (putih kebiruan).
  static const Color background = Color(0xFFF3F7FC);

  /// Warna penanda jawaban salah (merah lembut).
  static const Color wrong = Color(0xFFE53935);

  /// Warna ikon yang belum dijawab.
  static const Color pendingIcon = Color(0xFFB0BEC5);
}

/// Tema aplikasi kuis dengan skema biru tua - putih - cyan.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.navy,
    ).copyWith(
      primary: AppColors.navy,
      onPrimary: AppColors.white,
      secondary: AppColors.cyan,
      onSecondary: AppColors.navyDeep,
      surface: AppColors.white,
      onSurface: AppColors.navyDeep,
      error: AppColors.wrong,
      onError: AppColors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: AppColors.navy,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: AppColors.navyDeep,
          fontWeight: FontWeight.w600,
        ),
      ),
      // Langkah 4 - Transisi navigasi kustom.
      //
      // Catatan: modul meminta PredictiveBackPageTransitionsBuilder untuk
      // Android, namun kelas tersebut baru tersedia sejak Flutter >= 3.22.
      // Flutter yang tersedia di mesin ini adalah 3.19.5, sehingga Android
      // memakai FadeThroughPageTransitionsBuilder dari package animations
      // (sesuai dukungan package/SDK yang tersedia).
      // Bila Flutter di-upgrade ke >= 3.22, ganti baris Android dengan:
      //   TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.linux: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeThroughPageTransitionsBuilder(),
        },
      ),
    );
  }
}
