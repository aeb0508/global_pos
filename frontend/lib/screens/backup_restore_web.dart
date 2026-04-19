// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<void> downloadFile(String url, String filename) async {
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename);
  html.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
}
