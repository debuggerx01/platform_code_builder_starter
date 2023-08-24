import 'dart:io';
import 'dart:math';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:_fe_analyzer_shared/src/scanner/token.dart' show StringToken;

// ignore: implementation_imports
import 'package:analyzer/src/source/source_resource.dart' show FileSource;
import 'package:build/build.dart';
import 'package:chalkdart/chalk.dart';
import 'package:collection/collection.dart';
import 'package:lakos/lakos.dart';
import 'package:platform_code_builder/platform_type.dart';
import 'package:source_gen/source_gen.dart';

import 'platform_annotation.dart';

extension on int {
  bool binaryMatch(int other) => this | other == max(this, other);
}

int parsePlatformTypeExpression(String exp) {
  var parts = exp.split('|');
  return parts
      .map((e) => PlatformType.fromName(e.split('.').last.trim()))
      .reduce((value, ele) => value | ele);
}

class CodeRange {
  final int offset;
  final int end;

  const CodeRange(this.offset, this.end);

  factory CodeRange.formEntry(SyntacticEntity entry) => CodeRange(
        entry.offset,
        entry.end,
      );

  bool contains(CodeRange other) => offset <= other.offset && end >= other.end;
}

class PlatformGenerator extends GeneratorForAnnotation<PlatformDetector> {
  final int platformTypeMaskCode;
  final List<Edge> allImports;

  final _warnedSource = Set<String>();

  PlatformGenerator(
    this.platformTypeMaskCode,
    this.allImports,
  );

  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    var file = (element.source as FileSource).file;
    var hasImport = allImports.where((edge) => file.path.endsWith(edge.to));
    if (hasImport.isNotEmpty && !_warnedSource.contains(file.path)) {
      _warnedSource.add(file.path);
      List<String> exceptions = [''];
      hasImport.forEach((ele) {
        exceptions.add(
            '${chalk.yellow('[WARNING]')} Do not import [lib${ele.to}] directly in [lib${ele.from}], use [lib${ele.to.replaceFirst('.dart', '.p.dart')}] instead!');
      });
      stderr.writeln(exceptions.join('\n'));
    }
    var parseStringResult = parseString(content: file.readAsStringSync());
    var compilationUnit = parseString(content: file.readAsStringSync()).unit;
    var _visitor = _Visitor(platformTypeMaskCode);
    compilationUnit.visitChildren(_visitor);
    var res = parseStringResult.content;

    _visitor._renames.addAll(
      Map.fromIterables(
        _visitor._removes,
        List.generate(
          _visitor._removes.length,
          (index) => '',
        ),
      ),
    );

    var keys = _visitor._renames.keys.sorted((a, b) => b.end.compareTo(a.end));

    CodeRange? lastBigRange;
    for (var key in keys) {
      if (lastBigRange?.contains(key) == true) {
        continue;
      }
      lastBigRange = key;
      res = res.replaceRange(key.offset, key.end, _visitor._renames[key]!);
    }
    return res;
  }
}

typedef HandleRename = Token Function();

class _Visitor extends RecursiveAstVisitor<void> {
  final Set<CodeRange> _removes = {};
  final Map<CodeRange, String> _renames = {};
  final int platformTypeMaskCode;

  _Visitor(this.platformTypeMaskCode);

  _handleNode(AnnotatedNode node, {HandleRename? handleRename}) {
    if (node.metadata.isNotEmpty) {
      var annotation = node.metadata
          .singleWhereOrNull((element) => element.name.name == 'PlatformSpec');
      if (annotation != null && annotation.arguments != null) {
        var _platformType = annotation.arguments!.arguments.firstWhere((arg) =>
            arg is NamedExpression &&
            arg.name.label.toString() == 'platformType');
        var _renameTo = annotation.arguments!.arguments.firstWhereOrNull(
            (arg) =>
                arg is NamedExpression &&
                arg.name.label.toString() == 'renameTo');
        var _not = annotation.arguments!.arguments.firstWhereOrNull((arg) =>
            arg is NamedExpression && arg.name.label.toString() == 'not');
        var isNot = _not == null
            ? false
            : ((_not as NamedExpression).expression as BooleanLiteral).value;

        if (platformTypeMaskCode.binaryMatch(parsePlatformTypeExpression(
                (_platformType as dynamic).expression.toString())) !=
            isNot) {
          if (_renameTo != null) {
            var __renameTo =
                (_renameTo as NamedExpression).expression.toString();
            var nameNode = handleRename?.call();
            if (nameNode != null) {
              _renames[CodeRange.formEntry(nameNode)] =
                  __renameTo.substring(1, __renameTo.length - 1);
            }
          }
        } else {
          _removes.add(CodeRange.formEntry(node));
        }
      }
    }
  }

  @override
  visitClassDeclaration(ClassDeclaration node) {
    _handleNode(
      node,
      handleRename: () => node.name,
    );
    super.visitClassDeclaration(node);
  }

  @override
  visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    _handleNode(
      node.variables,
      handleRename: () => node.variables.variables.first.name,
    );
    super.visitVariableDeclarationStatement(node);
  }

  @override
  visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _handleNode(
      node,
      handleRename: () => node.variables.variables.first.name,
    );
    super.visitTopLevelVariableDeclaration(node);
  }

  @override
  visitFieldDeclaration(FieldDeclaration node) {
    _handleNode(
      node,
      handleRename: () => node.fields.variables.first.name,
    );
    super.visitFieldDeclaration(node);
  }

  @override
  visitImportDirective(ImportDirective node) {
    _handleNode(
      node,
      handleRename: () {
        var literal = (node.uri as SimpleStringLiteral).literal;
        var uriString = literal.toString().substring(1, literal.length - 1);
        return StringToken(TokenType.STRING, uriString, literal.offset + 1);
      },
    );
    super.visitImportDirective(node);
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    _handleNode(
      node,
      handleRename: () => node.name,
    );
    super.visitFunctionDeclaration(node);
  }

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    _handleNode(
      node,
      handleRename: () => node.name,
    );
    super.visitMethodDeclaration(node);
  }
}
