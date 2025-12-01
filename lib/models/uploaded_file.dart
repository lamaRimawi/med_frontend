class UploadedFile {
  final String id;
  final String name;
  final int size;
  final String type;
  final String path;
  final int timestamp;

  UploadedFile({
    required this.id,
    required this.name,
    required this.size,
    required this.type,
    required this.path,
    required this.timestamp,
  });
}
