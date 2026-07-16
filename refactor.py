import os
import re

lib_dir = r"c:\Users\imam\source\repos\imam8822\societyapp\lib"

# Matches: ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(something)));
# with optional newlines and indentation
pattern_error = re.compile(r'ScaffoldMessenger\.of\((.*?context.*?)\)\s*\.\s*showSnackBar\(\s*SnackBar\(\s*content:\s*Text\(([^)]+)\)\s*(?:,\s*backgroundColor:\s*[^)]+)?\)\s*\);?', re.MULTILINE | re.DOTALL)

# Same for success cases (we'll look for positive sounding strings like "successfully")
# Wait, some have specific colors or just simple text.

for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith(".dart") and file != "app_utils.dart":
            path = os.path.join(root, file)
            with open(path, "r", encoding="utf-8") as f:
                content = f.read()

            original = content
            
            def repl(m):
                ctx = m.group(1).strip()
                text = m.group(2).strip()
                # If text contains "success" case-insensitive, use showSuccess
                if "success" in text.lower():
                    return f"AppUtils.showSuccess({ctx}, {text});"
                else:
                    return f"AppUtils.showError({ctx}, {text});"
            
            content = pattern_error.sub(repl, content)
            
            # Also handle shared_widgets.dart specific snackbar variable
            content = content.replace("ScaffoldMessenger.of(context)\n      ..hideCurrentSnackBar()\n      ..showSnackBar(snackBar);", "")
            
            if content != original:
                # Add import if missing
                if "AppUtils.show" in content and "core/app_utils.dart" not in content:
                    # insert after first import
                    import_idx = content.find("import ")
                    if import_idx != -1:
                        end_import = content.find("\n", import_idx)
                        content = content[:end_import+1] + "import 'package:societyapp/core/app_utils.dart';\n" + content[end_import+1:]
                
                with open(path, "w", encoding="utf-8") as f:
                    f.write(content)
                print(f"Updated {file}")
