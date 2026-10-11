# Material Design 3 Layout & Adaptive Design System Global Rule

## Mandatory 4-Stage Layout & Adaptive Architecture

Whenever designing, refactoring, or building Flutter screens, responsive layouts, portals, or dashboards, you MUST strictly adhere to Google's official **Material Design 3 (M3)** specifications across the following 4 stages:

### 1. 5 Official Window Size Classes
- Responsive layouts MUST strictly categorize viewports using the 5 official M3 window size classes (`M3WindowSizeClass`):
  - **Compact**: `< 600dp` (Phones portrait, 4 columns, 16dp margins, 16dp gutters)
  - **Medium**: `600 – 839dp` (Tablets, foldables, 8 columns, 24dp margins, 24dp gutters)
  - **Expanded**: `840 – 1199dp` (Laptops, 12 columns, 24dp margins, 24dp gutters)
  - **Large**: `1200 – 1599dp` (Desktop monitors, 12 columns, 32dp margins, 24dp gutters)
  - **Extra Large**: `≥ 1600dp` (Ultra-wide displays, 12 columns, 64dp+ margins, 24dp gutters)
- Never use arbitrary threshold numbers (such as 700dp or 900dp).

### 2. Three-Tier Adaptive Navigation Transformation
- Navigation MUST transform smoothly according to the available width:
  - **Compact (<600dp)**: Content occupies 100% of width. Navigation moves to a Modal Drawer or Bottom Navigation Bar.
  - **Medium (600–839dp)**: Navigation transforms into a **Slim Navigation Rail** (`width: 72dp–76dp`) with centered destination icons (at 38dp) and contextual hover tooltips, freeing 88%+ of the screen width for data.
  - **Expanded & Large (≥840dp)**: Navigation transforms into a full **Navigation Sidebar / Persistent Drawer** (`width: 230dp–275dp`) with smooth collapsible animations (`200ms`, `ClipRect` + `OverflowBox`).
- **Natural Start Navigation Placement**:
  - In **Arabic (`ar` / RTL)**: Navigation rail/sidebar is situated on the **RIGHT** side of the screen.
  - In **English (`en` / LTR)** & **Hindi (`hi` / LTR)**: Navigation rail/sidebar is situated on the **LEFT** side of the screen.
  - Always place the sidebar as the **first child** in `Row(children: [ sidebar, Expanded(child: content) ])` so Flutter's ambient `Directionality` handles proper mirroring across all languages automatically.

### 3. Max-Width Containment & Visual Breathing
- Heavy data dashboards, analytical reports, forms, and detail viewports MUST be wrapped in `M3ContentBoundary` with `maxWidth: 1360dp` (or `1440dp` max for high-density tabular matrices) centered horizontally (`Alignment.topCenter`).
- On Ultra-Wide and 4K displays, content never stretches infinitely across thousands of pixels; surplus screen width automatically resolves into balanced, symmetric visual breathing whitespace.

### 4. 8dp Baseline Spacing Grid & Dynamic KPI Reflow
- All paddings, margins, gaps, and dimensions MUST strictly align with the 8dp grid scale (`M3Spacing`):
  - `xxs = 4.0` (micro-offsets)
  - `xs = 8.0` (tight spacing)
  - `sm = 16.0` (standard card padding / gutters)
  - `md = 24.0` (section padding)
  - `lg = 32.0` (large container padding)
  - `xl = 40.0` (hero spacing)
  - `xxl = 48.0` (standard minimum button height / prominent padding)
  - `xxxl = 64.0` (extra-large display margins)
- Ad-hoc random pixel numbers (`10`, `11`, `13`, `17`, `22`) are strictly forbidden.
- Metric KPI cards must reflow dynamically: 1 card per row on Compact, 2 cards on Medium, and 4 cards on Expanded / Desktop.
