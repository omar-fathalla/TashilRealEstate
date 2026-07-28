import os
import re

def fix_flutter_issues(directory):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                new_content = content
                
                # Fix withOpacity
                new_content = re.sub(r'\.withOpacity\((.*?)\)', r'.withValues(alpha: \1)', new_content)
                
                # Fix CardTheme -> CardThemeData
                new_content = new_content.replace('cardTheme: CardTheme(', 'cardTheme: CardThemeData(')
                
                # Fix BorderSide in BoxDecoration -> Border.all
                new_content = new_content.replace('border: BorderSide(color:', 'border: Border.all(color:')
                
                # Fix surfaceVariant -> surfaceContainerHighest
                new_content = re.sub(r'(?<!on)surfaceVariant', 'surfaceContainerHighest', new_content)
                
                # Fix Unused import in owner_overview_view.dart
                if file == 'owner_overview_view.dart':
                    new_content = new_content.replace("import 'package:tashil_real_estate/core/utils/responsive_layout.dart';\n", "")
                
                if new_content != content:
                    with open(filepath, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    print(f"Fixed {filepath}")

fix_flutter_issues('frontend/lib')
