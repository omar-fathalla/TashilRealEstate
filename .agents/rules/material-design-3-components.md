# Material Design 3 (M3) Component & Architectural Rules

This rule defines non-negotiable frontend implementation standards for all AI Agents and developers working on the Tashil Real Estate codebase.

---

## 1. Mandatory M3 Component Specifications

Whenever generating or refactoring Flutter UI code, you MUST use official Material Design 3 components:

1. **Buttons Taxonomy:**
   - **Primary Action:** Use `FilledButton` or `FilledButton.icon`.
   - **Secondary Key Action:** Use `FilledButton.tonal` or `FilledButton.tonalIcon`.
   - **Neutral Action:** Use `OutlinedButton` or `OutlinedButton.icon`.
   - **Inline Link / Low Emphasis:** Use `TextButton`.
   - **Toolbar / Grid Action:** Use `IconButton`, `IconButton.tonal`, `IconButton.outlined`, or `IconButton.filled`.
   - **Hero Floating Action:** Use `FloatingActionButton` or `FloatingActionButton.extended`.
   - **Selection / View Switch / Sorting:** Use `TashilConnectedButtonGroup<T>` (Official M3 Expressive Connected Button Group) replacing deprecated baseline `SegmentedButton`. Features a continuous `surfaceContainerHigh` stadium capsule (24dp radius), 3.5dp padding, and inner floating active pill in `primary`/`secondaryContainer` with subtle elevation shadow (`BoxShadow(color: colorScheme.shadow.withValues(alpha: 0.12), blurRadius: 4, offset: Offset(0, 1.5))`) and 220ms `easeInOutCubic` motion.
   - **Shorthand Protocol ("حولهالي بنفس النمط" / "طبق الـ Connected Button Group"):** Whenever the user asks to apply or convert buttons to the connected group design, immediately use `TashilConnectedButtonGroup<T>` with `TashilConnectedButtonSegment`.

2. **Strict Single-Icon Rule:**
   - Every button must contain at most **ONE single icon**.
   - **NEVER mix a Flutter `Icon` widget with an emoji** in the button's label text.
   - When using flag emojis (e.g. 🇪🇬 or 🇦🇪), pass them cleanly via `leading: Text('🇪🇬', style: TextStyle(fontSize: 15))` without additional `Icon` widgets.
   - ❌ `FilledButton.icon(icon: Icon(Icons.send), label: Text('🚀 إرسال'))`
   - ✅ `FilledButton.icon(icon: Icon(Icons.send), label: Text(loc.tr('send')))`

3. **Cards & Surface Elevation:**
   - Prefer `Card.outlined` with `Border.all(color: theme.colorScheme.outlineVariant)` for marketplace property items and tables.
   - Use `Card.filled` with `surfaceContainerLow` for dashboard metric cards.
   - Do NOT use harsh manual `BoxShadow(blurRadius: 20, color: Colors.black54)`. Use M3 surface container hierarchy.

4. **Forms & Inputs:**
   - Use `TextField` with `InputDecoration(filled: true, fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5))`.
   - Border radius should be `12px` to `16px`.
   - Focus border width `2px` in `colorScheme.primary`.

5. **Trilingual RTL/LTR Alignment:**
   - Always use `EdgeInsetsDirectional` for padding and margins.
   - Typography must be routed through `GoogleFonts.cairoTextTheme()` for Arabic, `GoogleFonts.interTextTheme()` for English, and `GoogleFonts.notoSansDevanagariTextTheme()` for Hindi.
   - Zero hardcoded user-visible text. All strings must use `AppLocalizations.of(context).tr('key')`.

6. **Switches & Boolean Controls:**
   - Use `TashilSwitch` (`lib/core/design_system/switches/tashil_switch.dart`) or `TashilSwitchListTile` for all toggle switches.
   - Strictly conforms to https://m3.material.io/components/switch/specs and https://m3.material.io/components/switch/guidelines.
   - Track: 52x32dp stadium capsule; unselected 2dp `outline` border with 16dp handle; selected solid `primary` with 24dp `onPrimary` handle and animated checkmark `✓` (`Icons.check_rounded`, 16dp).
   - Dynamic 28dp pressed handle expansion, 40dp state layer aura, and smooth 250ms `Curves.easeInOutCubic` motion with full RTL/LTR directionality awareness and tactile audio feedback.

---

## 2. Pre-Execution Verification Checklist

Before finalizing any UI code:
1. `flutter analyze` must report `0 issues`.
2. No deprecated Flutter widgets (e.g. `withOpacity` $\rightarrow$ `withValues(alpha: ...)`).
3. Theme tokens accessed strictly via `Theme.of(context).colorScheme` and `Theme.of(context).textTheme`.
