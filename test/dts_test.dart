import 'dart:io';

late List<String> obj;

void main() {

}

void outExportFile(Directory dir) {
  List<File> fileList = [];
  List<Directory> dirList = [dir];
  while (dirList.isNotEmpty) {
    final dir = dirList.removeAt(0);
    final List<Directory> nextList = [];
    for (final file in dir.listSync()) {
      if (file is Directory) {
        nextList.add(file);
        continue;
      }
      if (file is File && file.absolute.path.endsWith(".dart")) {
        fileList.add(file);
      }
    }
    nextList.sort((a, b) {
      return a.path.compareTo(b.path);
    });
    dirList.insertAll(0, nextList);
  }

  for (var file in fileList) {
    var path = file.absolute.path;
    path = path.replaceAll("/Users/wzp/Develop/Project/Flutter/dts/lib", "");
    path = path.replaceAll("\\", "/");
    path = "export '$path';";
    print(path);
  }
}

void _changeLibraryDep(Directory dir) {
  List<File> fileList = [];
  List<Directory> dirList = [dir];
  while (dirList.isNotEmpty) {
    final dir = dirList.removeAt(0);
    final List<Directory> nextList = [];
    for (final file in dir.listSync()) {
      if (file is Directory) {
        nextList.add(file);
        continue;
      }
      if (file is File && file.absolute.path.endsWith(".dart")) {
        fileList.add(file);
      }
    }
    nextList.sort((a, b) {
      return a.path.compareTo(b.path);
    });
    dirList.insertAll(0, nextList);
  }

  for (var file in fileList) {
    var content = file.readAsStringSync();
 //   content = content.replaceAll("import 'package:dts/src/base.dart';", "import 'package:d_util/d_util.dart';");
    content = content.replaceAll("import 'package:d_util/d_util.dart;'", "import 'package:d_util/d_util.dart';");
    file.writeAsString(content);
  }
}
