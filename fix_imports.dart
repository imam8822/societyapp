import 'dart:io';

void main() {
  final dir = Directory(r'c:\Users\imam\source\repos\imam8822\societyapp\lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    var content = file.readAsStringSync();
    var original = content;

    content = content.replaceAll("package:societyapp/", "package:society_app/");

    if (content != original) {
      file.writeAsStringSync(content);
      print('Updated \${file.path}');
    }
  }
}
