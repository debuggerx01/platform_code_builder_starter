@PlatformDetector()
import 'package:flutter/material.dart';
import 'package:platform_code_builder/platform_code_builder.dart';

@PlatformSpec(platformType: PlatformType.desktop)
class Test01 {
  @PlatformSpec(platformType: PlatformType.mac)
  getContainer() {
    return Container();
  }

  @PlatformSpec(platformType: PlatformType.linux, renameTo: "getContainer")
  getContainerTest() {
    return Container();
  }
}

@PlatformSpec(platformType: PlatformType.android, renameTo: "Test01")
class Test02 {
  @PlatformSpec(platformType: PlatformType.vivo)
  getContainer() {
    return Container();
  }

  @PlatformSpec(platformType: PlatformType.xiaomi, renameTo: "getContainer")
  getContainerTest() {
    return Container();
  }
}
