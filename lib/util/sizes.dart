import 'package:flutter/widgets.dart';

const kBigScreenMinWidth = 500;
const kFormPadding = 60;

bool isSmallScreen(BuildContext context) =>
    MediaQuery.of(context).size.width < kBigScreenMinWidth;

double formWidth(BuildContext context) {
  if (isSmallScreen(context)) {
    return MediaQuery.of(context).size.width - kFormPadding;
  } else {
    return MediaQuery.of(context).size.width / 2;
  }
}
