import 'dart:math';
import 'package:flutter/material.dart';
import '../../../controllers/graph_controller.dart';
import '../../../controllers/tools_controller.dart';
import '../../../data/models/frequency_response.dart'; // Assuming your curve model is here

class GraphPainter extends CustomPainter {
  final GraphController graphController;
  final ToolsController toolsController;

  GraphPainter({required this.graphController, required this.toolsController});

  // Helper to convert frequency (logarithmic) to X coordinate
  double _freqToX(double freq, double width) {
    if (freq <= 0) return 0;
    // Assuming these exist in your controller from your provided code
    final minFreq = graphController.xAxisMinRange.value;
    final maxFreq = graphController.xAxisMaxRange.value;
    return width * (log(freq / minFreq) / log(maxFreq / minFreq));
  }

  // Helper to convert dB level (linear) to Y coordinate
  double _dbToY(double db, double height) {
    // Defines the center dB level of the graph
    const centerDb = 0.0;
    final dbRange = toolsController.selectedYScale.value;
    final minDb = centerDb - dbRange / 2;
    final maxDb = centerDb + dbRange / 2;

    // Invert Y-axis because canvas origin (0,0) is top-left
    return height * (1 - (db - minDb) / (maxDb - minDb));
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawCurves(canvas, size);
    _drawLabels(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint =
        Paint()
          ..color = graphController.gridPaintColor.value
          ..strokeWidth = 1.0;

    final labelStyle = TextStyle(color: Colors.black, fontSize: 10);
    final smallLabelStyle = TextStyle(color: Colors.black, fontSize: 6);

    // --- Vertical Grid Lines (Frequency) ---
    final freqLines = [
      20,
      30,
      40,
      50,
      60,
      80,
      100,
      150,
      200,
      300,
      400,
      500,
      600,
      800,
      1000,
      1500,
      2000,
      3000,
      4000,
      5000,
      6000,
      8000,
      10000,
      15000,
      20000,
    ];
    final boldFreqLines = [20, 100, 1000, 10000, 20000];

    for (var freq in freqLines) {
      final x = _freqToX(freq.toDouble(), size.width);
      final isBold = boldFreqLines.contains(freq);

      gridPaint.color = const Color(0xFFC9A98A);
      gridPaint.strokeWidth = isBold ? 1.5 : 0.5;

      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);

      final String text;
      if (freq >= 1000) {
        final double kValue = freq / 1000;
        if (kValue == kValue.toInt().toDouble()) {
          text = '${kValue.toInt()}k';
        } else {
          text = '${kValue.toStringAsFixed(1)}k';
        }
      } else {
        if (freq == freq.toInt().toDouble()) {
          text = freq.toInt().toString();
        } else {
          text = freq.toStringAsFixed(1);
        }
      }
      final textPainter = TextPainter(
        text: TextSpan(text: text, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      if (size.width > 600 || isBold) {
        if (freq < 15000) {
          textPainter.paint(canvas, Offset(x + 2, size.height - 14));
        } else if (freq == 15000 || freq == 20000) {
          textPainter.paint(canvas, Offset(x - 16, size.height - 14));
        }
      } else {
        final textTempPainter = TextPainter(
          text: TextSpan(text: text, style: smallLabelStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        if (freq < 15000) {
          textTempPainter.paint(canvas, Offset(x + 1, size.height - 12));
        } else if (freq == 20000) {
          textTempPainter.paint(canvas, Offset(x - 8, size.height - 12));
        }
      }
    }

    // --- Horizontal Grid Lines (dB) ---
    const step = 5;
    const centerDb = 0;

    for (int i = -10; i < 10; i++) {
      final db = centerDb + (i * step);
      final y = _dbToY(db.toDouble(), size.height);

      if (y > 0 && y < size.height) {
        gridPaint.color = const Color(0xFFC9A98A);
        gridPaint.strokeWidth = 0.7;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);

        final textPainter = TextPainter(
          text: TextSpan(text: '$db dB', style: labelStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, Offset(5, y - 14));
      }
    }
  }

  void _drawCurves(Canvas canvas, Size size) {
    final normFreq = graphController.normHz.value;
    final normDb = graphController.normDb.value;

    for (var curve in graphController.curves) {
      if (!curve.isVisible.value || curve.data.isEmpty) continue;

      final curvePaint =
          Paint()
            ..color = curve.color
            ..strokeWidth = 2.0
            ..style = PaintingStyle.stroke;

      final normPoint = curve.data.firstWhere(
        (p) => p.frequency >= normFreq,
        orElse: () => curve.data.last,
      );
      final dbOffset = normDb - normPoint.db;

      final path = Path();
      bool firstPoint = true;

      for (var point in curve.data) {
        final x = _freqToX(point.frequency, size.width);
        final y = _dbToY(point.db + dbOffset, size.height);

        if (firstPoint) {
          path.moveTo(x, y);
          firstPoint = false;
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, curvePaint);
    }
  }

  void _drawLabels(Canvas canvas, Size size) {
    // Start the first label at 85% of the canvas height
    double labelYOffset = size.height * 0.85;

    for (var curve in graphController.curves) {
      // Only draw labels for curves that are visible and have data
      if (!curve.isVisible.value || curve.data.isEmpty) continue;

      _drawLabelShape(canvas, size, curve, labelYOffset);

      // Decrement the Y position for the next label
      labelYOffset -= 20;
    }
  }

  void _drawLabelShape(
    Canvas canvas,
    Size size,
    FrequencyResponse curve,
    double labelYOffset,
  ) {
    // 1. Define styles
    final shapePaint = Paint()..color = const Color(0xFFFFF8EB);
    final labelStyle = TextStyle(
      color: curve.color,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );

    // 2. Prepare the text to measure it
    final textPainter = TextPainter(
      text: TextSpan(text: '${curve.brandID} ${curve.name}', style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    // 3. Define shape properties
    const horizontalPadding = 8.0;
    const verticalPadding = 4.0;
    const cornerRadius = Radius.circular(8.0);
    final labelXPosition = size.width * 0.6255;

    final rectWidth = textPainter.width + (horizontalPadding * 2);
    final rectHeight = textPainter.height + (verticalPadding * 2);

    // 4. Create the shape path
    final shapePath = Path();

    // The main rectangle body
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(labelXPosition, labelYOffset, rectWidth, rectHeight),
      cornerRadius,
    );
    shapePath.addRRect(rect);

    // 5. Draw the shape and the text
    canvas.drawPath(shapePath, shapePaint);
    textPainter.paint(
      canvas,
      Offset(
        labelXPosition + horizontalPadding,
        labelYOffset + verticalPadding,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) {
    return true;
  }
}
