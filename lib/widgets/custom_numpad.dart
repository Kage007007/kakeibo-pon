import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

class CustomNumpad extends StatelessWidget {
  final Function(String) onNumberTap;
  final VoidCallback onDelete;
  final VoidCallback onClear;
  final VoidCallback onConfirm;

  const CustomNumpad({
    super.key,
    required this.onNumberTap,
    required this.onDelete,
    required this.onClear,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final keyHeight = r.heightSize(50);
    final spacing = r.spacing(6);

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow(['1', '2', '3'], keyHeight),
          SizedBox(height: spacing),
          _buildRow(['4', '5', '6'], keyHeight),
          SizedBox(height: spacing),
          _buildRow(['7', '8', '9'], keyHeight),
          SizedBox(height: spacing),
          _buildRow(['000', '0', '00'], keyHeight),
          SizedBox(height: spacing),
          _buildActionRow(keyHeight),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> numbers, double keyHeight) {
    return Row(
      children: numbers.map((number) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: _buildKey(number, keyHeight),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKey(String value, double keyHeight) {
    return _AnimatedNumpadKey(
      value: value,
      height: keyHeight,
      onTap: () => onNumberTap(value),
    );
  }

  Widget _buildActionRow(double keyHeight) {
    return Builder(
      builder: (context) {
        return Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Material(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.0),
                  child: InkWell(
                    onTap: onClear,
                    borderRadius: BorderRadius.circular(12.0),
                    child: Container(
                      height: keyHeight,
                      alignment: Alignment.center,
                      child: Text(
                        'クリア',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Material(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12.0),
                  child: InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(12.0),
                    child: Container(
                      height: keyHeight,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.backspace_outlined,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Material(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12.0),
                  child: InkWell(
                    onTap: onConfirm,
                    borderRadius: BorderRadius.circular(12.0),
                    child: Container(
                      height: keyHeight,
                      alignment: Alignment.center,
                      child: const Text(
                        '決定',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }
    );
  }
}

class _AnimatedNumpadKey extends StatefulWidget {
  final String value;
  final double height;
  final VoidCallback onTap;

  const _AnimatedNumpadKey({
    required this.value,
    required this.height,
    required this.onTap,
  });

  @override
  State<_AnimatedNumpadKey> createState() => _AnimatedNumpadKeyState();
}

class _AnimatedNumpadKeyState extends State<_AnimatedNumpadKey>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: _isPressed
              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12.0),
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            borderRadius: BorderRadius.circular(12.0),
            child: Container(
              height: widget.height,
              alignment: Alignment.center,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _isPressed
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
                child: Text(widget.value),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
