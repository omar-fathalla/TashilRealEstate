---
name: material-design-3-motion
description: Authoritative Google Material Design 3 (M3) Motion & Transitions System, easing tokens, duration hierarchies, 4 core transition patterns, physics-based springs, and Flutter implementation standards.
---

# Material Design 3 (M3) — Motion & Transitions System

This skill is the **definitive, authoritative engineering handbook** for all animations, motion behaviors, page transitions, and interactive physics across the **Tashil Real Estate** platform.

Whenever implementing or refactoring any screen transition, dialog animation, modal sheet, drawer expansion, button micro-interaction, or gesture physics, you MUST strictly adhere to these official Google Material Design 3 motion specifications.

---

## 1. Core Principles of Motion in Material Design 3

Motion in Material Design 3 is designed to make user interfaces expressive, effortless, and intuitive:
1. **Purposeful & Informative:** Motion guides user focus to what matters most. Every animation answers two core spatial questions:
   - *Where did this element come from?*
   - *Where is it going?*
2. **Connected Surfaces (No Harsh Cuts):** Rather than screens popping abruptly into view, surfaces morph, scale, and cross-fade to maintain spatial continuity.
3. **Hierarchy & Efficiency:**
   - Everyday micro-interactions (hover, ripple, toggle) are instant and snappy (**50ms - 200ms**).
   - Significant contextual shifts (dialogs, hero cards, full-screen transitions) are measured and expressive (**300ms - 500ms**).
   - **Exit transitions are always faster than entrances** (typically ~200ms vs 400-500ms) because outgoing UI should never hold the user back.
4. **Trilingual RTL & LTR Awareness:** Directional motion (Shared X-Axis, sliding drawers, forward/backward navigation) must invert along the horizontal axis when switching between Arabic (RTL) and English/Hindi (LTR).

---

## 2. Easing Curves & Mathematical Tokens

Google Material Design 3 categorizes easing curves into two primary families: **Emphasized** (the expressive default of M3) and **Standard** (functional utility).

### A. The Emphasized Curve Family (Hero & Expressive Default)
The Emphasized family features rapid initial acceleration followed by a prolonged, elegant deceleration. It is the signature motion personality of Material Design 3.

| Token Name | Cubic Bezier Spec | Flutter Implementation | Primary Use Case |
| :--- | :--- | :--- | :--- |
| **`emphasized`** | `cubic-bezier(0.2, 0.0, 0.0, 1.0)` | `Cubic(0.2, 0.0, 0.0, 1.0)` | Elements that **begin and end on screen** (size changes, position shifts, container expansions). |
| **`emphasizedDecelerate`** | `cubic-bezier(0.05, 0.7, 0.1, 1.0)` | `Cubic(0.05, 0.7, 0.1, 1.0)` | Elements that **enter the screen** (dialogs appearing, bottom sheets sliding up, menus unfolding). |
| **`emphasizedAccelerate`** | `cubic-bezier(0.3, 0.0, 0.8, 0.15)` | `Cubic(0.3, 0.0, 0.8, 0.15)` | Elements that **exit the screen** (dialogs dismissing, bottom sheets closing). |

### B. The Standard Curve Family (Functional & Compact)
The Standard curve family is subtle and utilitarian, intended for smaller UI components, data-dense views, or high-frequency micro-interactions.

| Token Name | Cubic Bezier Spec | Flutter Implementation | Primary Use Case |
| :--- | :--- | :--- | :--- |
| **`standard`** | `cubic-bezier(0.2, 0.0, 0.0, 1.0)` | `Cubic(0.2, 0.0, 0.0, 1.0)` | General on-screen transitions for small elements. |
| **`standardDecelerate`** | `cubic-bezier(0.0, 0.0, 0.2, 1.0)` | `Cubic(0.0, 0.0, 0.2, 1.0)` | Small elements entering screen bounds (tooltips, small badges). |
| **`standardAccelerate`** | `cubic-bezier(0.4, 0.0, 1.0, 1.0)` | `Cubic(0.4, 0.0, 1.0, 1.0)` | Small elements exiting screen bounds. |

---

## 3. Duration Tokens Hierarchy (The 16 Official Steps)

Material Design 3 defines an exact 16-tier duration scale divided into 4 tiers. Never use arbitrary durations like `327ms` or `750ms`. Always pick from the official scale:

### Short Tier (Micro-interactions & Exits)
- **`short1` (50ms):** Icon toggles, subtle color/opacity cross-fades, haptic visual sync.
- **`short2` (100ms):** Focus rings, selection checkmark animations, chip touch highlights.
- **`short3` (150ms):** Button tap depressions, ripple expansions, hover state layer fades.
- **`short4` (200ms):** Canonical exit duration for dialogs, modals, and sheets; tooltip fades.

### Medium Tier (Small Surfaces & Entrances)
- **`medium1` (250ms):** Standard component entrance (Standard Decelerate), dropdown menu reveal.
- **`medium2` (300ms):** Standard on-screen transitions, tab indicator slides, connected button group pill slide.
- **`medium3` (350ms):** Chip expansion, search bar container morphing.
- **`medium4` (400ms):** Canonical entrance duration for dialogs, bottom sheets, and snackbars (Emphasized Decelerate).

### Long Tier (Large Surfaces & Full Transitions)
- **`long1` (450ms):** Navigation drawer standard collapse/expand.
- **`long2` (500ms):** Canonical Container Transform duration (card to full-screen details view).
- **`long3` (550ms):** Complex multi-element modal expansions.
- **`long4` (600ms):** Expansive tablet/desktop layout reflows and split-view transitions.

### Extra-Long Tier (Onboarding & Brand Moments)
- **`extraLong1` (700ms) to `extraLong4` (1000ms):** Reserved strictly for onboarding illustrations, AI valuation calculation animations, or grand marketing hero intros. Never use in core productivity workflows.

---

## 4. Suggested Canonical Pairs (Duration + Easing Matrix)

| Interaction Scenario | Easing Token | Duration Token | Duration (ms) |
| :--- | :--- | :--- | :--- |
| **Hero Container Transform** | `TashilMotionEasing.emphasized` | `TashilMotionDuration.long2` | 500ms |
| **Dialog / Sheet Entrance** | `TashilMotionEasing.emphasizedDecelerate` | `TashilMotionDuration.medium4` | 400ms |
| **Dialog / Sheet Dismissal** | `TashilMotionEasing.emphasizedAccelerate` | `TashilMotionDuration.short4` | 200ms |
| **Drawer / Rail Morph** | `TashilMotionEasing.emphasized` | `TashilMotionDuration.long1` | 450ms |
| **Tab / Segment Pill Slide** | `TashilMotionEasing.standard` | `TashilMotionDuration.medium1` | 250ms |
| **Dropdown Menu Reveal** | `TashilMotionEasing.emphasizedDecelerate` | `TashilMotionDuration.medium1` | 250ms |
| **SnackBar Float In** | `TashilMotionEasing.emphasizedDecelerate` | `TashilMotionDuration.medium2` | 300ms |
| **SnackBar Float Out** | `TashilMotionEasing.emphasizedAccelerate` | `TashilMotionDuration.short4` | 200ms |

---

## 5. The 4 Core Transition Patterns

Material Design 3 defines 4 core architectural transition archetypes:

```
+-------------------------------------------------------------------------+
|                  THE 4 M3 TRANSITION ARCHETYPES                         |
+-------------------------------------------------------------------------+
|  1. Container Transform   | Surface A (Card/FAB) seamlessly morphs into |
|                           | Surface B (Full-screen view / Dialog)       |
+---------------------------+---------------------------------------------+
|  2. Shared Axis           | Elements share spatial navigation           |
|     - X-Axis (Horizontal) | Forward/Backward steps, Wizard, Tabs        |
|     - Y-Axis (Vertical)   | Pull-down search, vertical stepper          |
|     - Z-Axis (Depth)      | Folder drill-down, settings parent/child    |
+---------------------------+---------------------------------------------+
|  3. Fade Through          | Unrelated primary destinations (Bottom Bar, |
|                           | sidebar role switch); fades out, scales in  |
+---------------------------+---------------------------------------------+
|  4. Fade                  | Elements appearing within screen bounds     |
|                           | (Dialog scrim, tooltip, menu, snackbar)     |
+-------------------------------------------------------------------------+
```

### 1. Container Transform
- **Concept:** Seamlessly transforms a compact container (e.g. `PropertyCard`, `FloatingActionButton`, or list item) into an expanded container (e.g. `PropertyDetailsDialog` or full-screen page).
- **Key Interpolations:**
  - Border radius smoothly interpolates (e.g. from 12dp card squircle to 0dp screen or 28dp dialog).
  - Elevation transitions smoothly from Resting Level 1 to Level 3.
  - Background color blends smoothly between surfaces.
  - Outgoing content cross-fades quickly into incoming content without abrupt flashing.

### 2. Shared Axis Transition
- **Shared X-Axis (Horizontal):**
  - Used for linear navigation (wizard next/previous, stepping through lease generation, tab views).
  - **RTL Awareness:** In Arabic (`ar`), "Next" slides in from the left and exits to the right. In English (`en`) and Hindi (`hi`), "Next" slides in from the right and exits to the left.
- **Shared Y-Axis (Vertical):**
  - Used for top-level search unfolding, pull-to-refresh expansion, or reordering items vertically.
- **Shared Z-Axis (Depth / Scale):**
  - Used when drilling deeper into a hierarchy (e.g., clicking a property folder to open units inside). The current screen slightly scales down and fades out, while the child screen scales up from 80% to 100% and fades in.

### 3. Fade Through Transition
- Used for major navigation shifts where destinations do not share a spatial or parent-child relationship (e.g. clicking different items on the Bottom Navigation Bar or rail).
- **Sequencing:**
  - Phase 1 (0% to 35%): Outgoing view fades out to 0 opacity.
  - Phase 2 (35% to 100%): Incoming view fades in from 0 to 1 opacity while scaling up from 92% to 100%.

### 4. Fade Transition
- Used for transient surfaces appearing or disappearing entirely within screen bounds without altering page hierarchy (e.g., dialog backdrop scrims, floating snackbars, popover menus, tooltips).

---

## 6. Modern Motion Physics System — Springs

Material Design 3 has expanded beyond static cubic-bezier curves into **physics-based spring dynamics** for natural, interruptible, and gesture-driven motion.

### Mathematical Parameters:
- **Mass ($m$):** Inertia of the moving object (typically $1.0$).
- **Stiffness ($k$):** Spring tension and pull velocity towards equilibrium.
- **Damping Ratio ($\zeta$):**
  - $\zeta = 1.0$ (**Critically Damped**): Fastest return to equilibrium **without oscillation or bounce**. Essential for page transitions, drawer navigation, and accessible UI.
  - $\zeta < 1.0$ (**Underdamped**, typically $0.70 - 0.85$): Returns to equilibrium with a subtle, controlled **expressive bounce (overshoot)**. Used for button press releases, card dragging, and pull-to-refresh snaps.
  - $\zeta > 1.0$ (**Overdamped**): Sluggish, delayed return. Strictly prohibited in M3.

### The 3 Standard M3 Spring Presets:
```dart
// 1. Standard (Critically Damped - No Bounce)
const SpringDescription standardSpring = SpringDescription(
  mass: 1.0,
  stiffness: 300.0,
  damping: 34.64, // 2 * sqrt(mass * stiffness) -> zeta = 1.0
);

// 2. Expressive Bouncy (Tactile Delight - Subtle Overshoot)
const SpringDescription expressiveSpring = SpringDescription(
  mass: 1.0,
  stiffness: 320.0,
  damping: 27.15, // zeta approx 0.76 -> subtle spring bounce
);

// 3. Gentle (Relaxed & Soft)
const SpringDescription gentleSpring = SpringDescription(
  mass: 1.0,
  stiffness: 180.0,
  damping: 26.83, // zeta = 1.0 -> slow, luxurious settle
);
```

### 6.1 Web & Cross-Platform Spring-to-Curve Conversions (`TashilMotionWebCurves`)
When rendering motion on Web or desktop where native spring tickers may introduce overhead, Google Material Design 3 provides pre-computed, high-fidelity cubic bezier curves and durations:

| Spring Token | Motion Domain | Cubic-Bezier Curve | Duration | Best Use Case |
|---|---|---|---|---|
| **Expressive Fast Spatial** | Spatial | `Cubic(0.14, 1.41, 0.71, 0.99)` | 264ms | Card hover bounce, drag release, tactile snaps |
| **Expressive Default Spatial** | Spatial | `Cubic(0.18, 1.13, 0.52, 1.00)` | 500ms | Container transform, card to dialog modal |
| **Expressive Slow Spatial** | Spatial | `Cubic(0.14, 1.00, 0.32, 0.99)` | 620ms | Large hero expansions, full-page reveals |
| **Expressive Fast Effects** | Effects | `Cubic(0.00, 0.79, 0.63, 1.00)` | 150ms | Elevation shadow lift, backdrop scrim fade |
| **Expressive Default Effects** | Effects | `Cubic(0.10, 0.90, 0.51, 1.00)` | 200ms | Color fills, badge scale, button state layers |
| **Expressive Slow Effects** | Effects | `Cubic(0.10, 0.96, 0.44, 1.00)` | 350ms | Ambient tint shifts, complex layered cross-fades |
| **Standard Fast Spatial** | Spatial | `Cubic(0.20, 1.04, 0.54, 1.00)` | 290ms | Utilitarian list shifts, chip rearrangement |
| **Standard Default Spatial** | Spatial | `Cubic(0.20, 1.00, 0.40, 1.00)` | 500ms | Standard dialogs, sheet expansion |
| **Standard Slow Spatial** | Spatial | `Cubic(0.19, 1.00, 0.28, 1.00)` | 740ms | Complex multi-pane responsive layout transitions |
| **Standard Fast Effects** | Effects | `Cubic(0.00, 0.74, 0.54, 1.00)` | 150ms | Tooltips, focus outlines, quick icon cross-fades |
| **Standard Default Effects** | Effects | `Cubic(0.00, 0.90, 0.51, 1.00)` | 200ms | Standard opacity and background switches |
| **Standard Slow Effects** | Effects | `Cubic(0.10, 0.96, 0.44, 1.00)` | 350ms | Image fade-in upon network load |

---

## 7. Component Motion Integration Guide

1. **Connected Button Group (`TashilConnectedButtonGroup`):**
   - Active pill moves between segments using `TashilMotionEasing.standard` over `TashilMotionDuration.medium1` (250ms).
2. **Dialogs (`TashilAlertDialog`, `TashilModalDialog`):**
   - Entrance: `TashilMotionEasing.emphasizedDecelerate`, duration `TashilMotionDuration.medium4` (400ms), scale transition from `0.85` to `1.0`.
   - Exit: `TashilMotionEasing.emphasizedAccelerate`, duration `TashilMotionDuration.short4` (200ms), fade and subtle scale down to `0.95`.
3. **Snackbars (`TashilSnackBar`):**
   - Entrance: `TashilMotionEasing.emphasizedDecelerate`, duration `TashilMotionDuration.medium2` (300ms), sliding up from 16dp below viewport.
   - Exit: `TashilMotionEasing.emphasizedAccelerate`, duration `TashilMotionDuration.short4` (200ms).
4. **Navigation Rail & Drawer:**
   - Width expansion (80dp $\rightarrow$ 260dp): `TashilMotionEasing.emphasized` over `TashilMotionDuration.long1` (450ms).
   - Destination item label opacity cross-fades concurrently.
5. **Switch (`TashilSwitch`):**
   - Handle transition across track: `TashilMotionEasing.standard` over `TashilMotionDuration.medium1` (250ms), with dynamic 28dp pressed expansion.
6. **Card Filtering Motion & Transitions Protocol (`TashilCardFilterMotion`):**
   - **Continuous Height Morphing:** Wraps list/grid in `AnimatedSize` with `TashilMotionDuration.medium2` (300ms) and `TashilMotionEasing.emphasized` aligned to `Alignment.topCenter` to eliminate abrupt vertical snaps when item count changes.
   - **Staggered Card Cascading:** Incoming filtered cards cascade in using `TashilStaggeredEntrance` with a 35ms stagger step (`index * 35ms`), sliding up 18dp using `TashilMotionWebCurves.expressiveFastSpatial` with opacity fade ($0.0 \to 1.0$) over 280ms.
   - **The Faster Exit Law:** Exiting cards dissolve rapidly with `TashilMotionEasing.emphasizedAccelerate` (~150ms).
   - **Smooth Empty State Transition:** Automatically fades and scales in empty states with `TashilMotionEasing.emphasizedDecelerate`.
   - **Shorthand Protocol ("إعملي نظام الفلترة"):** Whenever asked to implement or refactor a filtering view, pair `TashilConnectedButtonGroup` with `TashilCardFilterMotion<T>`.

---

## 8. Motion DOs & DON'Ts

- **DO:** Always use `TashilMotionEasing.emphasizedDecelerate` for incoming elements (dialogs, bottom sheets, snackbars).
- **DO:** Always make exit transitions approximately half the duration of entrances (200ms exit vs 400ms entrance).
- **DO:** Invert horizontal slide directions for Arabic (`ar`) so forward movement honors RTL conventions.
- **DO:** Use `TashilMotionSpring.expressiveBouncy` for gesture-driven releases and drag snapping.
- **DON'T:** NEVER use `Curves.linear` for moving, scaling, or morphing elements.
- **DON'T:** NEVER apply overshoot or bouncy springs when elements cross the screen boundary (it looks like a collision bug).
- **DON'T:** NEVER use long durations (>300ms) for high-frequency micro-interactions (e.g. icon toggles, checkbox checks, button presses).
