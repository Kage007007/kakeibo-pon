import 'package:flutter/material.dart';
import '../models/category.dart';
import '../utils/responsive_utils.dart';

class CategoryButton extends StatefulWidget {
  final MainCategory category;
  final bool isSelected;
  final bool isPredicted;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const CategoryButton({
    super.key,
    required this.category,
    required this.isSelected,
    required this.isPredicted,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<CategoryButton> createState() => _CategoryButtonState();
}

class _CategoryButtonState extends State<CategoryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CategoryButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 予測時に脈動アニメーション開始
    if (widget.isPredicted && !oldWidget.isPredicted) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isPredicted && oldWidget.isPredicted) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    Color backgroundColor;
    Color borderColor;

    if (widget.isSelected) {
      backgroundColor = Theme.of(context).colorScheme.primary.withOpacity(0.3);
      borderColor = Theme.of(context).colorScheme.primary;
    } else if (widget.isPredicted) {
      backgroundColor = Theme.of(context).colorScheme.primary.withOpacity(0.1);
      borderColor = Theme.of(context).colorScheme.primary.withOpacity(0.5);
    } else {
      backgroundColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.05);
      borderColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.1);
    }

    Widget button = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(r.borderRadius(16)),
        border: Border.all(
          color: borderColor,
          width: widget.isSelected ? 2.0 : 1.0,
        ),
      ),
      padding: r.paddingSymmetric(vertical: 8, horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.category.icon,
                style: TextStyle(fontSize: r.iconSize(28)),
              ),
            ),
          ),
          r.verticalSpace(4),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.category.name,
                style: TextStyle(
                  fontSize: r.fontSize(12),
                  fontWeight:
                      widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: widget.isSelected
                      ? Theme.of(context).colorScheme.primary
                      : widget.isPredicted
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.8)
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (widget.isPredicted && !widget.isSelected)
            Flexible(
              child: Container(
                margin: EdgeInsets.only(top: r.spacing(2)),
                padding: EdgeInsets.symmetric(
                  horizontal: r.spacing(4),
                  vertical: r.spacing(1),
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(r.borderRadius(6)),
                ),
                child: Text(
                  '？',
                  style: TextStyle(
                    fontSize: r.fontSize(8),
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    // 予測時は脈動アニメーション
    if (widget.isPredicted) {
      button = ScaleTransition(
        scale: _pulseAnimation,
        child: button,
      );
    }

    // タップ時のスケールアニメーション
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 1.0),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(r.borderRadius(16)),
            child: InkWell(
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
              onTapDown: (_) {
                // タップ開始時にスケールダウン
              },
              onTapUp: (_) {
                // タップ終了時にスケール戻す
              },
              borderRadius: BorderRadius.circular(r.borderRadius(16)),
              child: button,
            ),
          ),
        );
      },
    );
  }
}
