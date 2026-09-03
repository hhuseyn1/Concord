library;

abstract final class ConcordSpacing {
  static const double base = 4;

  static double unit(double multiplier) => base * multiplier;

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

abstract final class ConcordRadii {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 16;
  static const double full = 9999;
}

abstract final class ConcordMotion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration base = Duration(milliseconds: 200);
}
