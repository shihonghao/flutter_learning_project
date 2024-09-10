library flutter_learning_project;

import 'dart:math';

import 'package:flutter/material.dart';

class StartEffectController {
  bool _run = false;
  bool _runRotation = false;

  get run => _run;

  get runRotation => _runRotation;

  void pause() {
    _run = false;
  }

  void active() {
    _run = true;
  }

  void rotation() {
    _runRotation = true;
  }

  void pauseRotation() {
    _runRotation = false;
  }
}

class StarEffectSetting {
  double canvasWidth;
  double canvasHeight;
  bool autoResize;
  double? autoResizeMinWidth;
  double? autoResizeMaxWidth;
  double? autoResizeMinHeight;
  double? autoResizeMaxHeight;
  bool addMouseControls;
  bool addTouchControls;
  bool hideContextMenu;
  int starCount;
  int starBgCount;
  Color starBgColor;
  int starBgColorRangeMin;
  int starBgColorRangeMax;
  Color starColor;
  int starColorRangeMin;
  int starColorRangeMax;
  Color starFieldBackgroundColor;
  double starDirection;
  double starSpeed;
  double starSpeedAnimationDuration;
  double starSpeedMax;
  double starSpeedMin;
  double starFov;
  double starFovMax;
  double starFovMin;
  double starFovAnimationDuration;
  bool starRotationPermission;
  double starRotationDirection;
  double starRotationSpeed;
  double starRotationSpeedMin;
  double starRotationSpeedMax;
  double starRotationAnimationDuration;
  double starWarpLineLength;
  double starWarpTunnelDiameter;
  double starFollowMouseSensitivity;
  bool starFollowMouseXAxis;
  bool starFollowMouseYAxis;
  double hz;

  StarEffectSetting(
      {this.canvasWidth = 480,
      this.canvasHeight = 480,
      this.autoResize = false,
      this.autoResizeMinWidth,
      this.autoResizeMaxWidth,
      this.autoResizeMinHeight,
      this.autoResizeMaxHeight,
      this.addMouseControls = true,
      this.addTouchControls = true,
      this.hideContextMenu = true,
      this.starCount = 6666,
      this.starBgCount = 2222,
      this.starBgColor = const Color.fromRGBO(255, 255, 255, 1),
      this.starBgColorRangeMin = 10,
      this.starBgColorRangeMax = 40,
      this.starColor = const Color.fromRGBO(255, 255, 255, 1),
      this.starColorRangeMin = 10,
      this.starColorRangeMax = 100,
      this.starFieldBackgroundColor = const Color.fromRGBO(0, 0, 0, 1),
      this.starDirection = 1,
      this.starSpeed = 20,
      this.starSpeedMax = 200,
      this.starFov = 300,
      this.starFovMin = 200,
      this.starRotationSpeed = 0.0,
      this.starRotationSpeedMax = 1.0,
      this.starWarpLineLength = 2.0,
      this.starWarpTunnelDiameter = 100,
      this.starFollowMouseSensitivity = 0.5,
      this.starFollowMouseXAxis = true,
      this.starFollowMouseYAxis = true,
      this.starFovAnimationDuration = 2,
      this.starRotationPermission = true,
      this.starRotationDirection = 1,
      this.starRotationAnimationDuration = 2,
      this.hz = 60})
      : starRotationSpeedMin = starRotationSpeed,
        starSpeedMin = starSpeed,
        starFovMax = starFov,
        starSpeedAnimationDuration = starFovAnimationDuration;
}

class StarEffect extends StatefulWidget {
  final StarEffectSetting? setting;
  final StartEffectController startEffectController;
  final Widget? child;

  const StarEffect(
      {super.key,
      this.setting,
      required this.startEffectController,
      this.child});

  @override
  State createState() => _StarEffectState();
}

class _StarEffectState extends State<StarEffect>
    with SingleTickerProviderStateMixin {
  late StartEffectController _startEffectController;
  late StarEffectSetting _setting;
  late AnimationController _controller;
  late Size _size;
  late List<Star> _starHolder;
  late List<Star> _starBgHolder;
  late double _starSpeedAnimationTime;
  late double _starFovAnimationTime;
  late double _starRotation;
  late double _starRotationAnimationTime;
  late double _starDistance;
  late double _starRotationSpeed;
  late double _starSpeed;
  late double _starFov;
  late List<List<Color>> _starColorLookupTable;
  late List<List<Color>> _starBgColorLookupTable;
  late Offset _center;
  late double _warpSpeedValue;
  late Offset _touchPos;
  late ValueNotifier<bool> _update;

  var paused = false;

  @override
  void initState() {
    super.initState();
    _update = ValueNotifier(false);
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _startEffectController = widget.startEffectController;
    _setting = widget.setting ?? StarEffectSetting();
    _controller.repeat();
    _size = Size(_setting.canvasWidth, _setting.canvasHeight);
    _starHolder = [];
    _starBgHolder = [];
    _starSpeed = _setting.starSpeed;
    _starFov = _setting.starFov;
    _starRotationSpeed = _setting.starRotationSpeed;

    _setting.starFovAnimationDuration =
        _setting.starFovAnimationDuration * _setting.hz;
    _setting.starSpeedAnimationDuration = _setting.starFovAnimationDuration;
    _setting.starRotationAnimationDuration =
        _setting.starRotationAnimationDuration * _setting.hz;

    _starFovAnimationTime = _setting.starFovAnimationDuration;
    _starSpeedAnimationTime = 0;
    _starRotationAnimationTime = 0;
    _starRotation = 0.0;

    _starDistance = 8000;
    _starColorLookupTable = [];
    _starBgColorLookupTable = [];
    _center = Offset(_setting.canvasWidth / 2, _setting.canvasHeight / 2);
    _touchPos = _center;
    _warpSpeedValue = 0;

    addColorLookupTable(
        _starColorLookupTable,
        _setting.starColorRangeMin,
        _setting.starColorRangeMax,
        _setting.starFieldBackgroundColor,
        _setting.starColor);
    addColorLookupTable(
        _starBgColorLookupTable,
        _setting.starBgColorRangeMin,
        _setting.starBgColorRangeMax,
        _setting.starFieldBackgroundColor,
        _setting.starBgColor);

    addStars();

    _controller.addListener(() {
      Future.delayed(Duration(milliseconds: (1000 / 60).round()), () {
        render();
        _update.value = !_update.value;
      });
    });

    _controller.repeat();
  }

  void addColorLookupTable(
      List<List<Color>> colorLookupTable,
      int colorRangeMin,
      int colorRangeMax,
      Color colorRGBStart,
      Color colorRGBEnd) {
    var colorHexStart =
        rgbToHex(colorRGBStart.red, colorRGBStart.green, colorRGBStart.blue);
    var colorHexEnd =
        rgbToHex(colorRGBEnd.red, colorRGBEnd.green, colorRGBEnd.blue);

    var colorRange = <String>[];
    var colorEndValues = <String>[];

    double percent;

    for (int i = 0, l = 100; i <= l; i++) {
      percent = i / 100;
      colorRange.add(shadeBlend(percent, colorHexStart, colorHexEnd));
    }

    for (int i = 0, l = colorRangeMax - colorRangeMin; i <= l; i++) {
      var index = i + colorRangeMin;

      colorEndValues.add(colorRange[index]);
    }

    for (int i = 0, l = colorEndValues.length; i < l; i++) {
      List<Color> range = [];

      for (int j = 0, k = 100; j <= k; j++) {
        percent = j / 100;
        List<int> rgb =
            hexToRgb(shadeBlend(percent, colorHexStart, colorEndValues[i]));
        range.add(Color.fromRGBO(rgb[0], rgb[1], rgb[2], 1));
      }

      colorLookupTable.add(range);
    }
  }

  // 将 RGB 转换为 Hex
  String rgbToHex(int r, int g, int b) {
    return '#${(r << 16 | g << 8 | b).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

// 将 Hex 转换为 RGB
  List<int> hexToRgb(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 3) {
      hex = '${hex[0]}${hex[0]}${hex[1]}${hex[1]}${hex[2]}${hex[2]}';
    }
    return [
      int.parse(hex.substring(0, 2), radix: 16),
      int.parse(hex.substring(2, 4), radix: 16),
      int.parse(hex.substring(4, 6), radix: 16)
    ];
  }

// 混合两个颜色
  String shadeBlend(double percent, String colorHexStart, String colorHexEnd) {
    var start = hexToRgb(colorHexStart);
    var end = hexToRgb(colorHexEnd);

    var r = (start[0] * (1 - percent)) + (end[0] * percent);
    var g = (start[1] * (1 - percent)) + (end[1] * percent);
    var b = (start[2] * (1 - percent)) + (end[2] * percent);

    return rgbToHex(r.round(), g.round(), b.round());
  }

  void addStars() {
    addStarBg();

    final random = Random();
    for (int i = 0; i < _setting.starCount; i++) {
      final starPosition =
          getStarPosition(_setting.starWarpTunnelDiameter, 10000);
      final z = random.nextDouble() * _starDistance;
      final colorIndex =
          (_starColorLookupTable.length * random.nextDouble()).floor();

      final colorTable = _starColorLookupTable[colorIndex];
      final distanceTotal =
          (_starDistance + _setting.starFov).round().toDouble();
      final star = Star(
          x: starPosition.dx,
          y: starPosition.dy,
          z: z,
          ox: starPosition.dx,
          oy: starPosition.dy,
          colorLookupTable: colorTable,
          distance: _starDistance - z,
          distanceTotal: distanceTotal,
          color: colorTable[(_starDistance / distanceTotal * 100).floor()],
          colorIndex: colorIndex);
      _starHolder.add(star);
    }
  }

  void addStarBg() {
    final random = Random();
    for (int i = 0; i < _setting.starBgCount; i++) {
      final starPosition = getStarPosition(0, 20000);
      final z = random.nextDouble() * _starDistance;
      final colorIndex =
          (_starBgColorLookupTable.length * random.nextDouble()).floor();
      final colorTable = _starBgColorLookupTable[colorIndex];
      final star = Star(
          x: starPosition.dx,
          y: starPosition.dy,
          z: z,
          ox: starPosition.dx,
          oy: starPosition.dy,
          colorLookupTable: colorTable,
          color: colorTable[(random.nextDouble() * 100).floor()],
          colorIndex: colorIndex);
      _starBgHolder.add(star);
    }
  }

  Offset getStarPosition(double radius, double sideLength) {
    final random = Random();
    double x = random.nextDouble() * sideLength - (sideLength / 2);
    double y = random.nextDouble() * sideLength - (sideLength / 2);

    if (radius > 0) {
      while (sqrt(x * x + y * y) < radius) {
        x = random.nextDouble() * sideLength - (sideLength / 2);
        y = random.nextDouble() * sideLength - (sideLength / 2);
      }
    }

    return Offset(x, y);
  }

  void render() {
    if (_setting.starRotationPermission) {
      if (_startEffectController._runRotation) {
        _starRotationAnimationTime += 1;
        if (_starRotationAnimationTime >
            _setting.starRotationAnimationDuration) {
          _starRotationAnimationTime = _setting.starRotationAnimationDuration;
        }
      } else {
        _starRotationAnimationTime -= 1;
        if (_starRotationAnimationTime < 0) {
          _starRotationAnimationTime = 0;
        }
      }
      _starRotationSpeed = _easeOutQuad(
          _starRotationAnimationTime,
          _setting.starRotationSpeedMin,
          _setting.starRotationSpeedMax,
          _setting.starRotationAnimationDuration);

      _starRotation -=
          _setting.starRotationSpeed * _setting.starRotationDirection;
    }

    if (_startEffectController._run) {
      _starSpeedAnimationTime += 1;
      if (_starSpeedAnimationTime > _setting.starSpeedAnimationDuration) {
        _starSpeedAnimationTime = _setting.starSpeedAnimationDuration;
      }
      _starFovAnimationTime -= 1;
      if (_starFovAnimationTime < 0) {
        _starFovAnimationTime = 0;
      }

      if (_setting.starFollowMouseXAxis) {
        _center = Offset(
            _center.dx +
                ((_touchPos.dx - _center.dx) *
                    _setting.starFollowMouseSensitivity),
            _center.dy);
      }

      if (_setting.starFollowMouseYAxis) {
        _center = Offset(
            _center.dx,
            _center.dy +
                ((_touchPos.dy - _center.dy) *
                    _setting.starFollowMouseSensitivity));
      }
    } else {
      _starSpeedAnimationTime -= 1;
      if (_starSpeedAnimationTime < 0) {
        _starSpeedAnimationTime = 0;
      }

      _starFovAnimationTime += 1;
      if (_starFovAnimationTime > _setting.starFovAnimationDuration) {
        _starFovAnimationTime = _setting.starFovAnimationDuration;
      }

      if (_setting.starFollowMouseXAxis) {
        _center = Offset(
            _center.dx +
                ((_setting.canvasWidth / 2 - _center.dx) *
                    _setting.starFollowMouseSensitivity),
            _center.dy);
      }

      if (_setting.starFollowMouseYAxis) {
        _center = Offset(
            _center.dx,
            _center.dy +
                ((_setting.canvasHeight / 2 - _center.dy) *
                    _setting.starFollowMouseSensitivity));
      }
    }

    _starSpeed = _easeOutQuad(
            _starSpeedAnimationTime,
            0,
            _setting.starSpeedMax - _setting.starSpeedMin,
            _setting.starSpeedAnimationDuration) +
        _setting.starSpeedMin;
    _starFov = _easeInQuad(
            _starFovAnimationTime,
            0,
            _setting.starFovMax - _setting.starFovMin,
            _setting.starFovAnimationDuration) +
        _setting.starFovMin;

    _warpSpeedValue = _starSpeed *
        (_starSpeed / (_setting.starSpeedMax / _setting.starWarpLineLength));
  }

  double _easeOutQuad(double t, double b, double c, double d) {
    t /= d;
    return -c * t * (t - 2) + b;
  }

  double _easeInQuad(double t, double b, double c, double d) {
    t /= d;
    return c * t * t + b;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        _setting.canvasWidth = constraints.maxWidth;
        _setting.canvasHeight = constraints.maxHeight;
        _size = Size(_setting.canvasWidth, _setting.canvasHeight);
        _center = Offset(_size.width / 2, _size.height / 2);
        _touchPos = _center;
        return MouseRegion(
            onHover: (event) {
              _touchPos = event.localPosition;
              _startEffectController.active();
            },
            onExit: (event) {
              _startEffectController.pause();
            },
            child: ValueListenableBuilder(
              valueListenable: _update,
              builder: (BuildContext context, bool value, Widget? child) {
                return CustomPaint(
                    size: _size,
                    painter: StarPainter(
                        starFieldBackgroundColor:
                            _setting.starFieldBackgroundColor,
                        starFov: _starFov,
                        center: _center,
                        starSpeed: _starSpeed,
                        starSpeedMin: _setting.starSpeedMin,
                        warpSpeedValue: _warpSpeedValue,
                        starRotationSpeed: _starRotationSpeed,
                        starRotationSpeedMin: _setting.starRotationSpeedMin,
                        starRotation: _starRotation,
                        controller: _controller,
                        starHolder: _starHolder,
                        starBgHolder: _starBgHolder,
                        starDistance: _starDistance,
                        starDirection: _setting.starDirection),
                    child: Container(
                      width: _size.width,
                      height: _size.height,
                      child: widget.child,
                    ));
              },
            ));
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class Star {
  double x;
  double y;
  double z;
  double ox;
  double oy;
  double x2d;
  double y2d;
  double? distance;
  double? distanceTotal;
  List<Color> colorLookupTable;
  int colorIndex;
  Color color;

  Star(
      {required this.x,
      required this.y,
      required this.z,
      required this.ox,
      required this.oy,
      this.distance,
      this.distanceTotal,
      this.x2d = 0,
      this.y2d = 0,
      required this.colorLookupTable,
      required this.colorIndex,
      required this.color});
}

class StarPainter extends CustomPainter {
  final AnimationController controller;
  final List<Star> starBgHolder;
  final List<Star> starHolder;
  final double starDistance;
  final double starDirection;
  final double starFov;
  final Offset center;
  final double starSpeed;
  final double starSpeedMin;
  final double starRotationSpeed;
  final double starRotationSpeedMin;
  final double warpSpeedValue;
  final double starRotation;
  final Color starFieldBackgroundColor;

  StarPainter(
      {required this.starFieldBackgroundColor,
      required this.starFov,
      required this.center,
      required this.starSpeed,
      required this.starSpeedMin,
      required this.warpSpeedValue,
      required this.starRotationSpeed,
      required this.starRotationSpeedMin,
      required this.starRotation,
      required this.controller,
      required this.starHolder,
      required this.starBgHolder,
      required this.starDistance,
      required this.starDirection});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final bgPaint = Paint()..style = PaintingStyle.fill;

    canvas.drawRect(
        Offset.zero & size, bgPaint..color = starFieldBackgroundColor);
    canvas.clipRect(Offset.zero & size);

    final canvasWidth = size.width;
    final canvasHeight = size.height;
    final centerX = center.dx;
    final centerY = center.dy;
    final starBorderFront = 1 - starFov;
    final starBorderBack = starDistance;

    // Background stars
    for (var star in starBgHolder) {
      final scale = starFov / (starFov + star.z);
      star.x2d = (star.x * scale) + centerX;
      star.y2d = (star.y * scale) + centerY;
      if (star.x2d > -1 &&
          star.x2d < canvasWidth &&
          star.y2d > -1 &&
          star.y2d < canvasHeight) {
        canvas.drawCircle(
            Offset(star.x2d, star.y2d), 1.0, paint..color = star.color);
      }
    }

    // Moving stars
    for (var star in starHolder) {
      star.distanceTotal = (starDistance + starFov).round().toDouble();
      // star.distance = star.distance ?? 0;

      if (starDirection >= 0) {
        star.z -= starSpeed;
        star.distance = star.distance! + starSpeed;

        if (star.z < starBorderFront) {
          star.z = starBorderBack;
          star.distance = 0;
        }
      } else {
        star.z += starSpeed;
        star.distance = star.distance! - starSpeed;

        if (star.z > starBorderBack) {
          star.z = starBorderFront;
          star.distance = star.distanceTotal;
        }
      }

      star.color = star.colorLookupTable[
          ((star.distance! / star.distanceTotal!) * 100).floor()];

      var scale = starFov / (starFov + star.z);
      star.x2d = (star.x * scale) + centerX;
      star.y2d = (star.y * scale) + centerY;

      drawLine(canvas, size, star, paint);

      if (starRotationSpeed != starRotationSpeedMin) {
        var radians = pi / 180 * starRotation;

        var cosV = cos(radians);

        var sinV = sin(radians);

        star.x = cosV * star.ox + sinV * star.oy;
        star.y = cosV * star.oy - sinV * star.ox;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  void drawCycle(Canvas canvas, Size size, Paint paint, Star star) {
    if (star.x2d > -1 &&
        star.x2d < size.width &&
        star.y2d > -1 &&
        star.y2d < size.height) {
      canvas.drawCircle(
          Offset(star.x2d, star.y2d), 1.0, paint..color = star.color);
    }
  }

  void drawLine(Canvas canvas, Size size, Star star, Paint paint) {
    var nz = star.z + warpSpeedValue;

    var scale = starFov / (starFov + nz);

    var x2d = (star.x * scale) + center.dx;
    var y2d = (star.y * scale) + center.dy;

    if (x2d > -1 && x2d < size.width && y2d > -1 && y2d < size.height) {
      final start = Offset(star.x2d, star.y2d);
      final end = Offset(x2d, y2d);
      if ((start - end).distance > 1) {
        canvas.drawLine(
            start,
            end,
            paint
              ..color = star.color
              ..strokeWidth = 1);
      } else {
        drawCycle(canvas, size, paint, star);
      }
    }
  }
}
