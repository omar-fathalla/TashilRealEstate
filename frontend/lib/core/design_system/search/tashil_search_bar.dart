import 'package:flutter/material.dart';
import '../buttons/tashil_split_button.dart';

/// Official Google Material Design 3 (M3) Search Bar Component.
/// Conforms to:
/// - https://m3.material.io/components/search/overview
/// - https://m3.material.io/components/search/guidelines
/// - https://m3.material.io/components/search/accessibility
/// - https://m3.material.io/components/search/specs
///
/// Features:
/// 1. 56dp standard height with full stadium rounded shape (28dp radius).
/// 2. Interactive state layers and smooth scale & elevation transition on focus/hover (220ms easeOutCubic).
/// 3. Leading search icon with semantic animation.
/// 4. Integrated multi-modal actions (AI Semantic Search, Visual Photo Search, Clear Query).
/// 5. Support for M3 Expressive Split Search Bar (integrated trailing options dropdown button).
/// 6. Downward unfolding M3 Search View / Suggestions overlay with cubic easing.
/// 7. 100% Directionality Awareness (RTL for Arabic, LTR for English/Hindi).
class TashilSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final String? hintText;
  final bool isSemanticActive;
  final VoidCallback? onToggleSemantic;
  final VoidCallback? onVisualSearch;
  final List<String> suggestions;
  final ValueChanged<String>? onSelectSuggestion;
  final double height;
  final FocusNode? focusNode;
  final List<TashilSplitButtonItem<String>>? splitMenuItems;
  final ValueChanged<String>? onSplitMenuItemSelected;
  final String? selectedSplitMenuValue;
  final IconData? leadingIcon;

  const TashilSearchBar({
    super.key,
    required this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.hintText,
    this.isSemanticActive = false,
    this.onToggleSemantic,
    this.onVisualSearch,
    this.suggestions = const [],
    this.onSelectSuggestion,
    this.height = 56.0,
    this.focusNode,
    this.splitMenuItems,
    this.onSplitMenuItemSelected,
    this.selectedSplitMenuValue,
    this.leadingIcon,
  });

  @override
  State<TashilSearchBar> createState() => _TashilSearchBarState();
}

class _TashilSearchBarState extends State<TashilSearchBar> with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _anchorKey = GlobalKey();

  late FocusNode _focusNode;
  bool _internalFocusNode = false;

  OverlayEntry? _suggestionsOverlay;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  bool _isHovered = false;
  bool _isFocused = false;
  bool _hasText = false;
  bool _isSplitMenuOpen = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _internalFocusNode = true;
    }

    _hasText = widget.controller.text.isNotEmpty;
    widget.controller.addListener(_handleTextChange);
    _focusNode.addListener(_handleFocusChange);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      reverseDuration: const Duration(milliseconds: 180),
    );

    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
  }

  void _handleTextChange() {
    final hasNow = widget.controller.text.isNotEmpty;
    if (hasNow != _hasText) {
      setState(() => _hasText = hasNow);
    }
  }

  void _handleFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
    if (_focusNode.hasFocus && widget.suggestions.isNotEmpty) {
      _showSuggestionsOverlay();
    } else {
      _hideSuggestionsOverlay();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChange);
    _focusNode.removeListener(_handleFocusChange);
    if (_internalFocusNode) {
      _focusNode.dispose();
    }
    _removeSuggestionsOverlay();
    _animController.dispose();
    super.dispose();
  }

  void _showSuggestionsOverlay() {
    if (_suggestionsOverlay != null || widget.suggestions.isEmpty) return;

    final overlayState = Overlay.maybeOf(context, rootOverlay: false) ?? Overlay.of(context);
    final renderBox = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;

    _suggestionsOverlay = OverlayEntry(
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;

        return Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, size.height + 8),
            child: Material(
              color: Colors.transparent,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  alignment: Alignment.topCenter,
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 280),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.14),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: widget.suggestions.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          thickness: 1,
                          indent: 16,
                          endIndent: 16,
                          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                        ),
                        itemBuilder: (ctx, i) {
                          final suggestion = widget.suggestions[i];
                          return ListTile(
                            dense: true,
                            horizontalTitleGap: 8,
                            leading: Icon(
                              Icons.history_rounded,
                              size: 18,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            title: Text(
                              suggestion,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: Icon(
                              Icons.north_west_rounded,
                              size: 16,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                            onTap: () {
                              widget.controller.text = suggestion;
                              widget.onSelectSuggestion?.call(suggestion);
                              widget.onSubmitted?.call(suggestion);
                              _focusNode.unfocus();
                              _hideSuggestionsOverlay();
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlayState.insert(_suggestionsOverlay!);
    _animController.forward();
  }

  void _hideSuggestionsOverlay() {
    if (_suggestionsOverlay == null) return;
    _animController.reverse().then((_) {
      _removeSuggestionsOverlay();
    });
  }

  void _removeSuggestionsOverlay() {
    _suggestionsOverlay?.remove();
    _suggestionsOverlay = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isActiveAi = widget.isSemanticActive;
    final hasSplitMenu = widget.splitMenuItems != null && widget.splitMenuItems!.isNotEmpty;

    // M3 Expressive state colors
    final borderColor = isActiveAi
        ? colorScheme.primary
        : (_isFocused
            ? colorScheme.primary
            : (_isHovered
                ? colorScheme.outline
                : colorScheme.outlineVariant.withValues(alpha: 0.6)));

    final borderWidth = (_isFocused || isActiveAi) ? 1.8 : 1.0;

    final containerColor = colorScheme.surfaceContainerLowest;

    final outerRadius = widget.height / 2;
    const innerRadius = 6.0;

    final mainBorderRadius = hasSplitMenu
        ? BorderRadiusDirectional.only(
            topStart: Radius.circular(outerRadius),
            bottomStart: Radius.circular(outerRadius),
            topEnd: const Radius.circular(innerRadius),
            bottomEnd: const Radius.circular(innerRadius),
          ).resolve(Directionality.of(context))
        : BorderRadius.circular(outerRadius);

    final menuBorderRadius = _isSplitMenuOpen
        ? BorderRadius.circular(outerRadius)
        : BorderRadiusDirectional.only(
            topStart: const Radius.circular(innerRadius),
            bottomStart: const Radius.circular(innerRadius),
            topEnd: Radius.circular(outerRadius),
            bottomEnd: Radius.circular(outerRadius),
          ).resolve(Directionality.of(context));

    final shadows = [
      BoxShadow(
        color: Colors.black.withValues(alpha: _isFocused ? 0.12 : (_isHovered ? 0.08 : 0.04)),
        blurRadius: _isFocused ? 16 : (_isHovered ? 10 : 4),
        offset: Offset(0, _isFocused ? 6 : 2),
      ),
      if (isActiveAi)
        BoxShadow(
          color: colorScheme.primary.withValues(alpha: 0.18),
          blurRadius: 12,
          spreadRadius: 1,
          offset: const Offset(0, 2),
        ),
    ];

    final mainSearchContainer = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      height: widget.height,
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: mainBorderRadius,
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: shadows,
      ),
      child: Row(
        children: [
          // Leading Search Icon
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 16, end: 12),
            child: AnimatedRotation(
              turns: _isFocused ? 0.05 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                widget.leadingIcon ?? (isActiveAi ? Icons.auto_awesome_rounded : Icons.search_rounded),
                size: 24,
                color: isActiveAi
                    ? colorScheme.primary
                    : (_isFocused ? colorScheme.primary : colorScheme.onSurfaceVariant),
              ),
            ),
          ),

          // Search Text Field - Completely seamless without nested borders or background
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              onChanged: widget.onChanged,
              onSubmitted: (val) {
                _hideSuggestionsOverlay();
                widget.onSubmitted?.call(val);
              },
              textInputAction: TextInputAction.search,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText ?? 'ابحث بالمنطقة أو اسم العقار...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                ),
                isDense: true,
                filled: false,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          // Trailing Action 1: Clear button (X)
          if (_hasText)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              tooltip: 'مسح',
              color: colorScheme.onSurfaceVariant,
              onPressed: () {
                widget.controller.clear();
                widget.onClear?.call();
                widget.onChanged?.call('');
              },
            ),

          // Trailing Action 2: Visual Camera Search Button
          if (widget.onVisualSearch != null)
            Tooltip(
              message: 'البحث بالصور والطراز',
              child: InkWell(
                onTap: widget.onVisualSearch,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsetsDirectional.only(end: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.photo_camera_outlined,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),

          // Trailing Action 3: AI Semantic Search Sparkle Icon Button
          if (widget.onToggleSemantic != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: Tooltip(
                message: 'البحث الدلالي الذكي بالذكاء الاصطناعي',
                child: InkWell(
                  onTap: widget.onToggleSemantic,
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isActiveAi ? colorScheme.primary : colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 18,
                      color: isActiveAi ? colorScheme.onPrimary : colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    Widget searchBarContent;

    if (hasSplitMenu) {
      // Official Google M3 Expressive Split Button Menu
      // Morphs dynamically to a standalone circle on open, with solid background color and rotating chevron
      final splitMenuButton = AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: widget.height,
        height: widget.height,
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: menuBorderRadius,
          border: Border.all(
            color: _isSplitMenuOpen ? colorScheme.primary : borderColor,
            width: _isSplitMenuOpen ? 1.8 : borderWidth,
          ),
          boxShadow: _isSplitMenuOpen
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : shadows,
        ),
        child: Material(
          color: Colors.transparent,
          child: Theme(
            data: theme.copyWith(
              popupMenuTheme: PopupMenuThemeData(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                color: colorScheme.surfaceContainerHigh,
                elevation: 6,
                surfaceTintColor: Colors.transparent,
              ),
            ),
            child: PopupMenuButton<String>(
              tooltip: 'خيارات البحث / Search options',
              enabled: widget.splitMenuItems!.isNotEmpty,
              borderRadius: _isSplitMenuOpen ? BorderRadius.circular(outerRadius) : menuBorderRadius,
              offset: const Offset(0, 58),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 260, maxWidth: 360),
              onOpened: () => setState(() => _isSplitMenuOpen = true),
              onCanceled: () => setState(() => _isSplitMenuOpen = false),
              onSelected: (val) {
                setState(() => _isSplitMenuOpen = false);
                widget.onSplitMenuItemSelected?.call(val);
              },
              icon: AnimatedRotation(
                turns: _isSplitMenuOpen ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 24,
                  color: _isSplitMenuOpen
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              itemBuilder: (context) {
                return widget.splitMenuItems!.map((item) {
                  final isSelected = widget.selectedSplitMenuValue != null &&
                      widget.selectedSplitMenuValue == item.value;
                  return PopupMenuItem<String>(
                    value: item.value,
                    enabled: item.enabled,
                    height: item.subtitle != null ? 56 : 46,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: isSelected
                          ? BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            )
                          : null,
                      child: Row(
                        children: [
                          if (item.icon != null) ...[
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                item.icon,
                                size: 16,
                                color: isSelected
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.label,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                                  ),
                                ),
                                if (item.subtitle != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    item.subtitle!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 11,
                                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      );

      searchBarContent = SizedBox(
        height: widget.height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: mainSearchContainer),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: _isSplitMenuOpen ? 8.0 : 3.0,
            ),
            splitMenuButton,
          ],
        ),
      );
    } else {
      searchBarContent = mainSearchContainer;
    }

    return CompositedTransformTarget(
      link: _layerLink,
      key: _anchorKey,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: searchBarContent,
      ),
    );
  }
}
