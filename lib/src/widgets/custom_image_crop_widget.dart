// ignore_for_file: comment_references, lines_longer_than_80_chars

import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:gesture_x_detector/gesture_x_detector.dart';
import 'package:vector_math/vector_math_64.dart' as vector_math;

import '../clippers/inverted_clipper.dart';
import '../controllers/controller.dart';
import '../models/model.dart';
import '../painters/circle_path_painter.dart';
import '../painters/dotted_path_painter.dart';

/// An image cropper that is customizable.
/// You can rotate, scale and translate either
/// through gestures or a controller
class CustomImageCrop extends StatefulWidget {
  /// The image to crop
  final ImageProvider image;

  /// The controller that handles the cropping and
  /// changing of the cropping area
  final CustomImageCropController cropController;

  /// The color behind the cropping area
  final Color backgroundColor;

  /// The color in front of the cropped area
  final Color overlayColor;

  /// The shape of the cropping area
  final CustomCropShape shape;

  /// The percentage of the available area that is
  /// reserved for the cropping area
  final double cropPercentage;

  /// The path drawer of the border see [DottedCropPathPainter],
  /// [SolidPathPainter] for more details or how to implement a
  /// custom one
  final CustomPaint Function(Path) drawPath;

  /// The paint used when drawing an image before cropping
  final Paint imagePaintDuringCrop;

  /// A custom image cropper widget
  ///
  /// Uses a `CustomImageCropController` to crop the image.
  /// With the controller you can rotate, translate and/or
  /// scale with buttons and sliders. This can also be
  /// achieved with gestures
  ///
  /// Use a `shape` with `CustomCropShape.Circle` or
  /// `CustomCropShape.Square`
  ///
  /// You can increase the cropping area using `cropPercentage`
  ///
  /// Change the cropping border by changing `drawPath`,
  /// we've provided two default painters as inspiration
  /// `DottedCropPathPainter.drawPath` and
  /// `SolidCropPathPainter.drawPath`

  final double height;

  final double width;

  CustomImageCrop({
    required this.image,
    required this.cropController,
    required this.height,
    this.width = double.infinity,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 0.5),
    this.backgroundColor = const Color(0xFF1A1A1A),
    this.shape = CustomCropShape.CircleDottedLine,
    this.cropPercentage = 0.62,
    this.drawPath = DottedCropPathPainter.drawPath,
    Paint? imagePaintDuringCrop,
    Key? key,
  })  : this.imagePaintDuringCrop = imagePaintDuringCrop ??
            (Paint()..filterQuality = FilterQuality.high),
        super(key: key);

  @override
  State<CustomImageCrop> createState() => _CustomImageCropState();
}

class _CustomImageCropState extends State<CustomImageCrop>
    with CustomImageCropListener {
  CropImageData? _dataTransitionStart;
  late Path _path;
  late double _width;
  late double _height;
  ui.Image? _imageAsUIImage;
  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;
  late CustomPaint Function(Path) _drawPath;

  @override
  void initState() {
    super.initState();
    if (widget.shape == CustomCropShape.Circle) {
      _drawPath = CircleCropPathPainter.drawPath;
    } else {
      _drawPath = widget.drawPath;
    }
    widget.cropController.addListener(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _getImage();
  }

  void _getImage() {
    final oldImageStream = _imageStream;
    _imageStream = widget.image.resolve(createLocalImageConfiguration(context));
    if (_imageStream?.key != oldImageStream?.key) {
      if (_imageListener != null) {
        oldImageStream?.removeListener(_imageListener!);
      }
      _imageListener = ImageStreamListener(_updateImage);
      _imageStream?.addListener(_imageListener!);
    }
  }

  void _updateImage(ImageInfo imageInfo, dynamic _) {
    setState(() {
      _imageAsUIImage = imageInfo.image;
    });
  }

  @override
  void dispose() {
    if (_imageListener != null) {
      _imageStream?.removeListener(_imageListener!);
    }
    widget.cropController.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _imageAsUIImage;

    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: image == null
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                _width = constraints.maxWidth;
                _height = constraints.maxHeight;
                final cropWidth = min(_width, _height) * widget.cropPercentage;
                final defaultScale = cropWidth / max(image.width, image.height);
                final scale = data.scale * defaultScale;
                _path = _getPath(cropWidth, _width, _height);

                return XGestureDetector(
                  onMoveStart: onMoveStart,
                  onMoveUpdate: onMoveUpdate,
                  onScaleStart: onScaleStart,
                  onScaleUpdate: onScaleUpdate,
                  child: Container(
                    width: _width,
                    height: _height,
                    color: widget.backgroundColor,
                    child: Stack(
                      children: [
                        Positioned(
                          left: data.x + _width / 2,
                          top: data.y + _height / 2,
                          child: Transform(
                            transform: Matrix4.diagonal3(
                              vector_math.Vector3(scale, scale, scale),
                            )
                              ..rotateZ(data.angle)
                              ..translate(-image.width / 2, -image.height / 2),
                            child: Image(
                              image: widget.image,
                            ),
                          ),
                        ),
                        IgnorePointer(
                          child: ClipPath(
                            clipper: InvertedClipper(_path, _width, _height),
                            child: Container(
                              color: widget.overlayColor,
                            ),
                          ),
                        ),
                        _drawPath(_path),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void onScaleStart(dynamic _) {
    _dataTransitionStart = null; // Reset for update
  }

  void onScaleUpdate(ScaleEvent event) {
    if (_dataTransitionStart != null) {
      addTransition(_dataTransitionStart! -
          CropImageData(scale: event.scale, angle: event.rotationAngle));
    }
    _dataTransitionStart =
        CropImageData(scale: event.scale, angle: event.rotationAngle);
  }

  void onMoveStart(dynamic _) {
    _dataTransitionStart = null; // Reset for update
  }

  void onMoveUpdate(MoveEvent event) {
    addTransition(CropImageData(x: event.delta.dx, y: event.delta.dy));
  }

  Path _getPath(double cropWidth, double width, double height) {
    switch (widget.shape) {
      case CustomCropShape.Circle:
      case CustomCropShape.CircleDottedLine:
        return Path()
          ..addOval(
            Rect.fromCircle(
              center: Offset(width / 2, height / 2),
              radius: cropWidth / 2,
            ),
          );
      case CustomCropShape.Square:
        return Path()
          ..addRect(
            Rect.fromCenter(
              center: Offset(width / 2, height / 2),
              width: cropWidth,
              height: cropWidth,
            ),
          );
    }
  }

  @override
  Future<MemoryImage?> onCropImage() async {
    if (_imageAsUIImage == null) {
      return null;
    }
    final imageWidth = _imageAsUIImage!.width;
    final imageHeight = _imageAsUIImage!.height;
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final uiWidth = min(_width, _height) * widget.cropPercentage;
    final cropWidth = max(imageWidth, imageHeight).toDouble();
    final translateScale = cropWidth / uiWidth;
    final scale = data.scale;
    final clipPath = Path.from(_getPath(cropWidth, cropWidth, cropWidth));
    final matrix4Image = Matrix4.diagonal3(vector_math.Vector3.all(1))
      ..translate(
        translateScale * data.x + cropWidth / 2,
        translateScale * data.y + cropWidth / 2,
      )
      ..scale(scale)
      ..rotateZ(data.angle);
    final bgPaint = Paint()
      ..color = widget.backgroundColor
      ..style = PaintingStyle.fill;
    canvas
      ..drawRect(Rect.fromLTWH(0, 0, cropWidth, cropWidth), bgPaint)
      ..save()
      ..clipPath(clipPath)
      ..transform(matrix4Image.storage)
      ..drawImage(_imageAsUIImage!, Offset(-imageWidth / 2, -imageHeight / 2),
          widget.imagePaintDuringCrop)
      ..restore();

    // Optionally remove magenta from image by evaluating every pixel
    // See https://github.com/brendan-duncan/image/blob/master/lib/src/transform/copy_crop.dart

    // final bytes = await compute(computeToByteData, <String, dynamic>{'pictureRecorder': pictureRecorder, 'cropWidth': cropWidth});

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(cropWidth.floor(), cropWidth.floor());

    // Adding compute would be preferrable. Unfortunately we cannot pass an ui image to this.
    // A workaround would be to save the image and load it inside of the isolate
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes == null ? null : MemoryImage(bytes.buffer.asUint8List());
  }

  @override
  void addTransition(CropImageData transition) {
    setState(() {
      data += transition;
      // For now, this will do. The idea is that we create
      // a path from the data and check if when we combine
      // that with the crop path that the resulting path
      // overlap the hole (crop). So we check if all pixels
      // from the crop contain pixels from the original image
      data.scale = data.scale.clamp(0.1, 10.0);
    });
  }

  @override
  void setData(CropImageData newData) {
    setState(() {
      data = newData;
      // The same check should happen (once available) as in addTransition
      data.scale = data.scale.clamp(0.1, 10.0);
    });
  }
}

enum CustomCropShape {
  Circle,
  CircleDottedLine,
  Square,
}
