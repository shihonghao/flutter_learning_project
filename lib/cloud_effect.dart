import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CloudEffect extends StatefulWidget {
  final Widget? child;

  const CloudEffect({super.key, this.child});

  @override
  State<StatefulWidget> createState() {
    return _CloudEffect();
  }
}

class _CloudEffect extends State<CloudEffect>
    with SingleTickerProviderStateMixin {
  late List<Cloud> _clouds;
  late AnimationController _animationController;
  late Size canvasSize;

  @override
  void initState() {
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _animationController.addListener(() {
      updateClouds();
    });
    _animationController.repeat();
    _clouds = [];
    canvasSize = Size.zero;
    super.initState();
  }

  Future<ui.Image> loadImage(String path) async {
    // 加载资源文件
    final data = await rootBundle.load(path);
    // 把资源文件转换成Uint8List类型
    final bytes = data.buffer.asUint8List();
    // 解析Uint8List类型的数据图片
    return await decodeImageFromList(bytes);
  }

  Future<List<ui.Image>> loadImages() async {
    List<ui.Image> images = [];
    images.add(await loadImage("packages/flutter_learning_project/assets/img/cloud1.png"));
    images.add(await loadImage("packages/flutter_learning_project/assets/img/cloud2.png"));
    images.add(await loadImage("packages/flutter_learning_project/assets/img/cloud3.png"));
    images.add(await loadImage("packages/flutter_learning_project/assets/img/cloud4.png"));
    images.add(await loadImage("packages/flutter_learning_project/assets/img/cloud5.png"));
    return images;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ui.Image>>(
        future: loadImages(),
        builder:
            (BuildContext context, AsyncSnapshot<List<ui.Image>> snapshot) {
          if (snapshot.hasData) {
            return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
                buildClouds(snapshot.requireData);
                return ListenableBuilder(
                  listenable: _animationController,
                  builder: (BuildContext context, Widget? child) {
                    return CustomPaint(
                      size: canvasSize,
                      painter: _CloudPainter(_clouds),
                      child: widget.child,
                    );
                  },
                );
              },
            );
          } else {
            return Container();
          }
        });
  }

  void buildClouds(List<ui.Image> imageData) {
    if (_clouds.isNotEmpty) {
      return;
    }
    List<Cloud> clouds = [];
    var random = Random();
    for (var value in imageData) {
      var scale = 0.2 + random.nextDouble() * 0.6;
      clouds.add(Cloud(
          Offset(
              random.nextDouble() * canvasSize.width,
              random.nextDouble() * canvasSize.height),
          scale,
          random.nextDouble(),
          value));
    }
    _clouds = clouds;
  }

  void updateClouds() {
    var random = Random();
    List<Cloud> needRemoved = [];
    List<Cloud> addList = [];

    for (var value in _clouds) {
      var maxWidth = canvasSize.width / value.scale;
      if (value.position.dx > maxWidth && value.readyDestroy) {
        needRemoved.add(value);
      } else if (maxWidth - value.position.dx < value.image.width / 2 &&
          !value.readyDestroy) {
        value.readyDestroy = true;
        var newScale = 0.3 + random.nextDouble() * 0.7;
        addList.add(Cloud(
            Offset(-value.image.width * 1,
                random.nextDouble() * canvasSize.height),
            newScale,
            random.nextDouble(),
            value.image));
      } else {
        value.position = Offset(value.position.dx + 4, value.position.dy);
      }
    }
    for (var value1 in needRemoved) {
      _clouds.remove(value1);
    }
    _clouds.addAll(addList);
  }
}

class Cloud {
  Offset position;
  double scale;
  double opacity;
  ui.Image image;
  bool readyDestroy;

  Cloud(this.position, this.scale, this.opacity, this.image,
      [this.readyDestroy = false]);
}

class _CloudPainter extends CustomPainter {
  final List<Cloud> clouds;

  _CloudPainter(this.clouds);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    canvas.drawRect(Offset.zero & size, paint..color = Colors.lightBlue);
    canvas.clipRect(Offset.zero & size);

    for (var cloud in clouds) {
      canvas.save();
      canvas.scale(cloud.scale);
      canvas.drawImage(
          cloud.image, cloud.position, paint..color = Colors.white);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
