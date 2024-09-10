library flutter_learning_project;

import 'dart:math';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/material.dart';

class Code {
  Color color;
  double x;
  double y;
  double? z;
  double scale;
  int length;
  String text;

  Code(
      {required this.color,
      required this.x,
      required this.y,
      this.z,
      required this.scale,
      required this.length,
      this.text = ""});
}

class CodeRainEffectSetting {
  double? canvasWidth;
  double? canvasHeight;
  final double count;
  final double maxDepth;
  final double maxLength;
  final double minLength;
  double moveSpeed;
  double transformDuration;
  final double fontSize;
  final double hz;

  CodeRainEffectSetting(
      {this.count = 100,
      this.canvasWidth,
      this.canvasHeight,
      this.maxDepth = 500,
      this.moveSpeed = 3,
      this.maxLength = 20,
      this.minLength = 5,
      this.transformDuration = 0.2,
      this.hz = 60,
      this.fontSize = 20});
}

class CodeRainEffect extends StatefulWidget {
  final CodeRainEffectSetting? setting;
  final Widget? child;

  const CodeRainEffect({super.key, this.setting, this.child});

  @override
  State<StatefulWidget> createState() {
    return _CodeRainEffectState();
  }
}

class _CodeRainEffectState extends State<CodeRainEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final List<Code> _codeHolder;
  late final CodeRainEffectSetting _setting;
  late double _transformTime;
  late bool _init;
  late ValueNotifier<bool> _update;

  @override
  void initState() {
    _codeHolder = [];
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _setting = widget.setting ?? CodeRainEffectSetting();
    _init = false;
    _update = ValueNotifier(false);
    _transformTime = 0;
    _setting.transformDuration = _setting.transformDuration * _setting.hz;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      _setting.canvasHeight = _setting.canvasHeight ?? constraints.maxHeight;
      _setting.canvasWidth = _setting.canvasWidth ?? constraints.maxWidth;

      if (!_init) {
        init();
        _init = true;
      }
      Size size = Size(_setting.canvasWidth!, _setting.canvasHeight!);
      return ValueListenableBuilder(
          valueListenable: _update,
          builder: (context, value, child) {
            return CustomPaint(
              size: size,
              painter: _TextEffectPainter(_codeHolder, _setting.fontSize),
              child: Container(
                width: size.width,
                height: size.height,
                child: widget.child,
              ),
            );
          });
    });
  }

  void init() {
    for (int i = 0; i < _setting.count; i++) {
      Random random = Random();
      final scale = 0.5 + random.nextDouble() * 0.5;
      final length = (_setting.minLength +
              random.nextDouble() * (_setting.maxLength - _setting.minLength))
          .floor();
      final text = randomText(length);

      _codeHolder.add(Code(
          x: random.nextDouble() * _setting.canvasWidth!,
          y: random.nextDouble() * _setting.canvasHeight!,
          color: Colors.yellowAccent.withOpacity(random.nextDouble()),
          scale: scale,
          length: length,
          text: text));
    }

    _animationController.addListener(() {
      for (var value in _codeHolder) {
        if (value.y > _setting.canvasHeight!) {
          Random random = Random();
          final scale = 0.3 + random.nextDouble() * 0.7;
          final length = (_setting.minLength +
                  random.nextDouble() *
                      (_setting.maxLength - _setting.minLength))
              .floor();

          final text = randomText(length);
          value.x = random.nextDouble() * _setting.canvasWidth!;
          value.y = 0 - (_setting.fontSize * length * 1.01);
          value.scale = scale;
          value.length = length;
          value.text = text;
        } else {
          value.y += _setting.moveSpeed;
          _transformTime += 1;
          if (_transformTime > _setting.transformDuration) {
            final text = randomText(value.length);
            value.text = text;
            _transformTime = 0;
          }
        }
      }
      _update.value = !_update.value;
    });

    _animationController.repeat();
  }

  String randomText(int length) {
    final random = Random();
    const availableChars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    final randomString = List.generate(length,
            (index) => availableChars[random.nextInt(availableChars.length)])
        .join();

    return randomString;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class _TextEffectPainter extends CustomPainter {
  final List<Code> _textEffectHolder;
  final double fontSize;

  _TextEffectPainter(this._textEffectHolder, this.fontSize);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, paint..color = Colors.black);
    canvas.clipRect(Offset.zero & size);
    for (var value in _textEffectHolder) {
      ParagraphBuilder paragraphBuilder = ParagraphBuilder(ParagraphStyle());
      final style = ui.TextStyle(
        color: value.color,
        fontSize: fontSize * value.scale,
      );
      paragraphBuilder.pushStyle(style);

      for (int i = 0; i < value.text.length; i++) {
        final c = value.text[i];
        final style = ui.TextStyle(
          color: value.color.withOpacity(i / value.text.length),
          fontSize: fontSize * value.scale,
        );
        paragraphBuilder.pop();
        paragraphBuilder.pushStyle(style);
        paragraphBuilder.addText(c);
      }
      ParagraphConstraints paragraphConstraints =
          const ParagraphConstraints(width: 1);
      Paragraph paragraph = paragraphBuilder.build()
        ..layout(paragraphConstraints);
      canvas.drawParagraph(paragraph, Offset(value.x, value.y));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
