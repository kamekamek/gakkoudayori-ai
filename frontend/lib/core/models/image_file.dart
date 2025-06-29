import 'dart:typed_data';

/// 画像ファイルのデータモデル
class ImageFile {
  final String id;
  final String name;
  final Uint8List bytes;
  final int size;
  final String? url; // アップロード後のURL
  final String mimeType;
  final DateTime uploadedAt;
  final bool isCompressed;
  final int? originalSize;

  ImageFile({
    required this.id,
    required this.name,
    required this.bytes,
    required this.size,
    this.url,
    required this.mimeType,
    required this.uploadedAt,
    this.isCompressed = false,
    this.originalSize,
  });

  /// ファイルサイズを人間が読める形式で返す
  String get sizeDisplay {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// 圧縮率を計算
  double? get compressionRatio {
    if (originalSize == null) return null;
    return ((originalSize! - size) / originalSize!) * 100;
  }

  /// 圧縮率の表示文字列
  String get compressionDisplay {
    final ratio = compressionRatio;
    if (ratio == null) return '';
    return '圧縮率: ${ratio.toStringAsFixed(1)}%';
  }

  /// ファイルの拡張子を取得
  String get extension {
    return name.split('.').last.toLowerCase();
  }

  /// 画像形式かどうか判定
  bool get isImage {
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg'];
    return imageExtensions.contains(extension);
  }

  /// コピーを作成（一部プロパティを変更）
  ImageFile copyWith({
    String? id,
    String? name,
    Uint8List? bytes,
    int? size,
    String? url,
    String? mimeType,
    DateTime? uploadedAt,
    bool? isCompressed,
    int? originalSize,
  }) {
    return ImageFile(
      id: id ?? this.id,
      name: name ?? this.name,
      bytes: bytes ?? this.bytes,
      size: size ?? this.size,
      url: url ?? this.url,
      mimeType: mimeType ?? this.mimeType,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      isCompressed: isCompressed ?? this.isCompressed,
      originalSize: originalSize ?? this.originalSize,
    );
  }

  /// JSONに変換（URLのみ保存）
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'size': size,
      'url': url,
      'mimeType': mimeType,
      'uploadedAt': uploadedAt.toIso8601String(),
      'isCompressed': isCompressed,
      'originalSize': originalSize,
    };
  }

  /// JSONから復元（bytesは含まれない）
  factory ImageFile.fromJson(Map<String, dynamic> json) {
    return ImageFile(
      id: json['id'] as String,
      name: json['name'] as String,
      bytes: Uint8List(0), // 空のデータ
      size: json['size'] as int,
      url: json['url'] as String?,
      mimeType: json['mimeType'] as String,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      isCompressed: json['isCompressed'] as bool? ?? false,
      originalSize: json['originalSize'] as int?,
    );
  }

  @override
  String toString() {
    return 'ImageFile(id: $id, name: $name, size: $sizeDisplay, url: $url)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ImageFile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 画像アップロードの結果
class ImageUploadResult {
  final ImageFile imageFile;
  final bool success;
  final String? error;
  final Duration uploadTime;

  ImageUploadResult({
    required this.imageFile,
    required this.success,
    this.error,
    required this.uploadTime,
  });

  @override
  String toString() {
    return 'ImageUploadResult(success: $success, file: ${imageFile.name}, time: ${uploadTime.inMilliseconds}ms)';
  }
}
