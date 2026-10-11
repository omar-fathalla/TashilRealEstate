/// Official Material Design 3 (M3) Dividers Design System for Tashil Real Estate.
///
/// Implements the official Google Material Design 3 Divider specifications and guidelines:
/// https://m3.material.io/components/divider/guidelines
///
/// Key Types & Guidelines:
/// 1. Full-width Divider ([TashilDivider.fullWidth]): Spans 100% of container width to separate functional areas.
/// 2. Inset Divider ([TashilDivider.inset], [TashilDivider.listTextInset]): Indented at start to align with text in lists.
/// 3. Middle Inset Divider ([TashilDivider.middleInset]): Symmetrically indented at start and end.
/// 4. Card Action Divider ([TashilDivider.cardAction]): Official M3 "DO" rule separating non-interactive content from interactive actions.
/// 5. Vertical Divider ([TashilVerticalDivider]): 1dp line separating horizontal items.
/// 6. Labelled Divider ([TashilLabelledDivider], [TashilDivider.withLabel]): Divider with inline label/badge.
///
/// DO vs CAUTION:
/// - DO: Use full-width dividers between non-interactive and interactive areas in cards/dialogs.
/// - DO: Use inset dividers in lists to group items without cutting through leading avatars/icons.
/// - CAUTION: Use full-width dividers sparingly to prevent visual clutter in dense lists.
library;

export 'tashil_divider.dart';
export 'm3_dividers_showcase_dialog.dart';
