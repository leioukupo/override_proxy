Future<void> main(List<String> args) async {
  for (final arg in args) {
    print(pathToMethodName(arg));
    print(pathToFileName(arg));
  }
}

String pathToMethodName(String path) {
  // 移除路径前的斜杠，并根据斜杠或特殊符号分割路径
  var segments = path.split(RegExp(r'[/-_]+')).where((s) => s.isNotEmpty).toList();

  // 将每个部分转换为首字母大写，其余小写（驼峰式）
  var methodNameParts = segments.map((part) {
    // 如果部分只有一个字符，直接返回大写形式
    if (part.length == 1) {
      return part.toUpperCase();
    }
    // 将第一个字符大写，其余字符小写
    return part[0].toUpperCase() + part.substring(1).toLowerCase();
  }).toList();

  // 将第一个词改为小写，其余保持不变，然后连接成一个字符串
  if (methodNameParts.isNotEmpty) {
    methodNameParts[0] = methodNameParts[0].toLowerCase();
  }

  return methodNameParts.join('');
}

String pathToFileName(String path) {
  // 移除路径前的斜杠，并根据斜杠或特殊符号分割路径
  var segments = path.split(RegExp(r'[/-_]+')).where((s) => s.isNotEmpty).toList();

  // 将每个部分转换为首字母大写，其余小写（驼峰式）
  var fileNameParts = segments.map((part) {
    // 如果部分只有一个字符，直接返回小写形式
    if (part.length == 1) {
      return part.toLowerCase();
    }
    // 将第一个字符小写，其余字符保持不变
    return part[0].toLowerCase() + part.substring(1);
  }).toList();

  // 将第一个词改为小写，其余保持不变，然后连接成一个字符串
  if (fileNameParts.isNotEmpty) {
    fileNameParts[0] = fileNameParts[0].toLowerCase();
  }

  return fileNameParts.join('_');
}