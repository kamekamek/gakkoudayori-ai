import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pages/newsletter_creation_page.dart';

/// 学校だよりAI - レスポンシブ対応版
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(GakkouDayoriAiApp());
}

class GakkouDayoriAiApp extends StatelessWidget {
  const GakkouDayoriAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Noto Sans JPを基本フォントとして設定
    final baseTextTheme = Theme.of(context).textTheme;

    return MaterialApp(
      title: '学校だよりAI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // Noto Sans JPをアプリ全体のフォントとして設定
        textTheme: GoogleFonts.notoSansJpTextTheme(baseTextTheme).copyWith(
          // 個別のスタイルにも適用
          displayLarge:
              GoogleFonts.notoSansJp(textStyle: baseTextTheme.displayLarge),
          displayMedium:
              GoogleFonts.notoSansJp(textStyle: baseTextTheme.displayMedium),
          displaySmall:
              GoogleFonts.notoSansJp(textStyle: baseTextTheme.displaySmall),
          headlineLarge:
              GoogleFonts.notoSansJp(textStyle: baseTextTheme.headlineLarge),
          headlineMedium:
              GoogleFonts.notoSansJp(textStyle: baseTextTheme.headlineMedium),
          headlineSmall:
              GoogleFonts.notoSansJp(textStyle: baseTextTheme.headlineSmall),
          titleLarge:
              GoogleFonts.notoSansJp(textStyle: baseTextTheme.titleLarge),
          titleMedium:
              GoogleFonts.notoSansJp(textStyle: baseTextTheme.titleMedium),
          titleSmall:
              GoogleFonts.notoSansJp(textStyle: baseTextTheme.titleSmall),
          bodyLarge: GoogleFonts.notoSansJp(textStyle: baseTextTheme.bodyLarge),
          bodyMedium:
              GoogleFonts.notoSansJp(textStyle: baseTextTheme.bodyMedium),
          bodySmall: GoogleFonts.notoSansJp(textStyle: baseTextTheme.bodySmall),
          labelLarge:
              GoogleFonts.notoSansJp(textStyle: baseTextTheme.labelLarge),
          labelMedium:
              GoogleFonts.notoSansJp(textStyle: baseTextTheme.labelMedium),
          labelSmall:
              GoogleFonts.notoSansJp(textStyle: baseTextTheme.labelSmall),
        ),
      ),
      home: NewsletterCreationPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

