import 'package:flutter/widgets.dart';

class TayaColors {
  static Color primaryTextColor = const Color.fromRGBO(15, 88, 120, 1);
  static Color secondaryTextColor = const Color.fromRGBO(13, 31, 64, 1);
  static Color tertiaryTextColor = const Color.fromRGBO(12, 29, 63, 1);
  static Color surfaceColor = const Color.fromRGBO(252, 248, 224, 1);
  static Color primaryColor = const Color.fromRGBO(79, 175, 190, 1);
  static LinearGradient primaryGradient = const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color.fromRGBO(77, 161, 181, 1), Color(0xFFFFF8E1)],
    stops: [0.0, 0.6],
  );
}
