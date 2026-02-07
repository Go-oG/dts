import 'dart:io';

import 'package:dts/dts.dart';

late List<String> obj;

void main() {
  // outExportFile(Directory("E:/Code/FlutterProject/chart/e_chart/lib/src"));
  fred();
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
    path = path.replaceAll("E:/Code/FlutterProject/chart/e_chart/lib", "");
    path = path.replaceAll("\\", "/");
    path = path.substring(1);

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

Geometry fred() {
  final pm = PrecisionModel();
  final gf = GeometryFactory(pm: pm);

  //  first polygon
  final shell1 = [
    (-76.1, 23.650755),
    (-76.1, 33.6085),
    (-98.0, 33.6085),
    (-98.0, 22.783333),
    (-98.116667, 22.783333),
    (-98.116667, 22.7),
    (-98.0, 22.7),
    (-98.0, 17.791497),
    (-76.1, 17.791497),
    (-76.1, 23.650755),
  ];

  final shell1Coordinates = [
    for (final point in shell1) Coordinate(point.$1, point.$2),
  ];

  final p1 = Polygon(LinearRing.of(shell1Coordinates, gf), [], gf);

  //  second polygon
  final shell2 = [
    (-75.400303, 20.43528),
    (-75.400303, 20.439801),
    (-73.286111, 20.439801),
    (-73.286111, 26.366669),
    (-81.0, 26.366669),
    (-81.0, 24.1666667),
    (-85.326389, 24.1666667),
    (-85.326389, 19.143375),
    (-76.283328, 19.143375),
    (-76.283328, 20.301842),
    (-75.820374, 20.301842),
    (-75.820374, 20.04614),
    (-75.400303, 20.04614),
    (-75.400303, 20.43528),
  ];

  final shell2Coordinates = [
    for (final point in shell2) Coordinate(point.$1, point.$2),
  ];

  final p2 = Polygon(LinearRing.of(shell2Coordinates, gf), [], gf);

  final union = p1.union2(p2);
  final diff = p1.difference(p2);

  return diff!;
}
