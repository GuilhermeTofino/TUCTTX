import 'package:app_tenda/widgets/colors.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

// Certifique-se de que LoaderCanvas está importado ou definido neste arquivo.

class TucttxLoader extends StatefulWidget {
  const TucttxLoader({super.key});

  @override
  _TucttxLoaderState createState() => _TucttxLoaderState();
}

class _TucttxLoaderState extends State<TucttxLoader>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _animation = Tween(begin: 1.0, end: 1.2)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 1500)).then((_) {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SizedBox(
          width: 260,
          height: 150,
          child: Align(
            alignment: FractionalOffset.center,
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                padding: const EdgeInsets.all(10),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (BuildContext context, Widget? child) {
                          return Stack(
                            children: [
                              Positioned.fill(
                                child: Transform.rotate(
                                  angle: _controller.status ==
                                          AnimationStatus.forward
                                      ? (math.pi * 2) * _controller.value
                                      : -(math.pi * 2) * _controller.value,
                                  child: CustomPaint(
                                    painter:
                                        LoaderCanvas(radius: _animation.value),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.center,
                                child: SizedBox(
                                  height: 100,
                                  width: 100,
                                  child: Center(
                                    child: Image.asset(
                                      'images/logo_TUCTTX.png',
                                      width: 200.0,
                                    ),
                                  ),
                                ),
                              )
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LoaderCanvas extends CustomPainter {
  final double radius;
  LoaderCanvas({required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    Paint arcPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    Offset center = Offset(size.width / 2, size.height / 2);
    canvas.drawArc(
      Rect.fromCenter(center: center, width: size.width, height: size.height),
      math.pi / 4,
      math.pi / 2,
      false,
      arcPaint,
    );
    canvas.drawArc(
      Rect.fromCenter(center: center, width: size.width, height: size.height),
      -math.pi / 4,
      -math.pi / 2,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
