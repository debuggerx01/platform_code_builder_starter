@PlatformDetector()
import 'package:flutter/material.dart';
import 'package:platform_code_builder/platform_code_builder.dart';
import 'package:platform_code_builder_starter/current_platform.p.dart' as current_platform;
import 'package:platform_code_builder_starter/platform_dialog.p.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @PlatformSpec(platformType: PlatformType.desktop | PlatformType.web, renameTo: 'scale')
  final scaleForDesktopAndWeb = 2.0;

  @PlatformSpec(platformType: PlatformType.desktop | PlatformType.web, not: true)
  final scale = 1.0;

  @PlatformSpec(platformType: PlatformType.android, renameTo: 'themeColor')
  final themeColorForAndroid = Colors.blue;

  @PlatformSpec(platformType: PlatformType.ios, renameTo: 'themeColor')
  final themeColorForIos = Colors.cyan;

  @PlatformSpec(platformType: PlatformType.android | PlatformType.ios, not: true)
  final themeColor = Colors.teal;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter platform code Demo',
      theme: ThemeData(
        primarySwatch: themeColor,
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaleFactor: scale,
        ),
        child: child!,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset('assets/logo.png'),
            const Text('Current platform is ${current_platform.current}'),
            TextButton(
              onPressed: () {
                PlatformDialog.show(context);
              },
              child: const Text('Show platform specific dialog'),
            ),
          ],
        ),
      ),
    );
  }
}
