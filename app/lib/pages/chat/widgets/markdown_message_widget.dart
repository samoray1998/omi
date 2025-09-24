import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:omi/utils/styles.dart';

Widget getMarkdownWidget(BuildContext context, String content) {
  var style = TextStyle(color: TayaColors.secondaryTextColor, fontSize: 16, height: 1.5);
  return MarkdownBody(
    selectable: false,
    shrinkWrap: true,
    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      listBullet: style.copyWith(
        backgroundColor: Colors.transparent,
        color: TayaColors.secondaryTextColor,
      ),
      a: style,
      p: style.copyWith(
        height: 1.5,
      ),
      pPadding: const EdgeInsets.only(bottom: 12),
      blockquote: style.copyWith(
        backgroundColor: Colors.transparent,
        color: TayaColors.secondaryTextColor,
      ),
      blockquoteDecoration: BoxDecoration(
        color: Color(0xFF35343B),
        borderRadius: BorderRadius.circular(4),
      ),
      code: style.copyWith(
        backgroundColor: Colors.transparent,
        decoration: TextDecoration.none,
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
    ),
    data: content,
  );
}
