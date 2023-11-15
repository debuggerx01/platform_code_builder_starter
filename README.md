# platform_code_builder_starter

利用`source_gen`自定义代码生成器，解决跨平台开发时差异代码替换的问题。

详细说明及分析请看：
- [在 flutter 中利用 source_gen 实现条件编译（上）](https://www.debuggerx.com/2022/04/17/conditional-compilation-using-source-gen-in-flutter-1/)
- [在 flutter 中利用 source_gen 实现条件编译（中）](https://www.debuggerx.com/2022/06/19/conditional-compilation-using-source-gen-in-flutter-2/)
- [在 flutter 中利用 source_gen 实现条件编译（下）](https://www.debuggerx.com/2023/06/20/conditional-compilation-using-source-gen-in-flutter-3/)

# DEMO使用方法

1. clone本仓库
2. 下载依赖`dart pub get`
3. 运行代码生成：

    ```shell
    dart run build_runner build
    ```

4. 查看`lib`目录下生成的`*.p.dart`代码，或直接运行项目查看效果

> tips：可以用 `flutter create ./` 命令创建支持各个平台运行的模板代码

## 指定生成代码平台的方法

### 方法一

1. 修改`platform_code_options.yaml`，修改最后一行`current_platform: `的值：

    ```yaml
    current_platform: xiaomi
    ```

   > 当前可选: `xiaomi`、`huawei`、`oppo`、`vivo`、`other_android`、`iphone`、`mac`、`windows`、`linux`
   、`web`

2. 运行代码生成：

    ```shell
    dart run build_runner build
    ```

### 方法二

直接在代码生成命令中加入options覆盖参数：

- mac:

    ```shell
    dart run build_runner build --define "platform_code_builder:platform_builder=platform=mac"
    ```

- web:

    ```shell
    dart run build_runner build --define "platform_code_builder:platform_builder=platform=web"
    ```

> 注意：代码生成时选择的 platform 必须是 `platform_code_options.yaml` 中 `platform_types` 定义的“基本平台类型”

# 注解使用说明

参考[source_gen](https://pub.flutter-io.cn/packages/source_gen)的文档和用例，需要使用注解来指定需要代码生成器处理的源码和元素。

## @PlatformDetector

这是用来标记需要进行代码替换的注解标记，无需解释，放在需要处理的代码源文件的第一行即可

## @PlatformSpec

这是用来标记需要替换的元素的注解，注解签名为：

```dart
const PlatformSpec({
  required this.platformType,
  this.not = false,
  this.renameTo,
});

```

其中：

- `platformType`必须指定，当与当前指定的PlatformType不一致时，生成的代码中该注解所标记的代码块将被移除；
- `not`为可选，默认为`false`，当指定为`true`时表示当前指定的PlatformType与注解的platformType一致时，代码块将被移除；
- `renameTo`为可选，当改注解标记的代码块需要保留时，如果指定了`renameTo`，那么根据代码块类型的不同，将进行相应的替换

> 如果想要一次指定多个`platformType`，有两种选择
> 1. 在`platform_code_options.yaml`的`union_types`下增加组合平台类型，定义时请注意定义顺序
> 2. 使用`|`操作符组合，例如：@PlatformSpec(platformType: PlatformType.android | PlatformType.ios)

## 增加 PlatformType 的方法

在`platform_code_options.yaml`中增加类型：

### 基本平台类型
在`platform_types`节点下以数组形式声明所有基本平台类型，形如：
```yaml
platform_types:
  - android
  - ios
  - desktop
  - web
```
### 组合平台类型
在`union_types`节点下以字典形式声明组合平台类型，形如：
```yaml
union_types:
  mobile: [android, ios]
  native: [mobile, desktop]  # 注意，由于上面先定义了mobile类型，所以这里才可以使用
```

# 当前支持替换的语法元素

- 类定义（ClassDeclaration）

- 变量定义（VariableDeclaration）

- 顶层变量定义（TopLevelVariableDeclaration）

- 字段定义（FieldDeclaration）

- import指令（ImportDirective）

- 函数定义（FunctionDeclaration）

- 方法定义（MethodDeclaration）

  > 更多语法支持可以通过在`lib/builder/platform_generator.dart`中增加`visitXXX`系列的方法覆写来实现。

# 向项目中集成的步骤
1. clone本仓库
2. 复制`platform_code_builder`目录至目标项目的根目录
3. 编辑目标项目的`pubspec.yaml`，添加如下内容
    ```yaml
    dependencies:
      ……
      platform_code_builder:
        path: platform_code_builder
    
    dev_dependencies:
      ……
      build_runner: ^<latest_version>
    ```
4. 在项目根目录创建`platform_code_options.yaml`，根据项目需要定义所有平台类型
5. 定义完成后，在项目根目录依次如下命令：
    ```shell
    dart pub get
    dart run build_runner build
    ```
   完成后请检查生成的`platform_code_builder/lib/platform_type.dart`文件内容无误
6. 在项目源码中使用注解标记不同平台下的代码，参考[注解使用说明](#注解使用说明)
7. (可选)，创建`bin/handle_platform.dart`，用于为指定平台执行特殊操作，基础代码如下：
    ```dart
    import 'package:platform_code_builder/platform_type.dart';
    
    main(List<String> args) {
      var platformMaskCode = PlatformType.fromName(args.first);
      /// 在这里判断platformMaskCode执行所需操作
    }

    ```
8. 运行` run build_runner build`或`dart run build_runner watch`，并将项目中相关的import源码路径更改为生成的`*.p.dart`
9. 运行Flutter/Dart项目，检查结果是否符合预期
