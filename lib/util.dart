import 'package:flutter/material.dart';

class Util{
  static double getScaleWidth(BuildContext context) {
    const standardDeviceWidth = 402;
    final deviceWidth = MediaQuery.of(context).size.width;
    final changedValue = deviceWidth / standardDeviceWidth;
    return changedValue;
  }

  static double getScaleHeight(BuildContext context) {
    const standardDeviceHeight = 874;
    final deviceHeight = MediaQuery.of(context).size.height;
    final changedValue = deviceHeight / standardDeviceHeight;
    return changedValue;
  }
}