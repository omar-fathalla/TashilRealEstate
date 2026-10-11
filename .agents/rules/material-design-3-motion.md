# Material Design 3 (M3) Motion & Transition Rules

This rule defines mandatory, non-negotiable frontend motion and transition standards for all AI Agents and developers working on the Tashil Real Estate codebase.

---

## 1. Mandatory Motion Easing & Duration Tokens

Whenever implementing any animation, screen transition, sheet reveal, dialog opening, or component morphing, you MUST use official Material Design 3 tokens defined in `lib/core/design_system/motion/tashil_motion.dart`:

1. **Easing Token Standards:**
   - **On-Screen Movements & Container Expansion:** Always use `TashilMotionEasing.emphasized` (`Cubic(0.2, 0.0, 0.0, 1.0)`).
   - **Elements Entering the Screen:** Always use `TashilMotionEasing.emphasizedDecelerate` (`Cubic(0.05, 0.7, 0.1, 1.0)`) or `standardDecelerate` for micro-elements.
   - **Elements Exiting the Screen:** Always use `TashilMotionEasing.emphasizedAccelerate` (`Cubic(0.3, 0.0, 0.8, 0.15)`) or `standardAccelerate`.
   - **Strict Prohibition of Linear Motion:** NEVER use `Curves.linear` for spatial movement, scale, or size changes.
   - **Strict Prohibition of Boundary Overshoot:** NEVER use bouncy or elastic curves for elements entering or exiting across screen boundaries.

2. **Duration Token Scale:**
   - Use strictly defined tokens from `TashilMotionDuration` (`short1` to `extraLong4`). Never hardcode arbitrary millisecond numbers (e.g. `312ms`, `750ms`).
   - **Micro-interactions:** `short1` (50ms) to `short3` (150ms).
   - **Component Exits:** `short4` (200ms).
   - **Component Entrances:** `medium1` (250ms) for standard elements, `medium4` (400ms) for dialogs and sheets.
   - **Hero Container Transforms:** `long2` (500ms).
   - **The Faster Exit Law:** Exits MUST always be approximately half the duration of entrances (200ms vs 400ms).

---

## 2. The 4 Mandatory Transition Patterns

Whenever architecting page or view transitions, choose strictly from the 4 M3 archetypes:

1. **Container Transform:**
   - Use for transitioning from a compact container (`PropertyCard`, FAB, search bar) to a detailed container (`PropertyDetailsDialog`, new listing sheet).
   - Must interpolate corner radius, elevation, and background color while cross-fading content.
2. **Shared Axis Transition:**
   - **Shared X-Axis:** Forward/backward pagination, wizards, and tabs.
   - **Directionality Awareness:** When navigating "Forward" in Arabic (`ar`), content MUST slide from the **Left** to the **Right** (RTL). In English and Hindi, forward content slides from **Right** to **Left** (LTR).
   - **Shared Y-Axis:** Pull-down search overlays and vertical steppers.
   - **Shared Z-Axis:** Deep-dive navigation into folders or categories.
3. **Fade Through Transition:**
   - Use for unrelated top-level navigation (Bottom Navigation Bar, Navigation Rail destination switches).
   - Outgoing screen fades out to 0 opacity (0-35% duration), then incoming screen fades in from 0 to 1 while scaling up from 92% to 100% (35-100% duration).
4. **Fade Transition:**
   - Use for transient elements appearing within current screen bounds (dialog backdrop scrims, floating snackbars, popover menus, tooltips).

---

## 3. Physics-Based Springs & Web Conversions Standard

For gesture-driven interactions, card drag releases, and interactive feedback, use `TashilMotionSpring` and `TashilMotionWebCurves`:
- **Critically Damped (`TashilMotionSpring.criticallyDamped`, $\zeta = 1.0$):** Use for UI stabilization without bouncing.
- **Expressive Bouncy (`TashilMotionSpring.expressiveBouncy`, $\zeta \approx 0.76$):** Use for tactile delight on button press releases and card dismiss snaps.

### 3.1 Web & Cross-Platform Spring-to-Curve Conversions (`TashilMotionWebCurves`):
Per official Google M3 specs (https://m3.material.io/styles/motion/overview/specs):
- **Spatial Motions (Movement in space, resizing, container expansions):**
  * `expressiveFastSpatial`: `Cubic(0.14, 1.41, 0.71, 0.99)`, 264ms (card hover bounce, quick snaps).
  * `expressiveDefaultSpatial`: `Cubic(0.18, 1.13, 0.52, 1.00)`, 500ms (container transforms, property details dialog).
  * `expressiveSlowSpatial`: `Cubic(0.14, 1.00, 0.32, 0.99)`, 620ms.
  * `standardFastSpatial`: `Cubic(0.20, 1.04, 0.54, 1.00)`, 290ms.
  * `standardDefaultSpatial`: `Cubic(0.20, 1.00, 0.40, 1.00)`, 500ms.
  * `standardSlowSpatial`: `Cubic(0.19, 1.00, 0.28, 1.00)`, 740ms.
- **Effects Motions (In-place visual changes: opacity, color, elevation, blur):**
  * `expressiveFastEffects`: `Cubic(0.00, 0.79, 0.63, 1.00)`, 150ms (card shadow lift, scrim fade).
  * `expressiveDefaultEffects`: `Cubic(0.10, 0.90, 0.51, 1.00)`, 200ms.
  * `expressiveSlowEffects`: `Cubic(0.10, 0.96, 0.44, 1.00)`, 350ms.
  * `standardFastEffects`: `Cubic(0.00, 0.74, 0.54, 1.00)`, 150ms.
  * `standardDefaultEffects`: `Cubic(0.00, 0.90, 0.51, 1.00)`, 200ms.
  * `standardSlowEffects`: `Cubic(0.10, 0.96, 0.44, 1.00)`, 350ms.

---

## 4. معيار موشن وانتقالات الفلترة بين الكروت (Card Filtering Motion & Transitions Protocol)

Whenever implementing or refactoring any filtering system across cards, invoices, properties, or leases (e.g. using `TashilConnectedButtonGroup` or filter chips):
1. **Strict Prohibition of Solid/Instant Cuts (حظر الانتقال الصلب والمفاجئ):** NEVER swap lists abruptly without motion. Never render static `ListView` blocks that snap instantly when filters change.
2. **Mandatory Standard Component (`TashilCardFilterMotion<T>`):**
   All filtering views MUST use `TashilCardFilterMotion<T>` from `lib/core/design_system/motion/tashil_motion.dart`.
3. **Smooth Container Morphing (`AnimatedSize`):**
   The card container MUST wrap with `AnimatedSize` using `TashilMotionDuration.medium2` (300ms) and `TashilMotionEasing.emphasized` aligned to `Alignment.topCenter` so container height glides smoothly as item count increases or decreases.
4. **Staggered Cascading Entrance per Card (`TashilStaggeredEntrance`):**
   Incoming cards MUST enter sequentially with a 35ms stagger step (`index * 35ms`, capped at 250ms), sliding up gently (16-18dp) using `TashilMotionWebCurves.expressiveFastSpatial` with opacity fade ($0.0 \to 1.0$) over 280ms.
5. **The Faster Exit Law for Outgoing Cards:**
   Cards exiting the active filter dissolve quickly with `TashilMotionEasing.emphasizedAccelerate` (~150ms) to ensure responsiveness.
6. **Graceful Empty State Transition:**
   If a filter yields zero results, the empty state view animates in with subtle scale ($0.94 \to 1.0$) and fade rather than snapping.
7. **Shorthand Protocol ("إعملي نظام الفلترة"):**
   Whenever the user requests a filtering system ("إعملي نظام الفلترة"), the agent MUST immediately integrate `TashilConnectedButtonGroup` linked with `TashilCardFilterMotion<T>`.

---

## 5. Pre-Execution Verification Checklist

Before finalizing any animated UI code:
1. All curves and durations reference `TashilMotionEasing`, `TashilMotionDuration`, or `TashilMotionWebCurves`.
2. No `Curves.linear` or manual arbitrary `Duration(milliseconds: 320)` used.
3. Card details and full modals open via `TashilTransitions.showContainerTransformDialog`.
4. Lists and grids apply `TashilStaggeredEntrance` with 35ms cascade step, or `TashilCardFilterMotion` for category filters.
5. Horizontal transitions are tested in Arabic (`ar` RTL) and English (`en` LTR).
6. `flutter analyze` reports `0 issues`.
