import 'dart:convert';
import 'dart:io';

void main(List<String> arguments) async {
  if (arguments.length != 2) {
    print('Usage: dart create_structure.dart <json_file> <target_directory>');
    return;
  }

  String jsonFilePath = arguments[0];
  String targetDirectory = arguments[1];

  // 读取JSON文件
  File jsonFile = File(jsonFilePath);
  if (!await jsonFile.exists()) {
    print('Error: JSON file not found.');
    return;
  }

  String jsonString = await jsonFile.readAsString();
  Map<String, dynamic> jsonData = jsonDecode(jsonString);

  // 生成目录结构和文件
  createStructure(jsonData, targetDirectory);
}

void createStructure(Map<String, dynamic> data, String path) {
  data.forEach((key, value) {
    String newPath = '$path/$key';
    if (value is Map<String, dynamic>) {
      // 是目录
      Directory dir = Directory(newPath);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
        print('Created directory: $newPath');
      }
      createStructure(value, newPath);
    } else if (value is String) {
      // 是文件
      File file = File(newPath);
      if (file.existsSync()) return;
      file.writeAsStringSync('//$value');
      print('Created file: $newPath');
    }
  });
}
