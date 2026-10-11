# Tashil Real Estate — Agent Instructions & Standards

Welcome to the Tashil Real Estate PropTech SaaS ecosystem. Whenever an AI Agent performs any task on this repository, it MUST strictly adhere to the following core architectural, design, and multilingual rules:

---

## 1. Trilingual Architecture (AR, EN, HI)
The platform natively supports 3 languages:
1. **Arabic (`ar`)** — Default / Primary:
   - **Direction:** Right-to-Left (RTL).
   - **Typography:** `GoogleFonts.cairoTextTheme()` with M3 token hierarchy.
   - **Layout:** Logo & Brand identity start on the **Right**; Language selector & action buttons end on the **Left**. Form labels, search icons, and cards MUST flow RTL.
2. **English (`en`)**:
   - **Direction:** Left-to-Right (LTR).
   - **Typography:** `GoogleFonts.interTextTheme()` / `Outfit`.
   - **Layout:** Logo starts on the **Left**; actions end on the **Right**.
3. **Hindi (`hi`)** — UAE & Regional Expats:
   - **Direction:** Left-to-Right (LTR).
   - **Typography:** `GoogleFonts.notoSansDevanagariTextTheme()` / `Poppins`.
   - **Terminology:** Accurate Devanagari PropTech and real estate terms.

---

## 2. Localization Implementation Rules (i18n)
- **Reference Skill & Rule:** `.agents/skills/trilingual-proptech-i18n/SKILL.md` and `.agents/rules/multilingual-ui-guidelines.md`.
- **Centralized Dictionary:** All user-facing strings MUST be defined in `frontend/lib/core/localization/app_localizations.dart` under their respective language keys (`'ar'`, `'en'`, `'hi'`).
- **Zero Language Mixing (معيار النقاء اللغوي التام):**
  * Never mix English words or parentheses inside Arabic dictionary strings (e.g. ❌ `الوكالة (Agency)`, ✅ `وكالة عقارية`).
  * Never mix Arabic or Hindi into English or vice-versa. Output 100% pure language per selected locale.
- **Mandatory Tri-Language Parity:** Every new key added to the dictionary MUST be populated in `'ar'`, `'en'`, and `'hi'` simultaneously.
- **Zero Hardcoding:** Never hardcode raw display strings in widgets. Always use `AppLocalizations.of(context).tr('key')`.
- **Screen Reactivity Protocol:** All screens MUST listen to `LocaleController.currentLocale` via `ValueListenableBuilder<Locale>` so language switching updates all text instantaneously.
- **Directionality Awareness:** Never hardcode directional insets (e.g. `EdgeInsets.only(left: 16)`). Use `EdgeInsetsDirectional.only(start: 16, end: 16)` so layouts automatically adapt between RTL and LTR.

---

## 3. Material Design 3 (M3) Standards & Button Taxonomy (The 10 Official Types)
- `useMaterial3: true` is mandatory across all themes.
- Single Seed Color generation: `ColorScheme.fromSeed(seedColor: Color(0xFF0F172A), primary: Color(0xFF0F172A), secondary: Color(0xFF3B82F6), tertiary: Color(0xFFF59E0B))`.
- Reference the definitive component handbook: `.agents/skills/material-design-3/SKILL.md` and rule `.agents/rules/material-design-3-components.md`.
- **Dynamic Primary-Derived Hover Engine:** All hover states, overlays, borders, and active pill backgrounds MUST be dynamically derived from the active theme's primary seed color (`M3HoverColorScheme` extension in `theme_palette_controller.dart`). Active pills and filled primary buttons on hover must darken slightly (`primaryDarkenedHover` via `Color.lerp(primary, Colors.black, 0.10)` in Light Mode, or `Colors.white, 0.12` in Dark Mode). Cards and unselected buttons on hover receive `primaryHoverStateLayer` (6-8% of primary) and `primaryHoverBorder` (42-55% of primary) with primary shadow tinting, ensuring instant, seamless adaptation across all 5 seed palettes (Warm Terracotta brown `#8F4C38`, Forest Olive green `#2E6B48`, Ocean Blue `#0061A4`, Slate Navy `#0F172A`, Emerald Teal `#006874`).
- **The 10 Official M3 Button Types Suite (`lib/core/design_system/buttons/tashil_buttons.dart`):**
  1. `TashilButton` (Standard Button: Filled, Tonal, Outlined, Elevated, Text).
  2. `TashilToggleButton` (Stateful toggle button: Selected / Unselected).
  3. `TashilIconButton` (Circular icon button: Standard, Filled, Tonal, Outlined).
  4. `TashilToggleIconButton` (Stateful icon button with outline/fill transition).
  5. `TashilSplitButton` (Compound action button with dropdown popup menu & RTL/LTR awareness).
  6. `TashilStandardButtonGroup` (Standard row/wrap group of standalone buttons).
  7. `TashilConnectedButtonGroup` (Official Google M3 Expressive Connected Button Group replacing deprecated baseline SegmentedButtons: continuous `surfaceContainerHigh` stadium capsule, 24dp radius, inner floating active pill in `primary`/`secondaryContainer` with subtle elevation shadow, and 220ms `easeInOutCubic` animated transitions. Supports view switches, mode selections, and multi-option filters).
  8. `TashilFloatingActionButton` (Squircle FAB: Small, Regular, Large).
  9. `TashilExtendedFloatingActionButton` (Extended FAB with icon + label).
  10. `TashilFabMenu` (Tiered expandable Speed Dial FAB menu with animated close state).
  * **Shorthand Component Protocol ("حولهالي بنفس النمط" / "طبق الـ Connected Button Group"):** Whenever requested by the user to convert or apply buttons to the modern connected group style, the agent MUST immediately implement `TashilConnectedButtonGroup<T>` using `TashilConnectedButtonSegment` with strict single-icon / clean emoji leading standard and pure trilingual parity.
  * **The M3 Shaded Close Button Standard (قاعدة زر الإغلاق X المضلل):** All dismiss/close buttons with 'X' (`Icons.close_rounded`, `Icons.close`, `Icons.clear_rounded`, `TashilIconButton.close`) MUST NEVER be rendered as empty, transparent, or uncolored glyphs in their resting state. They MUST always feature a circular shaded background (`surfaceContainerHighest` or `surfaceContainerHigh`) in resting state, and visibly darken upon hover (`Colors.black, 0.12` in Light Mode, or `Colors.white, 0.14` in Dark Mode) with further darkening when pressed. This guarantees high affordance, avoids bare uncolored icons, and ensures consistency across all dialogs, modals, banners, and search inputs.
- **The 3 Official M3 Card Types & Interactive States Suite (`lib/core/design_system/cards/tashil_cards.dart`):**
  1. `TashilCard.elevated` (Elevated Card: Tonal shadow elevation for prominent floating containers. Fully conforms to Google M3 Interactive States across Light and Dark themes: Resting Level 1 1dp elevation; Hovered Level 2 3dp elevation with 8% state layer and subtle -3dp lift; Focused Level 1 1dp elevation with 10% state layer and official 3dp M3 secondary focus ring; Pressed Level 1 1dp elevation with 10% ripple; Dragged Level 4 8dp elevation with 16% state layer and lift shadow; Disabled Level 0 0dp elevation with 38% content opacity).
  2. `TashilCard.filled` (Filled Card: SurfaceContainer fill for analytical stats and metrics with focus and interaction state layers).
  3. `TashilCard.outlined` (Outlined Card: 1px outlineVariant border for properties, leases, and details. Fully conforms to Google M3 Interactive States across Light and Dark themes: Resting Level 0 0dp elevation, 1dp outlineVariant border; Hovered Level 1 1dp elevation with 8% state layer, 1dp outline, and subtle -3dp lift; Focused Level 0 0dp elevation with 10% state layer and official 3dp M3 secondary focus ring; Pressed Level 0 0dp elevation with 10% ripple; Dragged Level 4 8dp elevation with 16% state layer and lift shadow; Disabled Level 0 0dp elevation with 38% content opacity and muted border).
  * **Marketplace Property Card Standard (`PropertyCard`), M3 Card Measurements & Interactive Controls Suite:** All cards adhere to the official Google M3 Card Measurements: **Shape:** 12dp corner radius (with 11dp inner image clipping for 1dp outlined cards); **Left/right padding:** 16dp; **Padding between cards:** 8dp max (`crossAxisSpacing: 8`, `mainAxisSpacing: 8`); **Label text alignment:** Start-aligned (`CrossAxisAlignment.start` / `TextAlign.start`). **Official Google M3 Card Text Hierarchy (`TashilCardText`):** All card content MUST strictly follow the 3 canonical M3 text roles: (1) **Headline**: Communicates the primary subject of the card (`titleMedium`, bold); (2) **Subhead**: Smaller text elements such as an article byline or tagged location with leading icon (`bodySmall`, `onSurfaceVariant`); (3) **Supporting text**: Body content such as summary or property description (`bodySmall`, `onSurfaceVariant`, standardized strictly to 1 single line with ellipsis `...` followed by guaranteed visible clickable `linkedText` "اقرأ المزيد" opening `PropertyDetailsDialog` to ensure visual symmetry across all cards). **Official Google M3 Card Interactive Controls Suite (`lib/core/design_system/cards/tashil_cards.dart`):** Conforms to https://m3.material.io/components/cards/guidelines#actions: (1) **Buttons**: Standard action buttons or `TashilConnectedButtonGroup` for primary actions ("حجز معاينة" / "عرض التفاصيل"); (2) **Icon buttons**: Standalone outlined or tonal icon buttons (`TashilIconButton.outlined`, `TashilToggleIconButton`) for direct contextual triggers such as phone call (`Icons.phone_outlined`) and chat (`Icons.chat_bubble_outline_rounded`); (3) **Selection controls**: Chips (`TashilAssistChip`), checkboxes, and sliders embedded via `selectionControl`; (4) **Linked text**: Interactive, clickable hyperlink embedded in supporting text via `linkedText` and `onLinkedTextTap` with click cursor and underline styling. All property cards MUST use `TashilCard.outlined` with crisp 1dp outline boundary ensuring high contrast and sharp boundaries across Light & Dark backgrounds, zero dead space and zero edge/bottom button clipping via Pinned Action Footer Architecture (`contentWidgets` in `Expanded` directly above `TashilDivider.cardAction()`, followed by the pinned action buttons footer with generous 12dp bottom and 14dp side padding guaranteeing 100% visibility without edge clipping, combined with responsive dynamic `childAspectRatio` [0.66 to 0.80] and calibrated breakpoints [<720, 720-1180, 1180-1550, >=1550]), dedicated semantic icons for every data element (price `Icons.payments_outlined`, rating `Icons.star_rounded`, type `Icons.apartment_rounded`, location `Icons.location_on_outlined`, bedrooms `Icons.bed_outlined`, bathrooms `Icons.bathtub_outlined`, area `Icons.square_foot_outlined`, furnishing `Icons.weekend_outlined`, agency `Icons.business_rounded`), `TashilCardText` with clickable details link, amenity chips, followed by `TashilDivider.cardAction()` and the official `TashilConnectedButtonGroup` footer alongside quick contact icon buttons.
- **The Official M3 Carousel Suite (`lib/core/design_system/carousel/tashil_carousels.dart`):**
  1. `TashilCarousel.hero` (Single focal item with end-peek, magnetic snapping, photo counter indicator, RTL/LTR awareness, and mouse/touch swipe support for property cards).
  2. `TashilCarousel.multiBrowse` (Dynamic multi-item carousel adapting item sizes and flex weights across screen breakpoints).
  3. `TashilCarousel.uncontained` (Continuous uniform-item horizontal carousel).
  * **Unified System Standard:** All multi-image property cards and media galleries MUST use `TashilCarousel.hero` with `TashilCarouselScrollBehavior` to allow mouse drag, trackpad, and touch scrolling.
- **The Official M3 Tabs Suite (`lib/core/design_system/tabs/tashil_tabs.dart`):**
  1. `TashilPrimaryTabBar` (Official Google M3 Primary Tabs: 48dp/64dp height, 3dp rounded pill indicator, active/inactive color transitions, full-width bottom divider, responsive equal-width distribution).
  2. `TashilSecondaryTabBar` (Official Google M3 Secondary Tabs: 44-48dp height, 2dp underline indicator for sub-views and filter segmentation).
  * Reference: https://m3.material.io/components/tabs/specs
- **The Official M3 Chips Suite (`lib/core/design_system/chips/tashil_chips.dart`):**
  1. `TashilAssistChip` (Official Google M3 Assist Chip: Type 1 smart & contextual action chip with leading semantic icon, 32dp height, 8dp squircle corner radius, outlined/elevated/tonal variants).
  2. `TashilFilterChip` (Official Google M3 Filter Chip: Selection and multi-criteria filtering with animated checkmark indicator).
  3. `TashilInputChip` (Official Google M3 Input Chip: Discrete entry tags with trailing close/remove action).
  4. `TashilSuggestionChip` (Official Google M3 Suggestion Chip: Recommendation and AI prompt shortcuts).
  * Reference: https://m3.material.io/components/chips/overview
- **The Official M3 Dialogs Suite (`lib/core/design_system/dialogs/tashil_dialogs.dart`):**
  1. `TashilAlertDialog` (Official Google M3 Basic/Alert Dialog: 28dp extra-large corner radius, Level 3 elevation, optional 24dp top icon, headlineSmall, supporting text, end-aligned action buttons).
  2. `TashilModalDialog` (Official Google M3 Large/Fullscreen Form Dialog: 28dp squircle radius, structured header with icon badge & close button, scrollable body, pinned action footer).
  3. `TashilSelectionDialog` (Official Google M3 Selection/Picker Dialog: 28dp radius, option list with checkmarks & flag/icon badges).
  * Reference: https://m3.material.io/components/dialogs/overview
- **The Official M3 Dividers Suite (`lib/core/design_system/dividers/tashil_dividers.dart`):**
  1. `TashilDivider.fullWidth` (Full-width divider spanning 100% of container width; 1dp thickness; `colorScheme.outlineVariant`).
  2. `TashilDivider.cardAction` (Official M3 DO rule: full-width divider explicitly separating non-interactive container content from interactive action areas such as card buttons).
  3. `TashilDivider.inset` & `TashilDivider.listTextInset` (Directionality-aware start-inset divider aligning with text in lists after leading avatars/icons).
  4. `TashilDivider.middleInset` (Symmetrical start and end insets for padded bounded containers).
  5. `TashilVerticalDivider` (1dp vertical divider for toolbars, stat groups, and split button segments).
  6. `TashilDivider.withLabel` (Labelled divider with inline text badge/label such as "أو" / "OR" with pure trilingual support).
  * **Card Dividers Rules & DO vs CAUTION Guidelines:**
    * **Rule 1 (Full-width in Cards):** Use full-width dividers (`TashilDivider.cardAction()`) spanning 100% border-to-border for content that can be expanded and to separate non-interactive container content from interactive action areas (card footers, dialog footers).
    * **Rule 2 (Inset in Cards):** Use inset dividers (`TashilDivider.middleInset()`, `TashilDivider.inset()`) which do not run the full width of a card to separate related content inside cards.
    * **CAUTION:** Use full-width dividers sparingly. Too many divider lines make an interface look cluttered. Do not place dividers between every row in tight lists when whitespace suffices.
  * Reference: https://m3.material.io/components/divider/guidelines
- **The Official M3 Lists Suite (`lib/core/design_system/lists/tashil_lists.dart`):**
  1. `TashilListTile` (Official Google M3 List Item: 1-line 56dp/48dp dense, 2-line 72dp/64dp dense, 3-line 88dp height; 16dp directional horizontal insets; 16dp gap between leading, text column, and trailing items; headline, overline, supporting text tokens).
  2. `TashilReorderableList` (Official Google M3 Reorderable List container with Level 3 tonal elevation floating card proxy decorator, rounded squircle corners, and smooth reordering physics).
  3. `TashilReorderHandle` (M3 Drag Handle with `Icons.drag_indicator_rounded` supporting immediate desktop mouse drag without delay and mobile touch hold).
  * References: https://m3.material.io/components/lists/guidelines and https://m3.material.io/components/lists/specs
- **The Official M3 Loading Indicator Suite (`lib/core/design_system/loading/tashil_loading.dart`):**
  1. `TashilLoadingIndicator` (Official Google M3 Expressive Loading Indicator: Replaces indeterminate circular progress rings with an organic 4-fold morphing clover/squircle shape, smooth continuous rotation, and harmonic breathing pulse).
  2. Strict M3 Size Hierarchy: Small (`24dp` for buttons, chips, inline items), Medium (`48dp` standard for cards, dialogs, sections), Large (`72dp` prominent for page hydration and AI valuation).
  3. Container Variant: `hasContainer: true` wrapping the indicator in a Level 2 elevated surface container for pull-to-refresh interactions.
  4. `TashilLoadingOverlay` (Frosted glass modal scrim with backdrop filter blur, absorb-pointer interaction shield, and localized status updates for blocking asynchronous tasks).
  5. `M3LoadingShowcaseDialog` (Interactive showcase for inspecting sizes, motions, and overlay simulation).
  * References: https://m3.material.io/components/loading-indicator/overview, https://m3.material.io/components/loading-indicator/specs, and https://m3.material.io/components/loading-indicator/guidelines
- **The Official M3 Progress Indicators Suite (`lib/core/design_system/progress/tashil_progress.dart`):**
  1. `TashilLinearProgressIndicator` (Official Google M3 Expressive Linear Progress: Flat standard pill and Wavy sinusoidal wave with 40dp wavelength & 3.5dp amplitude, Determinate 0.0-1.0 and Indeterminate continuous wave flow, signature 4dp Stop Indicator dot at 100% position, 4dp Stop Gap, 4dp directional edge insets, and full RTL/LTR directionality awareness).
  2. `TashilCircularProgressIndicator` (Official Google M3 Expressive Circular Progress: Flat standard ring and Wavy undulating arc, Determinate 0.0-1.0 and Indeterminate continuous rotation, 4dp Stop Indicator dot, and 4 standard M3 size tokens: Small 40dp, Medium 44dp, Standard 48dp, Large 52dp).
  3. `M3ProgressShowcaseDialog` (Interactive showcase for inspecting Linear & Circular tracks, Flat & Wavy modes, Determinate scrub slider, and simulated file download & media upload).
  * References: https://m3.material.io/components/progress-indicators/overview and https://m3.material.io/components/progress-indicators/specs
- **The Official M3 Navigation Drawer Suite (`lib/core/design_system/drawer/tashil_navigation_drawer.dart`):**
  1. `TashilNavigationDrawer.standard` (Official Google M3 Standard Drawer: Persistent/collapsible sidebar for desktop & tablet ≥840dp, animated 250ms cubic easing between 260dp and 76dp rail mode with tooltips).
  2. `TashilNavigationDrawer.modal` (Official Google M3 Modal Drawer: Sliding drawer for mobile <600dp with Level 1 elevation and 28dp rounded corner on trailing edge).
  3. `TashilDrawerDestination` (Official Google M3 Destination Item: 56dp height, 28dp full stadium pill shape, 12dp directional margins, leading 24dp icon, active `secondaryContainer`/`onSecondaryContainer`, inactive `onSurfaceVariant`, numeric badge counters, and 4 interactive state layers: Enabled, Hovered 8%, Focused 10%, Pressed 10%).
  4. `TashilDrawerSectionHeader` (M3 Section Header: `titleSmall`, directional insets).
  5. `TashilDrawerProfileTile` (M3 Surface Card for user identity, avatar, role, and popup menu trigger).
  6. `M3DrawerShowcaseDialog` (Interactive showcase for inspecting all states, sizes, and motions).
  * References: https://m3.material.io/components/navigation-drawer/overview, https://m3.material.io/components/navigation-drawer/specs, and https://m3.material.io/components/navigation-drawer/guidelines
- **The Official M3 Navigation Rail & Nested Canvas Suite (`lib/core/design_system/navigation_rail/tashil_navigation_rail.dart` & `tashil_scaffold_canvas.dart`):**
  1. `TashilNavigationRail` (Official Google M3 Navigation Rail: 80dp compact rail width with 56x32dp active indicator pill, icon with label directly underneath, numeric badge counters, and animated transition to 260dp expanded drawer mode with 250ms cubic easing).
  2. `TashilRailDestination` (M3 Dual-Mode Destination Item: Vertical layout with label below icon in 80dp rail mode; horizontal row with label beside icon in 260dp mode; 4 interactive state layers: Enabled, Hovered 8%, Focused 10%, Pressed 10%; tooltips in rail mode).
  3. `TashilScaffoldCanvas` (Official Google M3 Nested Canvas Architecture: Outer scaffold where top header and rail share unified surfaceContainerLowest canvas with zero dividing lines; inner workspace body container is nested with surfaceContainerLow and prominent 28dp rounded top-start corner via `BorderRadiusDirectional.only(topStart: Radius.circular(28))` adapting seamlessly between RTL and LTR).
  4. `M3RailShowcaseDialog` (Interactive showcase for inspecting rail vs expanded mode, nested canvas curve, active indicator specs, and badge alignments).
  * References: https://m3.material.io/components/navigation-rail/overview, https://m3.material.io/components/navigation-rail/specs, https://m3.material.io/components/navigation-rail/guidelines, and https://m3.material.io/components/navigation-rail/accessibility
- **The Official M3 Menus Suite (`lib/core/design_system/menus/tashil_menus.dart`):**
  1. `TashilDropdownMenu<T>` (Official Google M3 Dropdown Menu: Outlined form field anchor with floating/header label, 180° animated caret rotation, Level 2 elevation floating menu container with 12dp squircle corners, and smooth 250ms top-to-bottom unfolding motion using `Curves.easeOutCubic`).
  2. `TashilDropdownMenuItem<T>` & `TashilMenuItemWidget<T>` (Official Google M3 Menu Item: 48dp standard touch height, 12dp directional insets, leading semantic icon, optional supporting text, highlighted `secondaryContainer` selected pill container, and trailing checkmark `Icons.check_rounded` for active selections).
  3. `M3MenusShowcaseDialog` (Interactive showcase for inspecting M3 menu specs, animations, selected states, and keyboard/touch dismissal).
  * References: https://m3.material.io/components/menus/guidelines and https://m3.material.io/components/menus/specs
- **The Official M3 Sliders Suite (`lib/core/design_system/sliders/tashil_sliders.dart`):**
  1. `TashilSlider` (Official Google M3 Expressive Slider: 16dp expressive track height with full stadium ends, signature 6dp Stop Gap between active track, handle, and inactive track, 4x44dp vertical bar handle or round thumb, animated floating value indicator balloon with `Curves.easeOutBack` spring physics, 40/44dp state layer aura, stop indicator dots, and 100% RTL/LTR directionality awareness).
  2. `TashilSliderHandleType` (`verticalBar` 4x44dp pill handle, `round` 20dp thumb).
  3. `M3SlidersShowcaseDialog` (Interactive showcase for inspecting 16dp tracks, 6dp stop gap, vertical bar & round handles, discrete stepping, and floating value balloon).
  * References: https://m3.material.io/components/sliders/guidelines and https://m3.material.io/components/sliders/specs
- **The Official M3 Search Suite (`lib/core/design_system/search/tashil_search.dart` & `tashil_search_bar.dart`):**
  1. `TashilSearchBar` (Official Google M3 Search Bar: 56dp standard height with 28dp full stadium pill shape, smooth 220ms hover and focus scale/elevation transitions, leading search icon, instant clear action, visual photo search button, and AI semantic vector search badge).
  2. `Search View Overlay` (Downwards unfolding suggestions view with 240ms cubic easing, rounded squircle corners, elevation shadow, and pure trilingual parity).
- **The Official M3 Switch Suite (`lib/core/design_system/switches/tashil_switches.dart`):**
  1. `TashilSwitch` (Official Google M3 Switch: 52x32dp track, full stadium rounded shape, unselected 2dp `outline` border with 16dp `outline` handle; selected `primary` fill without outline with 24dp `onPrimary` handle; animated checkmark `✓` icon inside handle; 28dp pressed state; 40dp state layer aura; 250ms cubic easing; 100% RTL/LTR directionality awareness; tactile audio/haptic feedback).
  2. `TashilSwitchListTile` (Official Google M3 Switch List Tile: Combines title, subtitle, optional leading icon, and trailing `TashilSwitch` with directionality-aware padding and whole-row tap to toggle).
  3. `M3SwitchesShowcaseDialog` (Interactive showcase for inspecting M3 switch specs, with/without icons, disabled states, and list tile variants).
  * References: https://m3.material.io/components/switch/specs and https://m3.material.io/components/switch/guidelines
- **The Official M3 SnackBar Suite (`lib/core/design_system/snackbars/tashil_snackbars.dart`):**
  1. `TashilSnackBar` (Official Google M3 SnackBar Suite: `TashilSnackBar.show`, `showSuccess`, `showError`, `showWarning`, `showInfo`). Conforms strictly to https://m3.material.io/components/snackbar/overview, https://m3.material.io/components/snackbar/specs, and https://m3.material.io/components/snackbar/guidelines.
  2. Floating & Rounded Container: `SnackBarBehavior.floating` with Level 3 tonal elevation (6dp) and 8dp squircle radius (`BorderRadius.circular(8.0)`).
  3. Dynamic Primary Seed Color Derivation: Automatically derives container and action colors from the active seed palette (`inverseSurface`, `inverseOnSurface`, `inversePrimary`), perfectly harmonizing when the theme shifts between Forest Olive (#2E6B48), Warm Terracotta (#8F4C38), Royal Blue (#0061A4), Slate Navy (#0F172A), or Emerald Teal (#006874).
  4. Responsive Centered Floating Width: Fixed max-width `min(screenWidth - 32, 520)` centered on desktop/tablet to strictly eliminate edge-to-edge stretching, with 16dp responsive margins on mobile.
  5. Strict Single-Action DO Rule: Maximum of 1 action button per snackbar (`TashilSnackBarAction`), preventing multi-button dialog abuse.
  6. Close Affordance: Optional 24dp close icon ('X') alongside the action or standalone.
- **The Official M3 Motion & Transitions Suite (`lib/core/design_system/motion/tashil_motion.dart`):**
  1. `TashilMotionEasing` (Official Google M3 Easing Curves: Emphasized Family for signature expressive motion: `emphasized` Cubic(0.2, 0.0, 0.0, 1.0) for on-screen movement, `emphasizedDecelerate` Cubic(0.05, 0.7, 0.1, 1.0) for entering the screen bounds, `emphasizedAccelerate` Cubic(0.3, 0.0, 0.8, 0.15) for exiting the screen bounds; Standard Family: `standard` Cubic(0.2, 0.0, 0.0, 1.0), `standardDecelerate` Cubic(0.0, 0.0, 0.2, 1.0), `standardAccelerate` Cubic(0.4, 0.0, 1.0, 1.0); strictly prohibits `Curves.linear` for spatial or sizing movement).
  2. `TashilMotionDuration` (Official Google M3 16 Duration Tokens organized in 4 tiers: Short 1-4 [50ms, 100ms, 150ms, 200ms] for micro-interactions & dismissals; Medium 1-4 [250ms, 300ms, 350ms, 400ms] for standard surface transitions & entrances; Long 1-4 [450ms, 500ms, 550ms, 600ms] for hero container expansions; Extra-Long 1-4 [700ms, 800ms, 900ms, 1000ms] for onboarding moments. Enforces the Faster Exit Law where exit durations must be ~50% of entrance durations).
  3. `TashilMotionSpring` (Official Google M3 Motion Physics Springs: `standard` / `criticallyDamped` with mass 1.0, stiffness 300.0, damping 34.64 [damping ratio $\zeta = 1.0$] reaching destination swiftly without overshoot; `expressiveBouncy` with mass 1.0, stiffness 320.0, damping 27.15 [damping ratio $\zeta \approx 0.76$] with tactile bounce for gesture releases and card snaps; `gentle` with mass 1.0, stiffness 180.0, damping 26.83 [$\zeta = 1.0$]).
  4. `TashilTransitions` (The 4 Canonical Google M3 Transition Archetypes: (1) `containerTransform` expanding compact cards into full screens with matched elevation and border radius; (2) `sharedAxis` for X [horizontal forward/backward], Y [vertical stepper], and Z [depth drill-down], featuring 100% RTL/LTR directionality awareness on the X-axis for Arabic; (3) `fadeThrough` for top-level navigation rail and bottom bar switches; (4) `fade` for transient dialogs and scrims).
  5. `TashilCardFilterMotion<T>` (Official Google M3 Card Filtering Motion Architecture: eliminates solid/instant cuts when filtering cards; wraps container in `AnimatedSize` [300ms `emphasized`] for continuous height morphing; cascades incoming cards via `TashilStaggeredEntrance` with 35ms stagger step and 18dp `expressiveFastSpatial` slide; executes 150ms `emphasizedAccelerate` dissolve for departing cards; smoothly scales empty states. Shorthand: whenever requested with 'إعملي نظام الفلترة', the agent MUST link `TashilConnectedButtonGroup` directly with `TashilCardFilterMotion<T>`).
  6. `M3MotionShowcaseDialog` (Interactive showcase for live inspection of curves, durations, transition patterns, and physics springs with pure trilingual parity).
- **The Official M3 Text Fields Suite (`lib/core/design_system/text_fields/tashil_text_fields.dart`):**
  1. `TashilTextField.outlined` & `TashilTextField.filled` (Official Google M3 Text Fields: Conforms to https://m3.material.io/components/text-fields/overview and https://m3.material.io/components/text-fields/specs with 56dp height standard container, 12dp squircle corners, floating animated labels with M3 cubic easing [14px interior to 12px bold header], hover/focus state layers, directional prefix/suffix icons, read-only/disabled states, helper/error text, and 100% RTL/LTR directionality awareness).
  2. `TashilPhoneTextField` (Official Google M3 Phone Input Field: Conforms to M3 text field specs with integrated start-prefix country selector [`+20` / `+971`] separated by a crisp 1dp vertical divider; maintains pure standalone text field architecture while action triggers such as "إرسال الرمز" and verification badges are placed side-by-side with matching 56dp container height and 12dp squircle corners).
  3. `M3TextFieldsShowcaseDialog` (Interactive showcase for inspecting outlined vs filled variants, floating labels, phone field with OTP trigger, and interactive error/disabled states).
  * References: https://m3.material.io/components/text-fields/overview and https://m3.material.io/components/text-fields/specs
- **Strict Single-Icon Rule for Buttons & Chips:**
  * Every button MUST contain at most **ONE single icon**.
  * **NEVER combine two icons** or mix a Flutter `Icon` widget with an emoji in the button's label text.
  * ✅ `TashilButton(icon: Icons.rocket_launch, label: loc.tr('joinPlatform'), onPressed: ...)`

---

## 4. Role-Based Multi-Tenant Portals
- `/` -> Public Marketplace & Property Showcase (accessible without login).
- `/login` -> Role-Based Authentication Gateway:
  * `SuperAdmin` -> `/super-admin`
  * `AgencyAdmin` / `Broker` -> `/agency`
  * `Owner` -> `/owner`
  * `Tenant` -> `/tenant`

---

## 5. Multi-Country Operations (Egypt 🇪🇬 & UAE 🇦🇪)
- Support both **Egypt (`EG`)** and **United Arab Emirates (`AE`)** across all portals.
- Reference skill: `.agents/skills/multi-country-proptech/SKILL.md` and rule `.agents/rules/multi-country-data-standards.md`.
- Ensure zero country leakage: selecting EG filters properties and metrics in EGP (`ج.م`), while selecting AE filters in AED (`د.إ`).
- All Firestore property/lease/agency documents must carry `country_code: 'EG' | 'AE'`.

---

## 6. Performance, Caching & Security Standards
- Reference skill: `.agents/skills/firestore-performance-and-caching/SKILL.md` and rule `.agents/rules/proptech-data-performance-rules.md`.
- All multi-field queries MUST be registered in `firestore.indexes.json`.
- All prices and numbers MUST be formatted using `CurrencyFormatter.formatAmount(...)`.
- All network images in cards MUST be memory-constrained with `ImageUtils.cachedImage`.
- All text searches MUST use `SearchTokenizer.normalizeArabic(...)`.
- Multi-tenant role security MUST adhere to `firestore.rules`.

---

## 7. Multi-Tenant Security & Zero-Leakage Data Standards
- Reference skill: `.agents/skills/multi-tenant-data-isolation/SKILL.md` and rule `.agents/rules/multi-tenant-security-and-isolation.md`.
- **Zero Tenant Leakage (انعدام تسريب البيانات التام):** Under NO circumstance may an owner, tenant, or agency access another entity's records.
- **Dedicated Subcollections:** Private owner assets (leases, tenant identities, payment schedules, unit numbers) MUST reside in `Users/{ownerId}/properties/{propertyId}`.
- **Public Marketplace Sanitization:** The public `/Properties` catalog must NEVER receive tenant names, phone numbers, installments, or private contract notes.
- **Mandatory Query Scoping:** All queries on shared collections (`Leases`, `Maintenance`, `Transactions`) MUST include `.where('owner_id'/'tenant_id'/'agency_id', '==', currentActorId)`.
- **Serverless Governance:** Fan-out and synchronization from private owner silos to public catalogs is handled via Cloud Functions using `firebase-admin`.

