import 'dart:io';

void main() {
  final dir = Directory(r'c:\Users\imam\source\repos\imam8822\societyapp\lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    if (file.path.contains('app_utils.dart')) continue;

    var content = file.readAsStringSync();
    var original = content;

    // Standard single line catches
    content = content.replaceAll(
      "ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));",
      "AppUtils.showError(context, e.toString());"
    );
    content = content.replaceAll(
      "ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text(e.toString())));",
      "AppUtils.showError(this.context, e.toString());"
    );
    content = content.replaceAll(
      "ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiError(e))));",
      "AppUtils.showError(context, apiError(e));"
    );
    content = content.replaceAll(
      "ScaffoldMessenger.of(context)\n            .showSnackBar(SnackBar(content: Text(apiError(e))));",
      "AppUtils.showError(context, apiError(e));"
    );
    content = content.replaceAll(
      "ScaffoldMessenger.of(context).showSnackBar(\n            const SnackBar(content: Text('Member added successfully!')));",
      "AppUtils.showSuccess(context, 'Member added successfully!');"
    );
    content = content.replaceAll(
      "ScaffoldMessenger.of(context).showSnackBar(\n            const SnackBar(content: Text('Settings saved!')));",
      "AppUtils.showSuccess(context, 'Settings saved!');"
    );
    content = content.replaceAll(
      "ScaffoldMessenger.of(context).showSnackBar(\n            const SnackBar(content: Text('Member updated successfully')));",
      "AppUtils.showSuccess(context, 'Member updated successfully');"
    );
    content = content.replaceAll(
      "ScaffoldMessenger.of(context).showSnackBar(\n            SnackBar(content: Text(e.toString())));",
      "AppUtils.showError(context, e.toString());"
    );

    // Multiline specific blocks
    content = content.replaceAll(
      "ScaffoldMessenger.of(context).showSnackBar(\n                        SnackBar(content: Text('Error: \$e')),\n                      );",
      "AppUtils.showError(context, 'Error: \$e');"
    );

    content = content.replaceAll(
      "ScaffoldMessenger.of(context).showSnackBar(\n        SnackBar(content: const Text('Amount must be greater than zero'), backgroundColor: context.colors.error),\n      );",
      "AppUtils.showError(context, 'Amount must be greater than zero');"
    );
    content = content.replaceAll(
      "ScaffoldMessenger.of(context).showSnackBar(\n          SnackBar(\n            content: const Text('Ledger adjustment recorded successfully'),\n            backgroundColor: context.colors.primary,\n          ),\n        );",
      "AppUtils.showSuccess(context, 'Ledger adjustment recorded successfully');"
    );
    content = content.replaceAll(
      "ScaffoldMessenger.of(context).showSnackBar(\n          SnackBar(content: Text(apiError(e)), backgroundColor: context.colors.error),\n        );",
      "AppUtils.showError(context, apiError(e));"
    );

    // If there were any replacements, add import
    if (content != original) {
      if (content.contains('AppUtils.show') && !content.contains('core/app_utils.dart')) {
        final importIdx = content.indexOf('import ');
        if (importIdx != -1) {
          final endImport = content.indexOf('\n', importIdx);
          content = content.substring(0, endImport + 1) + "import 'package:societyapp/core/app_utils.dart';\n" + content.substring(endImport + 1);
        }
      }
      file.writeAsStringSync(content);
      print('Updated \${file.path}');
    }
  }
}
