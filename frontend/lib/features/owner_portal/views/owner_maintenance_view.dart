import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/features/maintenance/views/maintenance_views.dart';
import 'package:tashil_real_estate/features/vision_maintenance/widgets/ai_vision_maintenance_dialog.dart';

/// The owner's maintenance requests from the Maintenance collection (TAQ-111), with status updates.
class OwnerMaintenanceView extends StatelessWidget {
  const OwnerMaintenanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return MaintenanceManagerView(
      headerAction: TashilButton(
        onPressed: () => AiVisionMaintenanceDialog.show(context),
        icon: Icons.troubleshoot_rounded,
        label: loc.tr('visionMaintenanceTitle'),
        variant: TashilButtonVariant.filled,
      ),
    );
  }
}
