@PlatformDetector()
import 'package:platform_code_builder/platform_code_builder.dart';

@PlatformSpec(platformType: PlatformType.xiaomi, renameTo: 'current')
const String currentIsXiaomi = 'xiaomi';

@PlatformSpec(platformType: PlatformType.huawei, renameTo: 'current')
const String currentIsHW = 'huawei';

@PlatformSpec(platformType: PlatformType.oppo, renameTo: 'current')
const String currentIsOppo = 'oppo';

@PlatformSpec(platformType: PlatformType.vivo, renameTo: 'current')
const String currentIsVivo = 'vivo';

@PlatformSpec(platformType: PlatformType.other_android, renameTo: 'current')
const String currentIsOA = 'other_android';

@PlatformSpec(platformType: PlatformType.iphone, renameTo: 'current')
const String currentIsIP = 'iphone';

@PlatformSpec(platformType: PlatformType.linux, renameTo: 'current')
const String currentIsLinux = 'linux';

@PlatformSpec(platformType: PlatformType.mac, renameTo: 'current')
const String currentIsMac = 'mac';

@PlatformSpec(platformType: PlatformType.windows, renameTo: 'current')
const String currentIsWin = 'windows';

@PlatformSpec(platformType: PlatformType.web, renameTo: 'current')
const String currentIsWeb = 'web';
