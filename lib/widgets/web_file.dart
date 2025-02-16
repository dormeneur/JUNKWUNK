import 'dart:typed_data';

class WebFile {
  final Uint8List bytes;
  final String name;

  WebFile(this.bytes, this.name);
}
