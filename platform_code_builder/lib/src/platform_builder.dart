import 'dart:io';

import 'package:build/build.dart';
import 'package:chalkdart/chalk.dart';
import 'package:code_builder/code_builder.dart' hide LibraryBuilder;
import 'package:dart_style/dart_style.dart';
import 'package:lakos/lakos.dart';
import 'package:platform_code_builder/platform_type.dart';
import 'package:source_gen/source_gen.dart';
import 'package:yaml/yaml.dart';

import 'platform_generator.dart';

Builder platformBuilder(BuilderOptions options) {
  var currentPlatform = buildTypes();
  var selectedPlatform = options.config['platform'] ?? currentPlatform;
  if (selectedPlatform == null) {
    throw Exception('Please specify the platform!');
  }

  var platformMaskCode = PlatformType.fromName(selectedPlatform);

  if (platformMaskCode.toRadixString(2).replaceAll('0', '').length != 1) {
    throw Exception("Union type is not supported!");
  }

  var file = File('bin/handle_platform.dart');
  if (file.existsSync()) {
    var processResult = Process.runSync(
      Platform.executable,
      [
        file.absolute.path,
        selectedPlatform,
      ],
    );
    var out = processResult.stderr.toString();
    if (out.trim().isNotEmpty) {
      print(out);
    }
    out = processResult.stdout;
    if (out.trim().isNotEmpty) {
      print(out);
    }
  }

  var sources = Directory('./lib').listSync(recursive: true);
  var platformSources =
      sources.where((source) => source.path.endsWith('.p.dart'));
  for (var platformSource in platformSources) {
    if (sources.any((source) =>
        source.path == platformSource.path.replaceFirst('.p.dart', '.dart'))) {
      platformSource.deleteSync();
    }
  }

  return LibraryBuilder(
    PlatformGenerator(
      platformMaskCode,
      buildModel(Directory('./lib'), showTree: false).edges,
    ),
    generatedExtension: '.p.dart',
    header: '$defaultFileHeader\n// current platform is [$selectedPlatform]',
    formatOutput: (code) => DartFormatter(fixes: StyleFix.all).format(code),
  );
}

String? buildTypes() {
  var allTypes = <String, int>{};
  var yaml = loadYaml(File('./platform_code_options.yaml').readAsStringSync());
  var platformTypes = (yaml['platform_types'] as YamlList?) ?? [];
  for (int i = 0; i < platformTypes.length; i++) {
    allTypes[platformTypes[i]] = 1 << i;
  }

  var unionTypes = (yaml['union_types'] as YamlMap?) ?? {};
  for (var unionType in unionTypes.entries) {
    allTypes[unionType.key] = unionType.value
        .map((type) => allTypes[type]!)
        .reduce((value, ele) => value | ele);
  }

  final platformTypeClass = Class(
    (b) => b
      ..name = 'PlatformType'
      ..methods.add(
        Method(
          (b) => b
            ..name = 'fromName'
            ..static = true
            ..returns = Reference('int')
            ..requiredParameters.add(
              (ParameterBuilder()
                    ..type = Reference('String')
                    ..name = 'name')
                  .build(),
            )
            ..lambda = true
            ..body = Code(
                '{${allTypes.keys.map((key) => "'$key': $key").join(', ')}}[name]!'),
        ),
      )
      ..fields.addAll(
        allTypes.keys.map(
          (key) => (FieldBuilder()
                ..name = key
                ..static = true
                ..modifier = FieldModifier.constant
                ..assignment = Code(allTypes[key].toString()))
              .build(),
        ),
      ),
  );
  var platformTypeSourceCode =
      DartFormatter().format('${platformTypeClass.accept(DartEmitter())}');
  var file = File('./platform_code_builder/lib/platform_type.dart');
  var platformTypeContent = file.readAsStringSync();
  if (platformTypeContent != platformTypeSourceCode) {
    file.writeAsStringSync(platformTypeSourceCode);
    stderr.writeln(
        '${chalk.yellow('[WARNING]')} [platform_code_builder/lib/platform_type.dart] generated!');
    stderr.writeln(
        '${chalk.yellow('[WARNING]')} Please run the build runner again!');
    exit(1);
  }

  return yaml['current_platform'];
}
