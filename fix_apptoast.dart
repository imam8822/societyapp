import 'dart:io';

void main() {
  final dir = Directory(r'c:\Users\imam\source\repos\imam8822\societyapp\lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    if (file.path.contains('app_utils.dart')) continue;

    var content = file.readAsStringSync();
    var original = content;

    content = content.replaceAll('AppToast.', 'AppUtils.');

    if (content != original) {
      if (content.contains('AppUtils.') && !content.contains('core/app_utils.dart')) {
        final importIdx = content.indexOf('import ');
        if (importIdx != -1) {
          final endImport = content.indexOf('\n', importIdx);
          content = content.substring(0, endImport + 1) + "import 'package:society_app/core/app_utils.dart';\n" + content.substring(endImport + 1);
        }
      }
      file.writeAsStringSync(content);
      print('Updated \${file.path}');
    }
  }
}
