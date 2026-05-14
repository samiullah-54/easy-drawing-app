import 'package:flutter/material.dart';
import '../state/drawing_state.dart';
import 'dart:math' as math;

class FloatingObjectWidget extends StatefulWidget {
  final CanvasObject object;
  final DrawingState state;

  const FloatingObjectWidget({super.key, required this.object, required this.state});

  @override
  State<FloatingObjectWidget> createState() => _FloatingObjectWidgetState();
}

class _FloatingObjectWidgetState extends State<FloatingObjectWidget> {
  Offset _startingPosition = Offset.zero;
  double _startingScale = 1.0;
  double _startingRotation = 0.0;
  bool _isSelected = false;

  void _onScaleStart(ScaleStartDetails details) {
    if (widget.state.selectedTool != DrawingTool.pan) return;
    setState(() {
      _isSelected = true;
      _startingPosition = widget.object.position;
      _startingScale = widget.object.scale;
      _startingRotation = widget.object.rotation;
    });
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (!_isSelected) return;
    
    final newPosition = _startingPosition + details.focalPointDelta;
    final newScale = _startingScale * details.scale;
    final newRotation = _startingRotation + details.rotation;

    widget.state.updateObject(widget.object.copyWith(
      position: newPosition,
      scale: newScale,
      rotation: newRotation,
    ));
  }

  void _onScaleEnd(ScaleEndDetails details) {
    setState(() {
      _isSelected = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Only allow interaction if Pan tool is selected to avoid conflicting with drawing
    final canInteract = widget.state.selectedTool == DrawingTool.pan;

    return Positioned(
      left: widget.object.position.dx,
      top: widget.object.position.dy,
      child: GestureDetector(
        onScaleStart: canInteract ? _onScaleStart : null,
        onScaleUpdate: canInteract ? _onScaleUpdate : null,
        onScaleEnd: canInteract ? _onScaleEnd : null,
        onTap: () {
          // Future enhancement: tap to select/bring to front
        },
        child: Transform(
          transform: Matrix4.identity()
            ..translate(0.0, 0.0) // Position handled by Positioned
            ..rotateZ(widget.object.rotation)
            ..scale(widget.object.scale),
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              border: _isSelected ? Border.all(color: Colors.blue, width: 2 / widget.object.scale) : null,
            ),
            child: Icon(
              widget.object.icon,
              color: widget.object.color,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }
}
