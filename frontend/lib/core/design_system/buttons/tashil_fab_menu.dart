import 'package:flutter/material.dart';

/// Item model for actions inside the M3 FAB Menu.
class TashilFabMenuItem {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const TashilFabMenuItem({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
  });
}

/// Type 10: Official Material Design 3 FAB Menu (Speed Dial) component.
///
/// Features a primary floating action button that smoothly expands vertically
/// to reveal a tiered column of labeled secondary action buttons, with icon
/// rotation into a close indicator (✕).
class TashilFabMenu extends StatefulWidget {
  final List<TashilFabMenuItem> items;
  final IconData openIcon;
  final IconData closeIcon;
  final String? tooltip;
  final Color? mainFabBackgroundColor;
  final Color? mainFabForegroundColor;

  const TashilFabMenu({
    super.key,
    required this.items,
    this.openIcon = Icons.add_rounded,
    this.closeIcon = Icons.close_rounded,
    this.tooltip,
    this.mainFabBackgroundColor,
    this.mainFabForegroundColor,
  });

  @override
  State<TashilFabMenu> createState() => _TashilFabMenuState();
}

class _TashilFabMenuState extends State<TashilFabMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
    );
    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Expanded Menu Items
        AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            if (_expandAnimation.value == 0) return const SizedBox.shrink();

            return Opacity(
              opacity: _expandAnimation.value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (int i = 0; i < widget.items.length; i++) ...[
                    _buildMenuItem(context, widget.items[i], i),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            );
          },
        ),

        // Primary Toggle FAB
        FloatingActionButton(
          onPressed: _toggle,
          tooltip: widget.tooltip ?? (_isOpen ? 'إغلاق / Close' : 'إجراءات / Actions'),
          backgroundColor: widget.mainFabBackgroundColor ??
              (_isOpen ? colorScheme.surfaceContainerHighest : colorScheme.primary),
          foregroundColor: widget.mainFabForegroundColor ??
              (_isOpen ? colorScheme.onSurface : colorScheme.onPrimary),
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: RotationTransition(
            turns: _rotateAnimation,
            child: Icon(
              _isOpen ? widget.closeIcon : widget.openIcon,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, TashilFabMenuItem item, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bg = item.backgroundColor ?? colorScheme.secondaryContainer;
    final fg = item.foregroundColor ?? colorScheme.onSecondaryContainer;

    return Transform.translate(
      offset: Offset(0, 15 * (1 - _expandAnimation.value) * (widget.items.length - index)),
      child: Material(
        color: bg,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          onTap: () {
            _toggle();
            item.onPressed();
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.icon, size: 18, color: fg),
                const SizedBox(width: 8),
                Text(
                  item.label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
