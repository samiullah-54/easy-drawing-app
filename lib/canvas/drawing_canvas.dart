import 'package:flutter/material.dart';
import '../state/drawing_state.dart';
import 'drawing_painter.dart';
import 'floating_object_widget.dart';

class DrawingCanvas extends StatefulWidget {
  final DrawingState state;

  const DrawingCanvas({super.key, required this.state});

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  void _onPointerDown(PointerDownEvent event) {
    if (widget.state.selectedTool == DrawingTool.pan) return;
    if (event.size > 15.0) return; // Example threshold for palm rejection

    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Offset localPosition = renderBox.globalToLocal(event.position);

    widget.state.addStroke(DrawingStroke(
      points: [localPosition],
      color: widget.state.selectedColor,
      strokeWidth: widget.state.strokeWidth,
      isEraser: widget.state.selectedTool == DrawingTool.eraser,
    ));
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (widget.state.selectedTool == DrawingTool.pan) return;
    if (event.size > 15.0) return;
    
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Offset localPosition = renderBox.globalToLocal(event.position);
    widget.state.updateCurrentStroke(localPosition);
  }

  void _onPointerUp(PointerUpEvent event) {
    if (widget.state.selectedTool == DrawingTool.pan) return;
    widget.state.endStroke();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRect(
          child: Listener(
            onPointerDown: _onPointerDown,
            onPointerMove: _onPointerMove,
            onPointerUp: _onPointerUp,
            behavior: HitTestBehavior.opaque,
            child: ListenableBuilder(
              listenable: widget.state,
              builder: (context, _) {
                if (widget.state.isLoading) {
                   return const Center(child: CircularProgressIndicator());
                }
                return Stack(
                  children: [
                    CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: DrawingPainter(strokes: widget.state.strokes),
                    ),
                    for (var obj in widget.state.objects)
                      FloatingObjectWidget(
                        key: ValueKey(obj.id),
                        object: obj,
                        state: widget.state,
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
