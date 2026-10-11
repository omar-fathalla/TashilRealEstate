---
name: material-design-3-layout-and-adaptive-standard
description: Mandatory Material Design 3 (M3) standard for Window Size Classes, 8dp baseline spacing grid, 3-tier adaptive navigation transformation, max-width containment, and responsive grid reflow across Flutter applications.
---

# Material Design 3 Layout & Adaptive Design Standard

This skill establishes the authoritative, mandatory 4-stage engineering specification for responsive layouts, adaptive window sizing, navigation transformation, max-width containment, and spacing grids across Flutter applications adhering to Google's official **Material Design 3 (M3)** guidelines.

Whenever designing, refactoring, or building user interfaces, responsive layouts, portals, or dashboards, you MUST strictly follow this 4-stage standard.

---

## 📐 The 4 Canonical Stages of M3 Layout Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ Stage 1: Window Size Classes & Layout Engine (5 Official Tiers)             │
│ Compact (<600dp) ── Medium (600-839dp) ── Expanded ── Large ── Extra-Large │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
┌──────────────────────────────────────▼──────────────────────────────────────┐
│ Stage 2: Three-Tier Adaptive Navigation Transformation                      │
│ 📱 Compact: Drawer / Bottom Bar  │  📱 Medium: Rail  │  💻 Expanded: Drawer │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
┌──────────────────────────────────────▼──────────────────────────────────────┐
│ Stage 3: Max-Width Containment & Visual Breathing (1360 - 1440dp)           │
│ Ultra-wide / 4K monitors: Centered with symmetric breathing margins         │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
┌──────────────────────────────────────▼──────────────────────────────────────┐
│ Stage 4: 8dp Baseline Spacing Grid & Grid Reflow (Columns 4 / 8 / 12)       │
│ Micro 4dp, Base 8dp, Standard 16dp / 24dp / 32dp. KPI Cards 1 -> 2 -> 4 cols│
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 1️⃣ Stage 1: Window Size Classes & Metrics Engine (فئات أحجام النوافذ الرسمية)

Ref: [https://m3.material.io/foundations/layout/applying-layout/window-size-classes](https://m3.material.io/foundations/layout/applying-layout/window-size-classes)

M3 categorizes screens by available viewport width into five mathematically defined tiers:

| Window Size Class | Width Range | Typical Devices | Columns | Margin | Gutter | Canonical Navigation |
| :--- | :--- | :--- | :---: | :---: | :---: | :--- |
| **Compact** | `< 600dp` | Smartphones (portrait), folded foldables | 4 | 16dp | 16dp | Bottom Navigation Bar / Modal Drawer |
| **Medium** | `600 – 839dp` | Small tablets, unfolded foldables, landscape phones | 8 | 24dp | 24dp | Slim Navigation Rail (72-76dp) |
| **Expanded** | `840 – 1199dp` | Laptops, large tablets (landscape) | 12 | 24dp | 24dp | Navigation Drawer / Persistent Sidebar |
| **Large** | `1200 – 1599dp` | Desktop monitors | 12 | 32dp | 24dp | Permanent Navigation Drawer |
| **Extra Large** | `≥ 1600dp` | Ultra-wide displays, 4K monitors | 12 | 64dp+ | 24dp | Permanent Drawer + Max-Width Containment |

### Core Architectural Engine Implementation:
Every project must provide `responsive.dart` with:
- `enum M3WindowSizeClass { compact, medium, expanded, large, extraLarge }`
- `class M3LayoutMetrics` containing `width`, `height`, `columns`, `margin`, `gutter`, `navigationType`.
- `abstract class M3Layout` with `M3Layout.of(context)`, `M3Layout.fromConstraints(constraints)`, and `M3Layout.fromWidth(width)`.
- `class M3ResponsiveBuilder` and `class M3AdaptiveLayout`.

---

## 2️⃣ Stage 2: Three-Tier Adaptive Navigation Transformation (التحول التكيفي للملاحة)

Ref: [https://m3.material.io/foundations/layout/understanding-layout/parts-of-layout#navigation](https://m3.material.io/foundations/layout/understanding-layout/parts-of-layout#navigation)

Navigation MUST transform dynamically according to available width:

### A. Compact (< 600dp) — Mobile Experience
- The sidebar is completely hidden from the layout body.
- Content occupies 100% of screen width.
- Navigation occurs via a **Modal Drawer** triggered from the AppBar hamburger menu or a **Bottom Navigation Bar**.

### B. Medium (600 – 839dp) — Tablet & Foldable Experience
- The navigation transforms into a **Slim Navigation Rail** (`width: 72dp - 76dp`) visible directly in the parent `Row`.
- Destinations render as clean, centered icons (centered at 38dp) with contextual hover `Tooltip` widgets.
- The body content retains 88%+ of the screen width for data visualization, forms, and tables.

### C. Expanded & Large (≥ 840dp) — Desktop & Laptop Experience
- A full, rich **Navigation Sidebar / Drawer** (`width: 230dp - 275dp`) is displayed.
- Shows company/app logo, active metrics, section labels, badges, and quick-action footers.
- Supports smooth collapse/expand animation (`200ms`, `Curves.fastOutSlowIn`) with `ClipRect` and `OverflowBox` to prevent `RenderFlex` overflow during transition frames.

### D. Mandatory Directionality Rule (RTL vs LTR)
- In **Arabic (`ar` / RTL)**: Navigation rail/sidebar is situated on the **RIGHT** side of the screen.
- In **English (`en` / LTR)** & **Hindi (`hi` / LTR)**: Navigation rail/sidebar is situated on the **LEFT** side of the screen.
- Always implement as the **first child** in the parent `Row(children: [ sidebar, Expanded(child: content) ])` so Flutter's ambient `Directionality` handles mirroring automatically.

---

## 3️⃣ Stage 3: Max-Width Containment & Visual Breathing (حصر العرض الأقصى)

Ref: [https://m3.material.io/foundations/layout/applying-layout/canonical-layouts](https://m3.material.io/foundations/layout/applying-layout/canonical-layouts)

### The Infinite Stretch Anti-Pattern:
Allowing report tables, analytical graphs, and text blocks to stretch across 2000px+ displays causes eye strain, breaks visual hierarchy, and ruins user experience.

### The M3 Containment Standard:
- All analytical dashboards, reports, and detail viewports MUST wrap content in `M3ContentBoundary`.
- **Maximum Width**: Constrained to `1360dp` (or `1440dp` max for high-density tabular matrix views).
- **Centering**: The bounded container centers horizontally at `Alignment.topCenter`.
- **Symmetric Margins**: Surplus screen width on Ultra-wide / 4K displays naturally expands as balanced, symmetric whitespace (Visual Breathing Margins).
- **Small Screens**: On Compact and Medium screens (<1360dp), content fills 100% of width with standard M3 margins (`16dp` or `24dp`).

```dart
M3ContentBoundary(
  maxWidth: 1360.0,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [ ... ],
  ),
)
```

---

## 4️⃣ Stage 4: 8dp Baseline Spacing Grid & Grid Reflow (شبكة الـ 8dp والـ Reflow)

Ref: [https://m3.material.io/foundations/layout/understanding-layout/spacing](https://m3.material.io/foundations/layout/understanding-layout/spacing)

### A. The 8dp Spacing Scale (`M3Spacing`)
Every margin, padding, gap, and dimension MUST be a multiple of 8dp:
- `xxs = 4.0` (micro-alignment for icon labels and badge offsets)
- `xs = 8.0` (tight spacing)
- `sm = 16.0` (standard card padding, compact gutter)
- `md = 24.0` (section padding, medium/expanded gutter)
- `lg = 32.0` (large container padding)
- `xl = 40.0` (hero spacing)
- `xxl = 48.0` (standard minimum button height / prominent padding)
- `xxxl = 64.0` (extra-large display margins)

> ❌ **FORBIDDEN**: Random ad-hoc pixel values like `10`, `11`, `12`, `13`, `15`, `17`, `22`.

### B. Dynamic Metric Card Reflow (KPI Grid Reflow)
Dashboard KPI cards and summary tiles must reflow gracefully based on `M3Layout`:
```dart
LayoutBuilder(
  builder: (context, constraints) {
    final layout = M3Layout.fromConstraints(constraints);
    final double cardWidth;

    if (layout.isDesktop) {
      // 4 cards across (12 columns)
      cardWidth = (constraints.maxWidth - (3 * M3Spacing.sm)) / 4;
    } else if (layout.isMedium || constraints.maxWidth >= 420) {
      // 2 cards across (8 columns)
      cardWidth = (constraints.maxWidth - M3Spacing.sm) / 2;
    } else {
      // 1 card across (4 columns)
      cardWidth = constraints.maxWidth;
    }

    return Wrap(
      spacing: M3Spacing.sm,
      runSpacing: M3Spacing.sm,
      children: [ ... ],
    );
  },
)
```

---

## 🛠️ Verification Checklist for Any Screen or Project

Before declaring any screen or project M3-compliant, verify:
1. [ ] **Window Size Classes**: Breakpoints use `<600`, `600-839`, and `≥840dp` (never arbitrary 700 or 900 thresholds).
2. [ ] **Navigation Transformation**: Phones (<600dp) use Drawer/BottomBar; Tablets (600-839dp) use Navigation Rail; Desktops (≥840dp) use Sidebar.
3. [ ] **Directionality**: Sidebar is the first child of `Row` (Right in Arabic RTL, Left in English/Hindi LTR).
4. [ ] **Ultra-Wide Containment**: Heavy viewports wrap in `M3ContentBoundary(maxWidth: 1360-1440dp)`.
5. [ ] **8dp Baseline Spacing**: All paddings and gutters use `M3Spacing` (`8`, `16`, `24`, `32`, `48`).
6. [ ] **Zero Overflow Animations**: Collapsible sidebars use `ClipRect` and proper inner widths to ensure smooth 60 FPS transitions without `RenderFlex` exceptions.
