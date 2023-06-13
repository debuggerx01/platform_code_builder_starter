class PlatformType {
  static const xiaomi = 1;

  static const huawei = 2;

  static const oppo = 4;

  static const vivo = 8;

  static const other_android = 16;

  static const iphone = 32;

  static const mac = 64;

  static const windows = 128;

  static const linux = 256;

  static const web = 512;

  static const android = 31;

  static const ios = 96;

  static const mobile = 63;

  static const desktop = 448;

  static const native = 511;

  static int fromName(String name) => {
        'xiaomi': xiaomi,
        'huawei': huawei,
        'oppo': oppo,
        'vivo': vivo,
        'other_android': other_android,
        'iphone': iphone,
        'mac': mac,
        'windows': windows,
        'linux': linux,
        'web': web,
        'android': android,
        'ios': ios,
        'mobile': mobile,
        'desktop': desktop,
        'native': native
      }[name]!;
}
