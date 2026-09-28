import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color primary;
  final Color secondary;
  final Color background;
  final Color cardColor;
  final Color surfaceColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color highPriority;
  final Color mediumPriority;
  final Color lowPriority;
  final Color income;
  final Color expense;
  final Color gradientTop;
  final Color gradientBottom;
  final Color glow;

  const AppColors({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.cardColor,
    required this.surfaceColor,
    this.textPrimary = Colors.white,
    this.textSecondary = const Color(0xFF9AA0B4),
    this.highPriority = const Color(0xFFFF6B6B),
    this.mediumPriority = const Color(0xFFFFD93D),
    this.lowPriority = const Color(0xFF6BCB77),
    this.income = const Color(0xFF6BCB77),
    this.expense = const Color(0xFFFF6B6B),
    this.gradientTop = const Color(0xFF18123A),
    this.gradientBottom = const Color(0xFF080B16),
    this.glow = const Color(0xFF6C63FF),
  });

  // ─── Themes ───────────────────────────────────────────────────────────────
  static const obsidian = AppColors(
    primary: Color(0xFF6C63FF),
    secondary: Color(0xFF00D2FF),
    background: Color(0xFF080B16),
    cardColor: Color(0xFF171C33),
    surfaceColor: Color(0xFF111527),
    gradientTop: Color(0xFF1B1140),
    gradientBottom: Color(0xFF060910),
    glow: Color(0xFF6C63FF),
  );

  static const aurora = AppColors(
    primary: Color(0xFF00E5A0),
    secondary: Color(0xFF7C4DFF),
    background: Color(0xFF05100D),
    cardColor: Color(0xFF0F241D),
    surfaceColor: Color(0xFF0A1814),
    highPriority: Color(0xFFFF6B6B),
    mediumPriority: Color(0xFFFFC93D),
    lowPriority: Color(0xFF3DDC97),
    income: Color(0xFF3DDC97),
    expense: Color(0xFFFF6B6B),
    gradientTop: Color(0xFF0A3529),
    gradientBottom: Color(0xFF04100C),
    glow: Color(0xFF00E5A0),
  );

  static const midnight = AppColors(
    primary: Color(0xFF6B7BFF),
    secondary: Color(0xFF81D4FA),
    background: Color(0xFF090C1E),
    cardColor: Color(0xFF151B3A),
    surfaceColor: Color(0xFF0E132E),
    gradientTop: Color(0xFF1C2560),
    gradientBottom: Color(0xFF090C1E),
    glow: Color(0xFF6B7BFF),
  );

  static const ocean = AppColors(
    primary: Color(0xFF00B0FF),
    secondary: Color(0xFF69F0AE),
    background: Color(0xFF07121A),
    cardColor: Color(0xFF0F2030),
    surfaceColor: Color(0xFF0B1823),
    gradientTop: Color(0xFF0C3A58),
    gradientBottom: Color(0xFF061018),
    glow: Color(0xFF00B0FF),
  );

  static const sunset = AppColors(
    primary: Color(0xFFFF7E5F),
    secondary: Color(0xFFFEB47B),
    background: Color(0xFF190E14),
    cardColor: Color(0xFF2A1720),
    surfaceColor: Color(0xFF20111A),
    mediumPriority: Color(0xFFFDA14A),
    gradientTop: Color(0xFF401727),
    gradientBottom: Color(0xFF190E14),
    glow: Color(0xFFFF7E5F),
  );

  static const glass = AppColors(
    primary: Color(0xFF00C2FF),
    secondary: Color(0xFFB57EFF),
    background: Color(0xFF0D0E1C),
    cardColor: Color(0xFF232539),
    surfaceColor: Color(0xFF161826),
    gradientTop: Color(0xFF291F52),
    gradientBottom: Color(0xFF0B0C16),
    glow: Color(0xFF00C2FF),
  );

  static const minimalWhite = AppColors(
    primary: Color(0xFF5B5BD6),
    secondary: Color(0xFF00B8D4),
    background: Color(0xFFF4F6FB),
    cardColor: Color(0xFFFFFFFF),
    surfaceColor: Color(0xFFE9EDF5),
    textPrimary: Color(0xFF1A1D29),
    textSecondary: Color(0xFF6B7280),
    highPriority: Color(0xFFE5484D),
    mediumPriority: Color(0xFFF5A623),
    lowPriority: Color(0xFF30A46C),
    income: Color(0xFF30A46C),
    expense: Color(0xFFE5484D),
    gradientTop: Color(0xFFDEE4FF),
    gradientBottom: Color(0xFFF4F6FB),
    glow: Color(0xFF5B5BD6),
  );

  static const forest = AppColors(
    primary: Color(0xFF2DD4A7),
    secondary: Color(0xFFA3E635),
    background: Color(0xFF06120E),
    cardColor: Color(0xFF0F241B),
    surfaceColor: Color(0xFF0A1A14),
    mediumPriority: Color(0xFFFBBF24),
    income: Color(0xFF2DD4A7),
    gradientTop: Color(0xFF123B2C),
    gradientBottom: Color(0xFF06120E),
    glow: Color(0xFF2DD4A7),
  );

  static const rose = AppColors(
    primary: Color(0xFFFF5FA2),
    secondary: Color(0xFF9D4EDD),
    background: Color(0xFF1A0912),
    cardColor: Color(0xFF2A1220),
    surfaceColor: Color(0xFF210D19),
    income: Color(0xFF7CF29C),
    gradientTop: Color(0xFF4A1440),
    gradientBottom: Color(0xFF190811),
    glow: Color(0xFFFF5FA2),
  );

  static const amber = AppColors(
    primary: Color(0xFFFFB020),
    secondary: Color(0xFFFF7849),
    background: Color(0xFF1A1006),
    cardColor: Color(0xFF2B1C0D),
    surfaceColor: Color(0xFF211508),
    income: Color(0xFF7CF29C),
    gradientTop: Color(0xFF4A3010),
    gradientBottom: Color(0xFF180E05),
    glow: Color(0xFFFFB020),
  );

  static const nebula = AppColors(
    primary: Color(0xFFB388FF),
    secondary: Color(0xFF40C4FF),
    background: Color(0xFF12091F),
    cardColor: Color(0xFF1E1236),
    surfaceColor: Color(0xFF190E2A),
    gradientTop: Color(0xFF352264),
    gradientBottom: Color(0xFF100818),
    glow: Color(0xFFB388FF),
  );

  static const mint = AppColors(
    primary: Color(0xFF00897B),
    secondary: Color(0xFF26A69A),
    background: Color(0xFFF2FBF7),
    cardColor: Color(0xFFFFFFFF),
    surfaceColor: Color(0xFFE3F5EF),
    textPrimary: Color(0xFF102A24),
    textSecondary: Color(0xFF5B7B72),
    income: Color(0xFF2E9E5B),
    expense: Color(0xFFD64550),
    gradientTop: Color(0xFFD1F2E6),
    gradientBottom: Color(0xFFF2FBF7),
    glow: Color(0xFF00897B),
  );

  static const slate = AppColors(
    primary: Color(0xFF607D8B),
    secondary: Color(0xFF90A4AE),
    background: Color(0xFFF6F7F9),
    cardColor: Color(0xFFFFFFFF),
    surfaceColor: Color(0xFFE9EDF1),
    textPrimary: Color(0xFF15202B),
    textSecondary: Color(0xFF64748B),
    income: Color(0xFF2E7D32),
    expense: Color(0xFFC62828),
    gradientTop: Color(0xFFE0E7EE),
    gradientBottom: Color(0xFFF6F7F9),
    glow: Color(0xFF546E7A),
  );

  static const cherry = AppColors(
    primary: Color(0xFFFF5252),
    secondary: Color(0xFFFF8A65),
    background: Color(0xFF1C0808),
    cardColor: Color(0xFF2C1110),
    surfaceColor: Color(0xFF230C0B),
    income: Color(0xFF69F0AE),
    gradientTop: Color(0xFF4A1A14),
    gradientBottom: Color(0xFF190706),
    glow: Color(0xFFFF5252),
  );

  static const themes = [
    obsidian,
    aurora,
    midnight,
    ocean,
    sunset,
    glass,
    minimalWhite,
    forest,
    rose,
    amber,
    nebula,
    mint,
    slate,
    cherry,
  ];

  static const themeNames = [
    'Obsidian',
    'Aurora',
    'Midnight',
    'Ocean',
    'Sunset',
    'Glass',
    'Minimal',
    'Forest',
    'Rose',
    'Amber',
    'Nebula',
    'Mint',
    'Slate',
    'Cherry',
  ];

  bool get isLight =>
      ThemeData.estimateBrightnessForColor(background) == Brightness.light;

  // ─── Extension plumbing ──────────────────────────────────────────────────
  @override
  AppColors copyWith({
    Color? primary,
    Color? secondary,
    Color? background,
    Color? cardColor,
    Color? surfaceColor,
    Color? textPrimary,
    Color? textSecondary,
    Color? lowPriority,
    Color? mediumPriority,
    Color? highPriority,
    Color? income,
    Color? expense,
    Color? gradientTop,
    Color? gradientBottom,
    Color? glow,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      background: background ?? this.background,
      cardColor: cardColor ?? this.cardColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      lowPriority: lowPriority ?? this.lowPriority,
      mediumPriority: mediumPriority ?? this.mediumPriority,
      highPriority: highPriority ?? this.highPriority,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      gradientTop: gradientTop ?? this.gradientTop,
      gradientBottom: gradientBottom ?? this.gradientBottom,
      glow: glow ?? this.glow,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      background: Color.lerp(background, other.background, t)!,
      cardColor: Color.lerp(cardColor, other.cardColor, t)!,
      surfaceColor: Color.lerp(surfaceColor, other.surfaceColor, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      highPriority: Color.lerp(highPriority, other.highPriority, t)!,
      mediumPriority: Color.lerp(mediumPriority, other.mediumPriority, t)!,
      lowPriority: Color.lerp(lowPriority, other.lowPriority, t)!,
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      gradientTop: Color.lerp(gradientTop, other.gradientTop, t)!,
      gradientBottom: Color.lerp(gradientBottom, other.gradientBottom, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
    );
  }
}

class AppTheme {
  static ThemeData build(AppColors c) {
    final scheme = ColorScheme.fromSeed(
      seedColor: c.primary,
      brightness: c.isLight ? Brightness.light : Brightness.dark,
    ).copyWith(
      secondary: c.secondary,
      surface: c.surfaceColor,
      onSurface: c.textPrimary,
      primary: c.primary,
      onPrimary: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: c.isLight ? Brightness.light : Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      cardColor: c.cardColor,
      splashColor: c.primary.withValues(alpha: 0.12),
      extensions: [c],
      textTheme: ThemeData(
        brightness: c.isLight ? Brightness.light : Brightness.dark,
      ).textTheme.apply(
        bodyColor: c.textPrimary,
        displayColor: c.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: c.textPrimary,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: DividerThemeData(color: c.textSecondary.withValues(alpha: 0.12)),
    );
  }

  /// Colors helper for the current context theme.
  static AppColors of(BuildContext context) {
    return Theme.of(context).extension<AppColors>()!;
  }
}