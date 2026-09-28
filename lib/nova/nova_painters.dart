import 'package:flutter/material.dart';

class GraphPainter extends CustomPainter {
  final List<List<double>> series; // one list of y per function
  final List<double> xs;
  final List<Color> colors;
  final double xmin, xmax, ymin, ymax;

  GraphPainter({
    required this.series,
    required this.xs,
    required this.colors,
    required this.xmin,
    required this.xmax,
    required this.ymin,
    required this.ymax,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    double px(double x) => (x - xmin) / (xmax - xmin) * w;
    double py(double y) => h - (y - ymin) / (ymax - ymin) * h;
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    final gridW = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..strokeWidth = 1;
    // vertical grid
    final nv = (xmax - xmin).abs() > 0 ? ((xmax - xmin) / 1).ceil() : 10;
    final stepX = (xmax - xmin) / nv;
    for (int i = 0; i <= nv; i++) {
      final x = xmin + i * stepX;
      canvas.drawLine(Offset(px(x), 0), Offset(px(x), h), grid);
    }
    final stepY = (ymax - ymin) / 10;
    for (int i = 0; i <= 10; i++) {
      final y = ymin + i * stepY;
      canvas.drawLine(Offset(0, py(y)), Offset(w, py(y)), grid);
    }
    // axes
    if (xmin < 0 && xmax > 0) canvas.drawLine(Offset(px(0), 0), Offset(px(0), h), gridW);
    if (ymin < 0 && ymax > 0) canvas.drawLine(Offset(0, py(0)), Offset(w, py(0)), gridW);
    // curves
    for (int f = 0; f < series.length; f++) {
      final ys = series[f];
      if (ys.length < 2) continue;
      final paint = Paint()
        ..color = colors[f % colors.length]
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round;
      final path = Path();
      bool started = false;
      for (int i = 0; i < xs.length; i++) {
        final v = ys[i];
        if (!v.isFinite) {
          started = false;
          continue;
        }
        final o = Offset(px(xs[i]), py(v));
        if (!started) {
          path.moveTo(o.dx, o.dy);
          started = true;
        } else {
          path.lineTo(o.dx, o.dy);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant GraphPainter old) =>
      old.xmin != xmin ||
      old.xmax != xmax ||
      old.ymin != ymin ||
      old.ymax != ymax ||
      old.xs.length != xs.length ||
      old.series.length != series.length;
}

class IntegralAreaPainter extends CustomPainter {
  final List<double> xs;
  final List<double> ys;
  final double a, b;
  final Color curveColor;
  IntegralAreaPainter({
    required this.xs,
    required this.ys,
    required this.a,
    required this.b,
    required this.curveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    double xmin = xs.first, xmax = xs.last;
    double ymin = ys.reduce((x, y) => x < y ? x : y);
    double ymax = ys.reduce((x, y) => x > y ? x : y);
    if ((ymax - ymin).abs() < 1e-9) {
      ymin -= 1;
      ymax += 1;
    }
    double px(double x) => (x - xmin) / (xmax - xmin) * w;
    double py(double y) => h - (y - ymin) / (ymax - ymin) * h;
    // shaded region
    final shade = Paint()..color = curveColor.withValues(alpha: 0.25);
    final path = Path();
    final points = <Offset>[];
    for (int i = 0; i < xs.length; i++) {
      if (xs[i] < a || xs[i] > b) continue;
      points.add(Offset(px(xs[i]), py(ys[i])));
    }
    if (points.isNotEmpty) {
      final y0v = (ymin * ymax) < 0 ? 0.0 : (py(ymax) < 0 ? 0.0 : py(ymax));
      path.moveTo(points.first.dx, y0v);
      for (final p in points) {
        path.lineTo(p.dx, p.dy);
      }
      path.lineTo(points.last.dx, y0v);
      path.close();
      canvas.drawPath(path, shade);
    }
    // curve
    final paint = Paint()
      ..color = curveColor
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    final cp = Path();
    for (int i = 0; i < xs.length; i++) {
      final o = Offset(px(xs[i]), py(ys[i]));
      if (i == 0) {
        cp.moveTo(o.dx, o.dy);
      } else {
        cp.lineTo(o.dx, o.dy);
      }
    }
    canvas.drawPath(cp, paint);
    // a and b markers
    final mark = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.4;
    canvas.drawLine(Offset(px(a), 0), Offset(px(a), h), mark);
    canvas.drawLine(Offset(px(b), 0), Offset(px(b), h), mark);
  }

  @override
  bool shouldRepaint(covariant IntegralAreaPainter old) =>
      old.a != a || old.b != b || old.xs.length != xs.length;
}

class ProjectilePainter extends CustomPainter {
  final List<Offset> trajectory;
  final Offset? ball;
  final double range;
  final double maxH;
  ProjectilePainter({
    required this.trajectory,
    required this.ball,
    required this.range,
    required this.maxH,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width.toDouble(), h = size.height.toDouble();
    final pad = 22.0;
    final pw = w - pad * 2, ph = h - pad * 2;
    double xr = range <= 0 ? 1 : range;
    double hr = maxH <= 0 ? 1 : maxH;
    Offset map(Offset p) => Offset(pad + p.dx / xr * pw, h - pad - p.dy / hr * ph);
    // ground
    final ground = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(pad, h - pad), Offset(w - pad, h - pad), ground);
    // path
    final path = Paint()
      ..color = Colors.lightBlueAccent
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    final p = Path();
    for (int i = 0; i < trajectory.length; i++) {
      final o = map(trajectory[i]);
      if (i == 0) {
        p.moveTo(o.dx, o.dy);
      } else {
        p.lineTo(o.dx, o.dy);
      }
    }
    canvas.drawPath(p, path);
    if (ball != null) {
      final c = map(ball!);
      canvas.drawCircle(c, 9, Paint()..color = Colors.orangeAccent);
      canvas.drawCircle(c, 9, Paint()..color = Colors.black.withValues(alpha: 0.3)..style = PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(covariant ProjectilePainter old) => old.ball != ball;
}