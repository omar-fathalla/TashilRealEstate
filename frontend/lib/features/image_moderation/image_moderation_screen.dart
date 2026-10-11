import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/widgets/public_header_navbar.dart';
import 'package:tashil_real_estate/features/image_moderation/widgets/ai_image_moderator_dialog.dart';

class ImageModerationScreen extends StatelessWidget {
  const ImageModerationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, child) {
        final theme = Theme.of(context);
        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: const PublicHeaderNavbar(isSubPage: true, currentRoute: '/image-moderation'),
          body: const SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: AiImageModeratorDialog(),
              ),
            ),
          ),
        );
      },
    );
  }
}
