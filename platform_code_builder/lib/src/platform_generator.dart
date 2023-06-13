import 'dart:math';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

// ignore: implementation_imports
import 'package:analyzer/src/source/source_resource.dart' show FileSource;
import 'package:build/build.dart';
import 'package:collection/collection.dart';
import 'package:dart_style/dart_style.dart';
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

class PlatformGenerator extends GeneratorForAnnotation<PlatformDetector> {
  final int platformTypeMaskCode;

  PlatformGenerator(this.platformTypeMaskCode);

  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    var compilationUnit = parseString(
            content: (element.source as FileSource).file.readAsStringSync())
        .unit;
    var _visitor = _Visitor(platformTypeMaskCode);
    compilationUnit.visitChildren(_visitor);
    var res = compilationUnit.toSource();
    for (var ele in _visitor._removes) {
      res = res.replaceFirst(ele, '\n');
    }
    _visitor._renames.forEach((from, to) {
      res = res.replaceFirst(from, '\n$to\n');
    });
    return DartFormatter(fixes: StyleFix.all).format(res);
  }
}

typedef HandleRename = String Function(String source, String renameTo);

class _Visitor<R> extends RecursiveAstVisitor<R> {
  final Set<String> _removes = {};
  final Map<String, String> _renames = {};
  final int platformTypeMaskCode;

  _Visitor(this.platformTypeMaskCode);

  _handleNode(AnnotatedNode node,
      {HandleRename? handleRename, useParent = false}) {
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

        var _source = (useParent ? node.parent! : node).toString();
        if (platformTypeMaskCode.binaryMatch(parsePlatformTypeExpression(
                (_platformType as dynamic).expression.toString())) !=
            isNot) {
          if (_renameTo != null) {
            var __renameTo =
                (_renameTo as NamedExpression).expression.toString();
            var renamedSource = handleRename?.call(
                _source, __renameTo.substring(1, __renameTo.length - 1));
            if (renamedSource != null) {
              _renames[_source] = renamedSource;
            }
          }
        } else {
          _removes.add(_source);
        }
      }
    }
  }

  @override
  R? visitClassDeclaration(ClassDeclaration node) {
    _handleNode(
      node,
      handleRename: (source, renameTo) => source.replaceFirst(
          'class ${node.name.toString()}', 'class $renameTo'),
    );
    return super.visitClassDeclaration(node);
  }

  @override
  R? visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    _handleNode(
      node.variables,
      useParent: true,
      handleRename: (source, renameTo) => source.replaceFirst(
          node.variables.variables.first.name.toString(), renameTo),
    );
    return super.visitVariableDeclarationStatement(node);
  }

  @override
  R? visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _handleNode(
      node,
      handleRename: (source, renameTo) => source.replaceFirst(
          node.variables.variables.first.name.toString(), renameTo),
    );
    return super.visitTopLevelVariableDeclaration(node);
  }

  @override
  R? visitFieldDeclaration(FieldDeclaration node) {
    _handleNode(
      node,
      handleRename: (source, renameTo) => source.replaceFirst(
          node.fields.variables.first.name.toString(), renameTo),
    );
    return super.visitFieldDeclaration(node);
  }

  @override
  R? visitImportDirective(ImportDirective node) {
    _handleNode(
      node,
      handleRename: (source, renameTo) =>
          source.replaceFirst(node.uri.toSource(), "'$renameTo'"),
    );
    return super.visitImportDirective(node);
  }

  @override
  R? visitFunctionDeclaration(FunctionDeclaration node) {
    _handleNode(
      node,
      handleRename: (source, renameTo) =>
          source.replaceFirst(node.name.toString(), renameTo),
    );
    return super.visitFunctionDeclaration(node);
  }

  @override
  R? visitMethodDeclaration(MethodDeclaration node) {
    _handleNode(
      node,
      handleRename: (source, renameTo) =>
          source.replaceFirst(node.name.toString(), renameTo),
    );
    return super.visitMethodDeclaration(node);
  }
}
