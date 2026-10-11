# Material Design 3 (M3) — Master Design System & Architectural Standards
> **Authoritative Specification & Implementation Manual for AI Agents & Engineers**  
> *Derived from Google Material Design 3 guidelines, adapted for Enterprise PropTech & Multi-tenant Platforms.*

---

## 📋 Table of Contents
1. [Core Design Philosophy & Foundational Rules](#1-core-design-philosophy--foundational-rules)
2. [Dynamic Seed Color & Primary-Derived Hover Engine](#2-dynamic-seed-color--primary-derived-hover-engine)
3. [The 10 Official M3 Button Types Suite](#3-the-10-official-m3-button-types-suite)
4. [The M3 Shaded Close Button Standard ('X')](#4-the-m3-shaded-close-button-standard-x)
5. [The 3 Official M3 Card Types & Interactive States](#5-the-3-official-m3-card-types--interactive-states)
6. [Card Measurements, Hierarchy & Interactive Controls](#6-card-measurements-hierarchy--interactive-controls)
7. [The Official M3 Carousels Suite](#7-the-official-m3-carousels-suite)
8. [The Official M3 Tabs Suite](#8-the-official-m3-tabs-suite)
9. [The Official M3 Chips Suite](#9-the-official-m3-chips-suite)
10. [The Official M3 Dialogs & Modals Suite](#10-the-official-m3-dialogs--modals-suite)
11. [The Official M3 Dividers Suite & Rules](#11-the-official-m3-dividers-suite--rules)
12. [The Official M3 Lists & Reorderable Drag Suite](#12-the-official-m3-lists--reorderable-drag-suite)
13. [The Official M3 Loading Indicators Suite](#13-the-official-m3-loading-indicators-suite)
14. [The Official M3 Progress Indicators Suite (Flat & Wavy)](#14-the-official-m3-progress-indicators-suite-flat--wavy)
15. [The Official M3 Navigation Drawer Suite](#15-the-official-m3-navigation-drawer-suite)
16. [The Official M3 Navigation Rail & Nested Canvas Architecture](#16-the-official-m3-navigation-rail--nested-canvas-architecture)
17. [The Official M3 Dropdown Menus Suite](#17-the-official-m3-dropdown-menus-suite)
18. [The Official M3 Sliders Suite](#18-the-official-m3-sliders-suite)
19. [The Official M3 Search & Suggestions View Suite](#19-the-official-m3-search--suggestions-view-suite)
20. [The Official M3 Switches & Selection Controls Suite](#20-the-official-m3-switches--selection-controls-suite)
21. [The Official M3 SnackBars & Floating Notifications Suite](#21-the-official-m3-snackbars--floating-notifications-suite)
22. [The Official M3 Motion & Transitions Suite](#22-the-official-m3-motion--transitions-suite)
23. [Card Filtering Motion Architecture](#23-card-filtering-motion-architecture)
24. [Strict BiDi & LTR Numeric Input Protocol](#24-strict-bidi--ltr-numeric-input-protocol)
25. [Trilingual Architecture & Linguistic Purity (AR, EN, HI)](#25-trilingual-architecture--linguistic-purity-ar-en-hi)
26. [Comprehensive Verification Checklist for AI Agents](#26-comprehensive-verification-checklist-for-ai-agents)

---

## 1. Core Design Philosophy & Foundational Rules

1. **`useMaterial3: true` is strictly mandatory** across all light and dark themes.
2. **Surface Container Hierarchy over Skeuomorphic Dropshadows:** Never use harsh manual `BoxShadow(blurRadius: 20, color: Colors.black54)`. Material Design 3 replaces legacy elevation shadows with tonal surface tiers:
   - `surfaceContainerLowest`: Deepest background canvas (e.g. app workspace background).
   - `surfaceContainerLow`: Low elevated background (e.g. inner body canvas).
   - `surfaceContainer`: Baseline container surface (e.g. cards, banners).
   - `surfaceContainerHigh`: Elevated containers (e.g. connected button group tracks).
   - `surfaceContainerHighest`: Interactive resting containers, input fields, and shaded icon buttons.
3. **1px Outline Variant System:** Use `Border.all(color: theme.colorScheme.outlineVariant, width: 1.0)` for clean, crisp structural boundaries across light and dark modes.
4. **Strict Single-Icon Rule:** Every button, chip, and interactive segment must contain at most **ONE single icon**. Never combine a Flutter `Icon` widget with an emoji in the text label.
5. **No Raw Hardcoded Strings:** Zero hardcoding of user-facing strings. All strings must use centralized localization dictionaries with 100% trilingual parity.
6. **Directionality Awareness:** Never hardcode directional insets (`EdgeInsets.only(left: 16)`). Always use `EdgeInsetsDirectional.only(start: 16, end: 16)` so layouts adapt seamlessly between RTL and LTR.

---

## 2. Dynamic Seed Color & Primary-Derived Hover Engine

### 2.1 The 5 Canonical Seed Palettes
The design system dynamically derives its full M3 palette from a single seed color:
- **Warm Terracotta (Brown):** `#8F4C38`
- **Forest Olive (Green):** `#2E6B48`
- **Ocean Blue (Royal Blue):** `#0061A4`
- **Slate Navy (Deep Slate):** `#0F172A` (Default Primary)
- **Emerald Teal (Teal):** `#006874`

### 2.2 Dynamic Primary-Derived Hover Engine (`M3HoverColorScheme`)
All hover overlays, borders, active pills, and interaction highlights must dynamically scale from the active seed color:
- **Primary Darkened Hover (`primaryDarkenedHover`):** Filled primary buttons and active pills darken slightly on hover:
  - Light Mode: `Color.lerp(primary, Colors.black, 0.10)!`
  - Dark Mode: `Color.lerp(primary, Colors.white, 0.12)!`
- **Primary Hover State Layer (`primaryHoverStateLayer`):** Cards and unselected buttons receive a 6% to 8% tint of `primary` on hover: `primary.withValues(alpha: 0.08)`.
- **Primary Hover Border (`primaryHoverBorder`):** Hovered borders transition to 42%–55% of `primary`: `primary.withValues(alpha: 0.48)`.
- **Primary Shadow Tinting:** Hovered floating cards receive subtle primary-tinted elevation shadows rather than dull grey shadows.

---

## 3. The 10 Official M3 Button Types Suite

Reference: `lib/core/design_system/buttons/tashil_buttons.dart`  
Google M3 Spec: [https://m3.material.io/components/all-buttons](https://m3.material.io/components/all-buttons)

| # | Button Type | Class Name | Visual Style | Elevation / States | Primary Use Case |
|---|-------------|------------|--------------|-------------------|------------------|
| 1 | Standard Button | `TashilButton` | Filled, Tonal, Outlined, Elevated, Text | M3 standard interactive states | Single prominent actions ("تسجيل الدخول", "حفظ") |
| 2 | Toggle Button | `TashilToggleButton` | Stateful Outline $\leftrightarrow$ Fill | Animated toggle transitions | Feature toggles, bookmarking, filter flags |
| 3 | Standard Icon Button | `TashilIconButton` | Circular: Standard, Filled, Tonal, Outlined | 40x40dp touch target, 24dp icon | Toolbar actions, quick triggers, table rows |
| 4 | Toggle Icon Button | `TashilToggleIconButton` | Circular outline/fill transition | Heart (favorite), Bookmark, Pin | Quick favorite toggles on cards |
| 5 | Split Button | `TashilSplitButton` | Compound button with caret popup | Primary action + popup menu | Save & Print, Export with sub-formats |
| 6 | Standard Button Group | `TashilStandardButtonGroup`| Row/wrap of standalone buttons | Grouped buttons with spacing | Secondary action clusters |
| 7 | Connected Button Group | `TashilConnectedButtonGroup<T>` | Continuous stadium capsule (24dp radius), floating inner active pill | 220ms `easeInOutCubic` motion, elevation shadow | View switches, mode toggles, status filters |
| 8 | Floating Action Button | `TashilFloatingActionButton`| Squircle FAB: Small (40dp), Regular (56dp), Large (96dp) | Level 3 elevation, hover lift | Focal screen actions ("طلب صيانة", "إضافة عقار") |
| 9 | Extended FAB | `TashilExtendedFloatingActionButton` | Squircle container with icon + label | Dynamic expansion/collapse | Screen-level creation triggers |
| 10 | FAB Menu (Speed Dial) | `TashilFabMenu` | Tiered expandable Speed Dial menu | Rotational close transform | Multi-action hero creation menus |

### 3.1 Connected Button Group Architecture (M3 Expressive)
- **Outer Track:** Continuous stadium capsule (`height: 42dp`, `borderRadius: BorderRadius.circular(21)`), filled with `surfaceContainerHigh`, padded with `3.5dp`, bordered with `outlineVariant.withValues(alpha: 0.4)`.
- **Inner Active Pill:** Concentric stadium pill (`height: 35dp`, `borderRadius: BorderRadius.circular(17.5)`), filled with `primary` (or `secondaryContainer` if tonal), `onPrimary` text/icon, floating elevation shadow (`BoxShadow(color: shadow.withValues(alpha: 0.12), blurRadius: 4, offset: Offset(0, 1.5))`).
- **Motion:** 220ms `Curves.easeInOutCubic`.
- **Shorthand Rule:** Whenever requested with *"حولهالي بنفس النمط"* or *"طبق الـ Connected Button Group"*, immediately implement `TashilConnectedButtonGroup<T>`.

---

## 4. The M3 Shaded Close Button Standard ('X')
> **قاعدة زر الإغلاق X المظلل**

All dismiss/close buttons with 'X' (`Icons.close_rounded`, `Icons.close`, `Icons.clear_rounded`, `TashilIconButton.close`) **MUST NEVER** be rendered as empty, transparent, or uncolored glyphs in their resting state.
1. **Resting State:** Must always feature a circular shaded background (`surfaceContainerHighest` or `surfaceContainerHigh`) with a subtle 1px border (`outlineVariant`).
2. **Hover State:** Visibly darkens upon hover (`Colors.black.withValues(alpha: 0.12)` in Light Mode, or `Colors.white.withValues(alpha: 0.14)` in Dark Mode) with scale and shadow tint.
3. **Pressed State:** Further darkens with a 10% ripple state layer.
4. **Consistency:** Mandatory across all dialogs, modals, banners, drawer headers, and search inputs.

---

## 5. The 3 Official M3 Card Types & Interactive States

Reference: `lib/core/design_system/cards/tashil_cards.dart`  
Google M3 Spec: [https://m3.material.io/components/cards](https://m3.material.io/components/cards)

### Interactive States Matrix

| Interactive State | Elevated Card (`TashilCard.elevated`) | Filled Card (`TashilCard.filled`) | Outlined Card (`TashilCard.outlined`) |
|-------------------|---------------------------------------|-----------------------------------|--------------------------------------|
| **Resting** | Level 1 (1dp elevation) | Level 0 (0dp), `surfaceContainer` | Level 0 (0dp), 1px `outlineVariant` border |
| **Hovered** | Level 2 (3dp elevation), 8% primary state layer, -3dp subtle lift | Level 1 (1dp), 8% state layer, -3dp lift | Level 1 (1dp), 8% primary state layer, 1px hover border, -3dp lift |
| **Focused** | Level 1 (1dp), 10% state layer, 3dp secondary focus ring | Level 0 (0dp), 10% state layer, 3dp focus ring | Level 0 (0dp), 10% state layer, 3dp focus ring |
| **Pressed** | Level 1 (1dp), 10% ripple | Level 0 (0dp), 10% ripple | Level 0 (0dp), 10% ripple |
| **Dragged** | Level 4 (8dp elevation), 16% state layer, lift shadow | Level 3 (6dp elevation), 16% state layer | Level 4 (8dp elevation), 16% state layer |
| **Disabled** | Level 0 (0dp), 38% content opacity | Level 0 (0dp), 38% opacity | Level 0 (0dp), 38% opacity, muted border |

---

## 6. Card Measurements, Hierarchy & Interactive Controls

### 6.1 Canonical Card Measurements
- **Shape:** `BorderRadius.circular(12)` (with `11dp` inner image clipping for 1dp outlined cards).
- **Left / Right Padding:** `16dp`.
- **Padding Between Cards:** `8dp` max (`crossAxisSpacing: 8`, `mainAxisSpacing: 8`).
- **Text Alignment:** Start-aligned (`CrossAxisAlignment.start` / `TextAlign.start`).

### 6.2 The 3 Canonical M3 Text Roles (`TashilCardText`)
1. **Headline:** Communicates the primary subject (`titleMedium`, bold).
2. **Subhead:** Smaller text elements such as location or byline with leading icon (`bodySmall`, `onSurfaceVariant`).
3. **Supporting text:** Description or summary (`bodySmall`, `onSurfaceVariant`, standardized to **1 single line** with ellipsis `...` followed by guaranteed visible clickable `linkedText` "اقرأ المزيد" opening details dialog).

### 6.3 The 4 Official M3 Card Interactive Controls
1. **Buttons:** Primary actions ("حجز معاينة", "عرض التفاصيل") using `TashilConnectedButtonGroup` or standard M3 buttons.
2. **Icon Buttons:** Contextual triggers (`TashilIconButton.outlined`, `TashilToggleIconButton`) for phone call (`Icons.phone_outlined`) and chat (`Icons.chat_bubble_outline_rounded`).
3. **Selection Controls:** Chips (`TashilAssistChip`), switches, or sliders embedded via `selectionControl`.
4. **Linked Text:** Clickable hyperlink embedded in supporting text via `linkedText` with underline and pointer cursor.

### 6.4 Pinned Action Footer Architecture
To guarantee zero edge clipping and symmetric card heights across responsive breakpoints:
- Card body content wrapped in `Expanded`.
- Preceded by full-width divider: `TashilDivider.cardAction()`.
- Pinned footer with 12dp bottom and 14dp horizontal padding.
- Calibrated responsive breakpoints: `<720` (mobile 1-col), `720-1180` (tablet 2-col), `1180-1550` (desktop 3-col), `>=1550` (wide 4-col).

---

## 7. The Official M3 Carousels Suite

Reference: `lib/core/design_system/carousel/tashil_carousels.dart`
- **`TashilCarousel.hero`:** Single focal item with end-peek, magnetic snapping, photo counter indicator, RTL/LTR awareness, and mouse/touch/trackpad swipe support via `TashilCarouselScrollBehavior`.
- **`TashilCarousel.multiBrowse`:** Dynamic multi-item carousel adapting item sizes and flex weights across screen breakpoints.
- **`TashilCarousel.uncontained`:** Continuous uniform-item horizontal carousel.

---

## 8. The Official M3 Tabs Suite

Reference: `lib/core/design_system/tabs/tashil_tabs.dart`  
Google M3 Spec: [https://m3.material.io/components/tabs/specs](https://m3.material.io/components/tabs/specs)

- **`TashilPrimaryTabBar`:** 48dp or 64dp container height, 3dp rounded pill indicator, active/inactive color transitions, full-width bottom divider, responsive equal-width distribution.
- **`TashilSecondaryTabBar`:** 44–48dp container height, 2dp underline indicator for sub-views and filter segmentation.

---

## 9. The Official M3 Chips Suite

Reference: `lib/core/design_system/chips/tashil_chips.dart`  
Google M3 Spec: [https://m3.material.io/components/chips/overview](https://m3.material.io/components/chips/overview)

- **Container Specs:** 32dp height, 8dp squircle corner radius (`BorderRadius.circular(8)`).
- **`TashilAssistChip`:** Smart contextual action chip with leading 18dp semantic icon (Outlined, Elevated, Tonal variants).
- **`TashilFilterChip`:** Multi-criteria filtering with animated checkmark indicator.
- **`TashilInputChip`:** Discrete entry tags with trailing remove action ('X').
- **`TashilSuggestionChip`:** Recommendation and AI prompt shortcuts.

---

## 10. The Official M3 Dialogs & Modals Suite

Reference: `lib/core/design_system/dialogs/tashil_dialogs.dart`  
Google M3 Spec: [https://m3.material.io/components/dialogs/overview](https://m3.material.io/components/dialogs/overview)

- **`TashilAlertDialog`:** 28dp extra-large corner radius, Level 3 tonal elevation, optional 24dp top icon, headlineSmall, supporting text, end-aligned action buttons.
- **`TashilModalDialog`:** 28dp squircle radius, structured header with icon badge & M3 shaded close button, scrollable body, pinned action footer.
- **`TashilSelectionDialog`:** 28dp radius, option list with checkmarks & flag/icon badges.

---

## 11. The Official M3 Dividers Suite & Rules

Reference: `lib/core/design_system/dividers/tashil_dividers.dart`  
Google M3 Spec: [https://m3.material.io/components/divider/guidelines](https://m3.material.io/components/divider/guidelines)

### The 6 Types
1. `TashilDivider.fullWidth`: 100% container width, 1dp thickness, `colorScheme.outlineVariant`.
2. `TashilDivider.cardAction`: Separates non-interactive card content from interactive action footer.
3. `TashilDivider.inset`: Start-inset divider aligning with text after leading avatars/icons.
4. `TashilDivider.middleInset`: Symmetrical start and end insets for padded containers.
5. `TashilVerticalDivider`: 1dp vertical divider for toolbars and stat groups.
6. `TashilDivider.withLabel`: Labelled divider with inline text badge (e.g. "أو" / "OR").

### Card Dividers DO vs CAUTION Guidelines
- **Rule 1 (Full-width in Cards):** Use full-width dividers (`TashilDivider.cardAction()`) spanning 100% border-to-border to separate non-interactive container content from interactive action areas (card footers, dialog footers).
- **Rule 2 (Inset in Cards):** Use inset dividers (`TashilDivider.middleInset()`, `TashilDivider.inset()`) which do not run the full width of a card to separate related content inside cards.
- **CAUTION Guideline:** Use full-width dividers sparingly. Too many divider lines make an interface look cluttered. Do not place dividers between every row in tight lists when whitespace suffices.

---

## 12. The Official M3 Lists & Reorderable Drag Suite

Reference: `lib/core/design_system/lists/tashil_lists.dart`  
Google M3 Spec: [https://m3.material.io/components/lists/guidelines](https://m3.material.io/components/lists/guidelines)

- **Height Tokens:** 1-line (`56dp` / `48dp` dense), 2-line (`72dp` / `64dp` dense), 3-line (`88dp`).
- **Insets & Gaps:** 16dp directional horizontal insets; 16dp gap between leading, text column, and trailing items.
- **`TashilReorderableList`:** Level 3 tonal elevation floating proxy card, rounded squircle corners, smooth reordering physics.
- **`TashilReorderHandle`:** Drag handle with `Icons.drag_indicator_rounded` supporting immediate desktop mouse drag without delay and mobile touch hold.

---

## 13. The Official M3 Loading Indicators Suite

Reference: `lib/core/design_system/loading/tashil_loading.dart`  
Google M3 Spec: [https://m3.material.io/components/loading-indicator/overview](https://m3.material.io/components/loading-indicator/overview)

- **Visual Architecture:** Replaces legacy circular progress rings with an organic 4-petal morphing clover/squircle shape, smooth continuous rotation, and harmonic breathing pulse.
- **Size Hierarchy:**
  - Small (`24dp`): For buttons, chips, and inline items.
  - Medium (`48dp`): Standard for cards, dialogs, and sections.
  - Large (`72dp`): Prominent for full-page hydration and AI valuation.
- **Container Variant:** `hasContainer: true` wrapping the indicator in a Level 2 elevated surface container for pull-to-refresh interactions.
- **`TashilLoadingOverlay`:** Frosted glass modal scrim with backdrop filter blur, absorb-pointer shield, and localized status updates.

---

## 14. The Official M3 Progress Indicators Suite (Flat & Wavy)

Reference: `lib/core/design_system/progress/tashil_progress.dart`  
Google M3 Spec: [https://m3.material.io/components/progress-indicators/overview](https://m3.material.io/components/progress-indicators/overview)

### Linear Progress (`TashilLinearProgressIndicator`)
- **Modes:** Flat (standard pill) and Wavy (sinusoidal wave with 40dp wavelength & 3.5dp amplitude).
- **Execution:** Determinate (0.0 to 1.0) and Indeterminate continuous wave flow.
- **Signature Tokens:** 4dp Stop Indicator dot at the 100% position, 4dp Stop Gap, 4dp container edge insets.
- **Directionality:** 100% RTL/LTR directionality awareness.

### Circular Progress (`TashilCircularProgressIndicator`)
- **Modes:** Flat standard ring and Wavy undulating arc.
- **Size Tokens:** Small (40dp), Medium (44dp), Standard (48dp), Large (52dp).
- **Tokens:** 4dp Stop Indicator dot on determinate completion.

---

## 15. The Official M3 Navigation Drawer Suite

Reference: `lib/core/design_system/drawer/tashil_navigation_drawer.dart`  
Google M3 Spec: [https://m3.material.io/components/navigation-drawer/overview](https://m3.material.io/components/navigation-drawer/overview)

- **`TashilNavigationDrawer.standard`:** Persistent/collapsible sidebar for desktop & tablet $\ge 840dp$, animated 250ms cubic easing between 260dp and 76dp rail mode with tooltips.
- **`TashilNavigationDrawer.modal`:** Sliding drawer for mobile $<600dp$ with Level 1 elevation and 28dp rounded corner on trailing edge.
- **`TashilDrawerDestination`:** 56dp height, 28dp full stadium pill shape, 12dp directional margins, leading 24dp icon, active `secondaryContainer`/`onSecondaryContainer`, inactive `onSurfaceVariant`, numeric badge counters, and 4 interactive state layers (Enabled, Hover 8%, Focus 10%, Press 10%).

---

## 16. The Official M3 Navigation Rail & Nested Canvas Architecture

Reference: `lib/core/design_system/navigation_rail/tashil_navigation_rail.dart` & `tashil_scaffold_canvas.dart`

- **`TashilNavigationRail`:** 80dp compact rail width with 56x32dp active indicator pill, icon with label directly underneath, numeric badge counters, and animated transition to 260dp expanded drawer mode with 250ms cubic easing.
- **`TashilRailDestination`:** Dual-mode destination (vertical in 80dp rail, horizontal in 260dp drawer).
- **`TashilScaffoldCanvas` (Nested Canvas Architecture):**
  - **Outer Canvas:** Top header and navigation rail share unified `surfaceContainerLowest` canvas with **zero dividing lines**.
  - **Inner Body Canvas:** Nested workspace body container is nested with `surfaceContainerLow` and a prominent 28dp rounded top-start corner via `BorderRadiusDirectional.only(topStart: Radius.circular(28))` adapting seamlessly between RTL and LTR.

---

## 17. The Official M3 Dropdown Menus Suite

Reference: `lib/core/design_system/menus/tashil_menus.dart`  
Google M3 Spec: [https://m3.material.io/components/menus/guidelines](https://m3.material.io/components/menus/guidelines)

- **`TashilDropdownMenu<T>`:** Outlined form field anchor with floating/header label, 180° animated caret rotation, Level 2 elevation floating menu container with 12dp squircle corners, and smooth 250ms top-to-bottom unfolding motion using `Curves.easeOutCubic`.
- **`TashilDropdownMenuItem<T>`:** 48dp standard touch height, 12dp directional insets, leading semantic icon, optional supporting text, highlighted `secondaryContainer` selected pill container, and trailing checkmark `Icons.check_rounded` for active selections.

---

## 18. The Official M3 Sliders Suite

Reference: `lib/core/design_system/sliders/tashil_sliders.dart`  
Google M3 Spec: [https://m3.material.io/components/sliders/guidelines](https://m3.material.io/components/sliders/guidelines)

- **Track:** 16dp expressive track height with full stadium ends.
- **Signature 6dp Stop Gap:** Visible 6dp gap explicitly separating active track, handle, and inactive track.
- **Handle Types:** `verticalBar` (4x44dp pill handle) or `round` (20dp thumb).
- **Floating Balloon:** Animated floating value indicator balloon with `Curves.easeOutBack` spring physics.
- **State Layer:** 40/44dp state layer aura and discrete stop indicator dots.

---

## 19. The Official M3 Search & Suggestions View Suite

Reference: `lib/core/design_system/search/tashil_search.dart` & `tashil_search_bar.dart`  
Google M3 Spec: [https://m3.material.io/components/search/overview](https://m3.material.io/components/search/overview)

- **`TashilSearchBar`:** 56dp standard height with 28dp full stadium pill shape, smooth 220ms hover and focus scale (1.008x) and Level 2 elevation transitions, leading search icon, instant clear action ('X'), visual photo search button, and AI semantic vector search badge.
- **Search View Overlay:** Downwards unfolding suggestions view with 240ms cubic easing, rounded squircle corners, elevation shadow, and pure trilingual parity.

---

## 20. The Official M3 Switches & Selection Controls Suite

Reference: `lib/core/design_system/switches/tashil_switches.dart`  
Google M3 Spec: [https://m3.material.io/components/switch/specs](https://m3.material.io/components/switch/specs)

- **Track:** 52dp width x 32dp height, full stadium rounded ends (`Radius.circular(16)`).
- **Unselected:** `surfaceContainerHighest` fill with 2dp `outline` border and 16dp `outline` handle circle.
- **Selected:** Solid `primary` fill without outline with 24dp `onPrimary` handle circle and animated checkmark `✓` icon (`Icons.check_rounded`, 16dp) inside handle.
- **Pressed State:** Handle expands dynamically to 28dp.
- **State Layer:** 40dp circular aura centered on handle.
- **Motion:** 250ms cubic easing (`Curves.easeInOutCubic`).
- **`TashilSwitchListTile`:** Full-row tap integration combining title, subtitle, leading icon, and trailing `TashilSwitch`.

---

## 21. The Official M3 SnackBars & Floating Notifications Suite

Reference: `lib/core/design_system/snackbars/tashil_snackbars.dart`  
Google M3 Spec: [https://m3.material.io/components/snackbar/overview](https://m3.material.io/components/snackbar/overview)

- **Variants:** `TashilSnackBar.show`, `showSuccess`, `showError`, `showWarning`, `showInfo`.
- **Behavior & Elevation:** `SnackBarBehavior.floating` with Level 3 tonal elevation (6dp) and 8dp squircle radius (`BorderRadius.circular(8.0)`).
- **Dynamic Seed Palette Derivation:** Container and action colors automatically derived from active seed palette (`inverseSurface`, `inverseOnSurface`, `inversePrimary`).
- **Responsive Centered Width:** Fixed max-width `min(screenWidth - 32, 520)` centered on desktop/tablet to strictly eliminate edge-to-edge stretching, with 16dp responsive margins on mobile.
- **Strict Single-Action Rule:** Maximum of 1 action button per snackbar (`TashilSnackBarAction`), preventing dialog abuse.
- **Close Affordance:** Optional 24dp shaded close button ('X').
- **Dismissal Hygiene:** Automatic previous notification dismissal (`ScaffoldMessenger.of(context).hideCurrentSnackBar()`) to prevent queue stacking.

---

## 22. The Official M3 Motion & Transitions Suite

Reference: `lib/core/design_system/motion/tashil_motion.dart`  
Google M3 Spec: [https://m3.material.io/styles/motion/overview/specs](https://m3.material.io/styles/motion/overview/specs)

### 22.1 Easing Tokens (`TashilMotionEasing`)
- **Prohibition:** Strictly prohibits `Curves.linear` for spatial or sizing movements.
- **Emphasized Family (Signature M3 Motion):**
  - `emphasized`: `Cubic(0.2, 0.0, 0.0, 1.0)` for elements beginning and ending on-screen.
  - `emphasizedDecelerate`: `Cubic(0.05, 0.7, 0.1, 1.0)` for elements entering the screen bounds.
  - `emphasizedAccelerate`: `Cubic(0.3, 0.0, 0.8, 0.15)` for elements permanently exiting the screen bounds.
- **Standard Family:**
  - `standard`: `Cubic(0.2, 0.0, 0.0, 1.0)`
  - `standardDecelerate`: `Cubic(0.0, 0.0, 0.2, 1.0)`
  - `standardAccelerate`: `Cubic(0.4, 0.0, 1.0, 1.0)`

### 22.2 The 16 Duration Tokens (`TashilMotionDuration`)
- **Short (Micro-interactions & Dismissals):** `short1` (50ms), `short2` (100ms), `short3` (150ms), `short4` (200ms).
- **Medium (Surface Transitions & Entrances):** `medium1` (250ms), `medium2` (300ms), `medium3` (350ms), `medium4` (400ms).
- **Long (Hero Container Expansions):** `long1` (450ms), `long2` (500ms), `long3` (550ms), `long4` (600ms).
- **Extra-Long (Onboarding & Screen Transformations):** `extraLong1` (700ms), `extraLong2` (800ms), `extraLong3` (900ms), `extraLong4` (1000ms).
- **The Faster Exit Law:** Exits must always be faster (~50%) than entrances (e.g. 300ms entrance $\rightarrow$ 150ms exit).

### 22.3 Physics Springs (`TashilMotionSpring`)
- **Critically Damped (`standard`):** Mass 1.0, stiffness 300.0, damping 34.64 ($\zeta = 1.0$) reaching destination swiftly with zero overshoot.
- **Expressive Bouncy (`expressiveBouncy`):** Mass 1.0, stiffness 320.0, damping 27.15 ($\zeta \approx 0.76$) with tactile bounce for gesture releases and card snaps.
- **Gentle (`gentle`):** Mass 1.0, stiffness 180.0, damping 26.83 ($\zeta = 1.0$).

### 22.4 The 4 Canonical Transition Patterns (`TashilTransitions`)
1. **Container Transform:** Seamlessly expands a compact card or button into a detailed view or full screen with matched elevation and corner radius.
2. **Shared Axis:**
   - **X-Axis:** Horizontal forward/backward navigation with **100% RTL/LTR directionality awareness** (in Arabic, next slides from left to right; in English, next slides from right to left).
   - **Y-Axis:** Vertical step/stepper navigation.
   - **Z-Axis:** Depth zoom in/out for drill-downs.
3. **Fade Through:** Top-level navigation rail and bottom bar destination switches.
4. **Fade:** Transient dialogs, menus, and backdrop scrims.

---

## 23. Card Filtering Motion Architecture
> **معيار موشن وانتقالات الفلترة بين الكروت**

Whenever filtering cards across properties, leases, or invoices:
1. **No Instant Cuts:** Never instantly wipe or pop cards without transition.
2. **Height Morphing:** Wrap the card container in `AnimatedSize` with 300ms `emphasized` curve.
3. **Cascaded Staggered Entrance:** Incoming cards enter via `TashilStaggeredEntrance` with 35ms stagger step and 18dp `expressiveFastSpatial` slide.
4. **Fast Dissolve Exit:** Departing cards dissolve rapidly using 150ms `emphasizedAccelerate`.
5. **Empty State:** Smoothly scales and fades when zero results match.
6. **Shorthand Rule:** Whenever requested with *"إعملي نظام الفلترة"*, link `TashilConnectedButtonGroup` directly with `TashilCardFilterMotion<T>`.

---

## 24. Strict BiDi & LTR Numeric Input Protocol
> **قاعدة اتجاه الأرقام والمدخلات الرقمية الصارمة (LTR)**

### The Core Rule
All inputs and displays containing **pure numbers, phone numbers, financial amounts, codes, credit cards, dates, or identifiers MUST BE STRICTLY LTR** (`textDirection: TextDirection.ltr`, `textAlign: TextAlign.left`) regardless of active locale (Arabic, English, Hindi).

### Mandatory Field Specifications
1. **Credit Card Number:**
   - `textDirection: TextDirection.ltr`, `textAlign: TextAlign.left`, `keyboardType: TextInputType.number`.
   - Prefix icon on the LEFT.
   - Displays chunks in correct order: `4111 2222 3333 4444`.
2. **Card Expiry Date & CVV Row:**
   - The entire `Row` must have `textDirection: TextDirection.ltr` so that **Expiry Date is on the LEFT** and **CVV is on the RIGHT**.
   - Expiry Date: `textDirection: TextDirection.ltr`, `textAlign: TextAlign.left` (`12/28`).
   - CVV: `textDirection: TextDirection.ltr`, `textAlign: TextAlign.left` (`•••`).
3. **Phone Numbers & Country Dial Codes:**
   - Dial code container (e.g. `+20` or `+971`) on the LEFT; phone number input on the RIGHT.
   - `textDirection: TextDirection.ltr`, `textAlign: TextAlign.left`.
4. **National IDs, Emirates IDs & Alphanumeric Codes:**
   - `textDirection: TextDirection.ltr`, `textAlign: TextAlign.left`.
5. **Contract Numbers, Invoices, Fawry Codes & IBANs:**
   - `textDirection: TextDirection.ltr`, `textAlign: TextAlign.left`.

---

## 25. Trilingual Architecture & Linguistic Purity (AR, EN, HI)
> **معيار النقاء اللغوي التام**

### 25.1 Supported Locales
1. **Arabic (`ar`) — Primary / Default:**
   - Direction: Right-to-Left (RTL).
   - Typography: `GoogleFonts.cairoTextTheme()` with M3 token hierarchy.
   - Layout: Logo starts on the Right; actions end on the Left.
2. **English (`en`):**
   - Direction: Left-to-Right (LTR).
   - Typography: `GoogleFonts.interTextTheme()` / `Outfit`.
   - Layout: Logo starts on the Left; actions end on the Right.
3. **Hindi (`hi`):**
   - Direction: Left-to-Right (LTR).
   - Typography: `GoogleFonts.notoSansDevanagariTextTheme()` / `Poppins`.
   - Terminology: Accurate Devanagari PropTech and financial terms.

### 25.2 Zero Language Mixing Rules
- **No Mixed Parentheses:** Never combine English parentheses inside Arabic dictionary strings (e.g. ❌ `الوكالة (Agency)`, ✅ `وكالة عقارية`).
- **No Transliterated Slang:** Never mix Arabic or Hindi words into English or vice-versa. Output 100% pure language per selected locale.
- **Mandatory Tri-Language Parity:** Every new key added in `app_localizations.dart` must exist simultaneously in `'ar'`, `'en'`, and `'hi'`.
- **Dynamic Reactivity:** Screens must listen to `LocaleController.currentLocale` via `ValueListenableBuilder<Locale>` for zero-refresh updates.

---

## 26. Comprehensive Verification Checklist for AI Agents

Before committing any UI code, the AI Agent must verify:
- [ ] `flutter analyze` reports **0 issues**.
- [ ] `useMaterial3: true` enabled across all themes.
- [ ] Surface hierarchy used (`surfaceContainerLow`, `surfaceContainer`, `outlineVariant`) with zero harsh manual drop shadows.
- [ ] Buttons adhere to the 10 official types; `TashilConnectedButtonGroup` used for multi-option switches.
- [ ] All close buttons ('X') have circular shaded backgrounds in resting state.
- [ ] Single-icon rule obeyed (max 1 icon per button/chip, zero emojis in label text).
- [ ] All cards use M3 measurements (12dp radius, 16dp pad, 8dp gap) and pinned action footer architecture.
- [ ] All numeric inputs (phones, cards, IDs, amounts) have `textDirection: TextDirection.ltr` and `textAlign: TextAlign.left`.
- [ ] All directional insets use `EdgeInsetsDirectional`.
- [ ] Zero raw user-facing strings; 100% trilingual dictionary parity in Arabic, English, and Hindi.
- [ ] Motion curves use Emphasized / Standard curves; zero `Curves.linear` for spatial movement.
