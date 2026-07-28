const fs = require('fs');
const path = require('path');

function fixFlutterIssues(directory) {
    const files = fs.readdirSync(directory);
    for (const file of files) {
        const fullPath = path.join(directory, file);
        if (fs.statSync(fullPath).isDirectory()) {
            fixFlutterIssues(fullPath);
        } else if (fullPath.endsWith('.dart')) {
            let content = fs.readFileSync(fullPath, 'utf8');
            let newContent = content;

            // Fix withOpacity
            newContent = newContent.replace(/\.withOpacity\((.*?)\)/g, '.withValues(alpha: $1)');

            // Fix CardTheme -> CardThemeData
            newContent = newContent.replace(/cardTheme: CardTheme\(/g, 'cardTheme: CardThemeData(');

            // Fix BorderSide in BoxDecoration -> Border.all
            newContent = newContent.replace(/border: BorderSide\(color:/g, 'border: Border.all(color:');

            // Fix surfaceVariant -> surfaceContainerHighest
            newContent = newContent.replace(/(?<!on)surfaceVariant/g, 'surfaceContainerHighest');

            // Fix Unused import in owner_overview_view.dart
            if (file === 'owner_overview_view.dart') {
                newContent = newContent.replace("import 'package:tashil_real_estate/core/utils/responsive_layout.dart';\n", "");
            }

            if (newContent !== content) {
                fs.writeFileSync(fullPath, newContent, 'utf8');
                console.log(`Fixed ${fullPath}`);
            }
        }
    }
}

fixFlutterIssues('frontend/lib');
