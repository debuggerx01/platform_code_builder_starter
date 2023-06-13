@PlatformDetector()
@PlatformSpec(platformType: PlatformType.ios)
import 'package:flutter/cupertino.dart';
@PlatformSpec(platformType: PlatformType.ios, not: true)
import 'package:flutter/material.dart';
import 'package:platform_code_builder/platform_code_builder.dart';

class PlatformDialog {
  @PlatformSpec(platformType: PlatformType.ios, renameTo: 'show')
  static showForMac(BuildContext context) => showCupertinoDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Cupertino'),
          actions: [
            CupertinoButton(
              onPressed: Navigator.of(context).pop,
              child: const Text('Close'),
            ),
          ],
        ),
      );

  @PlatformSpec(platformType: PlatformType.ios, not: true, renameTo: 'show')
  static show(BuildContext context) => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Material'),
          actions: [
            ElevatedButton(
              onPressed: Navigator.of(context).pop,
              child: const Text('Close'),
            )
          ],
        ),
      );
}
