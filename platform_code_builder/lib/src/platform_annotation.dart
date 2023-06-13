class PlatformDetector {
  const PlatformDetector();
}

class PlatformSpec {
  final int platformType;
  final String? renameTo;
  final bool not;

  const PlatformSpec({
    required this.platformType,
    this.not = false,
    this.renameTo,
  });
}