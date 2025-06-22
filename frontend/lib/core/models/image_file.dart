import 'dart:typed_data';

/// 画像ファイルのデータモデル
class ImageFile {
  final String id;
  final String name;
  final Uint8List bytes;
  final int size;
  final String? url; // Cloud Storage URL
  final String mimeType;
  final DateTime uploadedAt;
  final ImageMetadata? metadata;

  const ImageFile({
    required this.id,
    required this.name,
    required this.bytes,
    required this.size,
    this.url,
    required this.mimeType,
    required this.uploadedAt,
    this.metadata,
  });

  /// ファイルサイズを読みやすい形式で返す
  String get formattedSize {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// ファイル拡張子を取得
  String get extension {
    return name.split('.').last.toLowerCase();
  }

  /// 画像が圧縮されているかどうか
  bool get isCompressed => metadata?.isCompressed ?? false;

  /// コピーコンストラクタ
  ImageFile copyWith({
    String? id,
    String? name,
    Uint8List? bytes,
    int? size,
    String? url,
    String? mimeType,
    DateTime? uploadedAt,
    ImageMetadata? metadata,
  }) {
    return ImageFile(
      id: id ?? this.id,
      name: name ?? this.name,
      bytes: bytes ?? this.bytes,
      size: size ?? this.size,
      url: url ?? this.url,
      mimeType: mimeType ?? this.mimeType,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// JSON変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'size': size,
      'url': url,
      'mimeType': mimeType,
      'uploadedAt': uploadedAt.toIso8601String(),
      'metadata': metadata?.toJson(),
    };
  }

  factory ImageFile.fromJson(Map<String, dynamic> json) {
    return ImageFile(
      id: json['id'],
      name: json['name'],
      bytes: Uint8List(0), // バイトデータは別途取得
      size: json['size'],
      url: json['url'],
      mimeType: json['mimeType'],
      uploadedAt: DateTime.parse(json['uploadedAt']),
      metadata: json['metadata'] != null 
          ? ImageMetadata.fromJson(json['metadata']) 
          : null,
    );
  }
}

/// 画像のメタデータ
class ImageMetadata {
  final int width;
  final int height;
  final bool isCompressed;
  final int? originalSize;
  final double? compressionRatio;

  const ImageMetadata({
    required this.width,
    required this.height,
    this.isCompressed = false,
    this.originalSize,
    this.compressionRatio,
  });

  /// アスペクト比を取得
  double get aspectRatio => width / height;

  /// 解像度を文字列で取得
  String get resolution => '${width}x${height}';

  Map<String, dynamic> toJson() {
    return {
      'width': width,
      'height': height,
      'isCompressed': isCompressed,
      'originalSize': originalSize,
      'compressionRatio': compressionRatio,
    };
  }

  factory ImageMetadata.fromJson(Map<String, dynamic> json) {
    return ImageMetadata(
      width: json['width'],
      height: json['height'],
      isCompressed: json['isCompressed'] ?? false,
      originalSize: json['originalSize'],
      compressionRatio: json['compressionRatio']?.toDouble(),
    );
  }
}

/// 画像アップロードの進捗状態
enum ImageUploadStatus {
  waiting,    // 待機中
  uploading,  // アップロード中
  processing, // 処理中（圧縮など）
  completed,  // 完了
  failed,     // 失敗
}

/// 画像アップロードの結果
class ImageUploadResult {
  final ImageFile? imageFile;
  final ImageUploadStatus status;
  final String? error;
  final double progress; // 0.0 - 1.0

  const ImageUploadResult({
    this.imageFile,
    required this.status,
    this.error,
    this.progress = 0.0,
  });

  bool get isSuccess => status == ImageUploadStatus.completed && imageFile != null;
  bool get isLoading => status == ImageUploadStatus.uploading || status == ImageUploadStatus.processing;
  bool get isError => status == ImageUploadStatus.failed;
}