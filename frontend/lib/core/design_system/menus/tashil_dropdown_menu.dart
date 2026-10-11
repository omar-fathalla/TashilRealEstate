import 'package:flutter/material.dart';
import 'tashil_menu_item.dart';

/// Official Google Material Design 3 Dropdown Menu Component.
/// Conforms to https://m3.material.io/components/menus/guidelines
/// and https://m3.material.io/components/menus/specs
///
/// Features:
/// 1. Smooth 250ms Top-to-Bottom unfolding animation (ScaleY + Slide + Fade with cubic easing).
/// 2. 180° animated caret rotation matching the open/close state.
/// 3. Level 2 Elevation floating container with 12dp squircle corners.
/// 4. Highlighted selected item pill container with checkmark icon.
/// 5. Full RTL and LTR directional support.
class TashilDropdownMenu<T> extends StatefulWidget {
  final T value;
  final List<TashilDropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final double height;
  final double maxMenuHeight;
  final bool enabled;
  final bool isSearchable;
  final String? searchHintText;

  const TashilDropdownMenu({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.height = 52.0,
    this.maxMenuHeight = 260.0,
    this.enabled = true,
    this.isSearchable = false,
    this.searchHintText,
  });

  @override
  State<TashilDropdownMenu<T>> createState() => _TashilDropdownMenuState<T>();
}

class _TashilDropdownMenuState<T> extends State<TashilDropdownMenu<T>>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _anchorKey = GlobalKey();

  OverlayEntry? _overlayEntry;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<Offset> _slideAnim;

  bool _isOpen = false;
  bool _isHovered = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      reverseDuration: const Duration(milliseconds: 180),
    );

    final curved = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(curved);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.0, -0.06),
      end: Offset.zero,
    ).animate(curved);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isOpen = false;
    _animController.stop();
    _animController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (!widget.enabled) return;
    if (_isOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    final renderBox = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;

    _searchController.clear();
    _overlayEntry = _createOverlayEntry(size);
    Overlay.of(context).insert(_overlayEntry!);

    setState(() => _isOpen = true);
    _animController.forward();
  }

  void _closeMenu() {
    if (!_isOpen) return;
    setState(() => _isOpen = false);
    _animController.reverse().then((_) {
      _removeOverlay(animate: false);
    });
  }

  void _removeOverlay({bool animate = true}) {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted && _isOpen) {
      setState(() => _isOpen = false);
    }
  }

  void _selectItem(T val) {
    _closeMenu();
    if (widget.onChanged != null) {
      widget.onChanged!(val);
    }
  }

  TashilDropdownMenuItem<T>? get _selectedItem {
    try {
      return widget.items.firstWhere((it) => it.value == widget.value && !it.isDivider);
    } catch (_) {
      return null;
    }
  }

  OverlayEntry _createOverlayEntry(Size anchorSize) {
    return OverlayEntry(
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Stack(
          children: [
            // Full-screen dismiss barrier
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeMenu,
                child: const SizedBox.expand(),
              ),
            ),

            // Animated Dropdown Menu Window anchored to the field
            Positioned.fill(
              child: Align(
                alignment: Alignment.topLeft,
                child: CompositedTransformFollower(
                  link: _layerLink,
                  showWhenUnlinked: false,
                  offset: Offset(0.0, anchorSize.height + 4.0),
                  child: SizedBox(
                    width: anchorSize.width,
                    child: AnimatedBuilder(
                      animation: _animController,
                      builder: (ctx, child) {
                        return FadeTransition(
                          opacity: _fadeAnim,
                          child: SlideTransition(
                            position: _slideAnim,
                            child: Transform.scale(
                              scaleY: _scaleAnim.value,
                              alignment: Alignment.topCenter,
                              child: child,
                            ),
                          ),
                        );
                      },
                      child: Material(
                        elevation: 6,
                        shadowColor: Colors.black.withValues(alpha: 0.18),
                        color: colorScheme.surfaceContainerLowest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.7),
                            width: 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: widget.maxMenuHeight,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.isSearchable) ...[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                                  child: TextField(
                                    controller: _searchController,
                                    autofocus: true,
                                    decoration: InputDecoration(
                                      hintText: widget.searchHintText ?? 'بحث...',
                                      hintStyle: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search_rounded,
                                        size: 18,
                                        color: colorScheme.primary,
                                      ),
                                      suffixIcon: _searchController.text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.clear_rounded, size: 16),
                                              onPressed: () {
                                                _searchController.clear();
                                                _overlayEntry?.markNeedsBuild();
                                              },
                                            )
                                          : null,
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      filled: true,
                                      fillColor: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: colorScheme.outlineVariant),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: colorScheme.outlineVariant),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
                                      ),
                                    ),
                                    style: const TextStyle(fontSize: 13),
                                    onChanged: (_) {
                                      _overlayEntry?.markNeedsBuild();
                                    },
                                  ),
                                ),
                                Divider(height: 1, color: colorScheme.outlineVariant),
                              ],
                              Flexible(
                                child: Builder(
                                  builder: (ctx) {
                                    final query = _searchController.text.trim().toLowerCase();
                                    final visibleItems = query.isEmpty
                                        ? widget.items
                                        : widget.items.where((it) {
                                            if (it.isDivider) return false;
                                            return it.label.toLowerCase().contains(query) ||
                                                (it.supportingText != null &&
                                                    it.supportingText!.toLowerCase().contains(query));
                                          }).toList();

                                    if (visibleItems.isEmpty) {
                                      return Container(
                                        padding: const EdgeInsets.all(20),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'لا توجد نتائج مطابقة',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      );
                                    }

                                    return ListView.builder(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      shrinkWrap: true,
                                      itemCount: visibleItems.length,
                                      itemBuilder: (ctx, idx) {
                                        final item = visibleItems[idx];
                                        final isSelected = !item.isDivider && item.value == widget.value;

                                        return TashilMenuItemWidget<T>(
                                          item: item,
                                          isSelected: isSelected,
                                          onTap: () {
                                            if (!item.isDivider) {
                                              _selectItem(item.value);
                                            }
                                          },
                                        );
                                      },
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
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selected = _selectedItem;

    final borderColor = _isOpen
        ? colorScheme.primary
        : (_isHovered
            ? colorScheme.onSurface
            : colorScheme.outlineVariant);

    final borderWidth = _isOpen ? 2.0 : 1.0;

    return CompositedTransformTarget(
      link: _layerLink,
      key: _anchorKey,
      child: MouseRegion(
        cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: _toggleMenu,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            height: widget.height,
            padding: const EdgeInsetsDirectional.only(start: 12, end: 12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: borderColor,
                width: borderWidth,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: AlignmentDirectional.centerStart,
              children: [
                // Floating Label on top border
                if (widget.labelText != null)
                  PositionedDirectional(
                    top: -10,
                    start: widget.prefixIcon != null ? 24 : 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      color: colorScheme.surface,
                      child: Text(
                        widget.labelText!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: _isOpen ? FontWeight.bold : FontWeight.w500,
                          color: _isOpen ? colorScheme.primary : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),

                // Main Content Row
                Row(
                  children: [
                    // Prefix Icon
                    if (widget.prefixIcon != null) ...[
                      Icon(
                        widget.prefixIcon,
                        size: 20,
                        color: _isOpen ? colorScheme.primary : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                    ],

                    // Selected Value Text or Hint
                    Expanded(
                      child: Text(
                        selected?.label ?? widget.hintText ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected != null
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Rotating Dropdown Caret Icon (180° rotation on open)
                    AnimatedRotation(
                      turns: _isOpen ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: _isOpen ? colorScheme.primary : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
