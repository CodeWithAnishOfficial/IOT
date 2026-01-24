import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SwipeButton extends StatefulWidget {
  final VoidCallback onSwipe;
  final String text;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;
  final double height;

  const SwipeButton({
    super.key,
    required this.onSwipe,
    this.text = "Swipe to Start",
    this.backgroundColor = Colors.black,
    this.foregroundColor = Colors.white,
    this.icon = Icons.arrow_forward,
    this.height = 56.0,
  });

  @override
  State<SwipeButton> createState() => _SwipeButtonState();
}

class _SwipeButtonState extends State<SwipeButton> {
  double _dragValue = 0.0;
  bool _isFinished = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final sliderWidth = widget.height - 8; // Padding 4 on each side

        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(widget.height / 2),
            boxShadow: [
              BoxShadow(
                color: widget.backgroundColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Text Label
              Center(
                child: Opacity(
                  opacity: 1.0 - (_dragValue / (maxWidth - widget.height)),
                  child: Text(
                    widget.text,
                    style: GoogleFonts.poppins(
                      color: widget.foregroundColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              // Draggable Circle
              Positioned(
                left: 4 + _dragValue,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_isFinished) return;
                    setState(() {
                      _dragValue += details.delta.dx;
                      if (_dragValue < 0) _dragValue = 0;
                      if (_dragValue > maxWidth - widget.height) {
                        _dragValue = maxWidth - widget.height;
                      }
                    });
                  },
                  onHorizontalDragEnd: (details) {
                     if (_isFinished) return;
                    if (_dragValue >= (maxWidth - widget.height) * 0.9) {
                      // Trigger Action
                      setState(() {
                        _isFinished = true;
                        _dragValue = maxWidth - widget.height;
                      });
                      widget.onSwipe();
                    } else {
                      // Reset
                      setState(() {
                        _dragValue = 0;
                      });
                    }
                  },
                  child: Container(
                    width: sliderWidth,
                    height: sliderWidth,
                    decoration: BoxDecoration(
                      color: widget.foregroundColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.backgroundColor,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
