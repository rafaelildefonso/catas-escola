import 'dart:typed_data';

class PickedAttachment {
  final String id;
  final String path;
  final String name;
  final bool isImage;
  final Uint8List? bytes; // Útil para web ou preview em memória
  final String? url; // URL do arquivo após upload

  PickedAttachment({
    required this.id,
    required this.path,
    required this.name,
    this.isImage = false,
    this.bytes,
    this.url,
  });

  PickedAttachment copyWith({
    String? id,
    String? path,
    String? name,
    bool? isImage,
    Uint8List? bytes,
    String? url,
  }) {
    return PickedAttachment(
      id: id ?? this.id,
      path: path ?? this.path,
      name: name ?? this.name,
      isImage: isImage ?? this.isImage,
      bytes: bytes ?? this.bytes,
      url: url ?? this.url,
    );
  }
}
