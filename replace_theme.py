import os
import re

directory = r"C:\Users\imam\source\repos\imam8822\societyapp\lib"

replacements = {
    r"AppTheme\.bgGrey": r"context.colors.bgGrey",
    r"AppTheme\.primaryLight": r"context.colors.primaryLight",
    r"AppTheme\.primary": r"context.colors.primary",
    r"AppTheme\.accent": r"context.colors.accent",
    r"AppTheme\.warning": r"context.colors.warning",
    r"AppTheme\.error": r"context.colors.error",
    r"AppTheme\.textDark": r"context.colors.textDark",
    r"AppTheme\.textGrey": r"context.colors.textGrey",
    r"AppTheme\.white": r"context.colors.surfaceWhite",
    r"AppTheme\.divider": r"context.colors.divider",
    r"AppTheme\.cardShadow": r"context.colors.cardShadow",
}

for root, _, files in os.walk(directory):
    for file in files:
        if file.endswith(".dart") and file != "constants.dart" and file != "theme_provider.dart":
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
                
            original = content
            for old, new in replacements.items():
                content = re.sub(old, new, content)
                
            if original != content:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f"Updated: {filepath}")

print("Done replacing.")
