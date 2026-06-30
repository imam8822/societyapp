const fs = require('fs');
const file = 'lib/screens/user/user_dashboard_screen.dart';
let content = fs.readFileSync(file, 'utf8');

const targets = ['TextStyle', 'Icon', 'Divider', 'Text', 'CircularProgressIndicator', 'BoxDecoration', 'IconThemeData', 'SizedBox', 'LinearGradient', 'EdgeInsets', 'Padding'];
for (const t of targets) {
  content = content.replace(new RegExp(`const \\s*${t}\\b`, 'g'), t);
}

fs.writeFileSync(file, content);
console.log('Fixed consts');
