import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

Future<void> downloadFile(String url, String filename) async {
  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) {
    throw Exception('Server returned ${response.statusCode}');
  }
  final directory =
      await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$filename');
  await file.writeAsBytes(response.bodyBytes);
}
