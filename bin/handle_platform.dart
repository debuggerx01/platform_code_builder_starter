import 'dart:io';

import 'package:platform_code_builder/platform_type.dart';

main(List<String> args) {
  var platformMaskCode = PlatformType.fromName(args.first);
  File(
    'assets/${getLogoPath(platformMaskCode)}',
  ).copySync('assets/logo.png');
}

String getLogoPath(int platformMaskCode) {
  switch (platformMaskCode) {
    case PlatformType.xiaomi:
      return 'xiaomi.png';
    case PlatformType.huawei:
      return 'huawei.png';
    case PlatformType.oppo:
      return 'oppo.png';
    case PlatformType.vivo:
      return 'vivo.png';
    case PlatformType.iphone:
    case PlatformType.mac:
      return 'apple.png';
    case PlatformType.linux:
      return 'linux.png';
    case PlatformType.windows:
      return 'windows.png';
    case PlatformType.web:
      return 'chrome.png';
  }
  throw Exception('No logo found');
}
