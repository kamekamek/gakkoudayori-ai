/// Google Classroom関連のモデル

/// Classroomコース情報
class ClassroomCourse {
  final String id;
  final String name;
  final String section; // 1年1組など
  final String? description;
  final String teacherId;
  final String? teacherName;
  final int studentCount;
  final CourseState state;

  ClassroomCourse({
    required this.id,
    required this.name,
    required this.section,
    this.description,
    required this.teacherId,
    this.teacherName,
    this.studentCount = 0,
    this.state = CourseState.active,
  });

  String get displayName => '$name ($section)';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'section': section,
      'description': description,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'studentCount': studentCount,
      'state': state.name,
    };
  }

  factory ClassroomCourse.fromJson(Map<String, dynamic> json) {
    return ClassroomCourse(
      id: json['id'],
      name: json['name'],
      section: json['section'] ?? '',
      description: json['description'],
      teacherId: json['teacherId'],
      teacherName: json['teacherName'],
      studentCount: json['studentCount'] ?? 0,
      state: CourseState.values.firstWhere(
        (e) => e.name == json['state'],
        orElse: () => CourseState.active,
      ),
    );
  }
}

/// コースの状態
enum CourseState {
  active,      // アクティブ
  archived,    // アーカイブ済み
  suspended,   // 停止中
}

/// Classroom投稿設定
class ClassroomPostSettings {
  final String courseId;
  final String title;
  final String description;
  final DateTime? scheduledTime; // 予約投稿時間
  final bool enableEmailNotification;
  final bool saveToArchive;
  final List<String> attachmentIds; // Drive file IDs

  ClassroomPostSettings({
    required this.courseId,
    required this.title,
    required this.description,
    this.scheduledTime,
    this.enableEmailNotification = true,
    this.saveToArchive = true,
    this.attachmentIds = const [],
  });

  bool get isScheduled => scheduledTime != null;
  bool get isImmediate => scheduledTime == null;

  ClassroomPostSettings copyWith({
    String? courseId,
    String? title,
    String? description,
    DateTime? scheduledTime,
    bool? enableEmailNotification,
    bool? saveToArchive,
    List<String>? attachmentIds,
  }) {
    return ClassroomPostSettings(
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      enableEmailNotification: enableEmailNotification ?? this.enableEmailNotification,
      saveToArchive: saveToArchive ?? this.saveToArchive,
      attachmentIds: attachmentIds ?? this.attachmentIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'title': title,
      'description': description,
      'scheduledTime': scheduledTime?.toIso8601String(),
      'enableEmailNotification': enableEmailNotification,
      'saveToArchive': saveToArchive,
      'attachmentIds': attachmentIds,
    };
  }

  factory ClassroomPostSettings.fromJson(Map<String, dynamic> json) {
    return ClassroomPostSettings(
      courseId: json['courseId'],
      title: json['title'],
      description: json['description'],
      scheduledTime: json['scheduledTime'] != null 
          ? DateTime.parse(json['scheduledTime']) 
          : null,
      enableEmailNotification: json['enableEmailNotification'] ?? true,
      saveToArchive: json['saveToArchive'] ?? true,
      attachmentIds: (json['attachmentIds'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}

/// Classroom投稿結果
class ClassroomPostResult {
  final bool success;
  final String? postId;
  final String? error;
  final DateTime? postedAt;
  final String? postUrl;

  ClassroomPostResult({
    required this.success,
    this.postId,
    this.error,
    this.postedAt,
    this.postUrl,
  });

  ClassroomPostResult.success({
    required String postId,
    required DateTime postedAt,
    String? postUrl,
  }) : this(
    success: true,
    postId: postId,
    postedAt: postedAt,
    postUrl: postUrl,
  );

  ClassroomPostResult.error(String error) : this(
    success: false,
    error: error,
  );
}

/// Classroom認証状態
class ClassroomAuthState {
  final bool isAuthenticated;
  final String? userEmail;
  final String? userName;
  final DateTime? tokenExpiry;
  final List<String> scopes;

  ClassroomAuthState({
    this.isAuthenticated = false,
    this.userEmail,
    this.userName,
    this.tokenExpiry,
    this.scopes = const [],
  });

  bool get isTokenExpired {
    if (tokenExpiry == null) return false;
    return DateTime.now().isAfter(tokenExpiry!);
  }

  bool get isValidAuth => isAuthenticated && !isTokenExpired;

  ClassroomAuthState copyWith({
    bool? isAuthenticated,
    String? userEmail,
    String? userName,
    DateTime? tokenExpiry,
    List<String>? scopes,
  }) {
    return ClassroomAuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      tokenExpiry: tokenExpiry ?? this.tokenExpiry,
      scopes: scopes ?? this.scopes,
    );
  }
}

/// Drive ファイル情報
class DriveFileInfo {
  final String id;
  final String name;
  final String mimeType;
  final int size;
  final DateTime createdAt;
  final String? webViewLink;
  final String? downloadLink;

  DriveFileInfo({
    required this.id,
    required this.name,
    required this.mimeType,
    required this.size,
    required this.createdAt,
    this.webViewLink,
    this.downloadLink,
  });

  String get formattedSize {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  bool get isPdf => mimeType == 'application/pdf';
  bool get isImage => mimeType.startsWith('image/');

  factory DriveFileInfo.fromJson(Map<String, dynamic> json) {
    return DriveFileInfo(
      id: json['id'],
      name: json['name'],
      mimeType: json['mimeType'],
      size: int.parse(json['size'] ?? '0'),
      createdAt: DateTime.parse(json['createdTime']),
      webViewLink: json['webViewLink'],
      downloadLink: json['downloadLink'],
    );
  }
}

/// Classroomアナウンスメント情報
class ClassroomAnnouncement {
  final String id;
  final String courseId;
  final String text;
  final DateTime createdAt;
  final DateTime? scheduledTime;
  final AnnouncementState state;
  final List<DriveFileInfo> attachments;

  ClassroomAnnouncement({
    required this.id,
    required this.courseId,
    required this.text,
    required this.createdAt,
    this.scheduledTime,
    this.state = AnnouncementState.published,
    this.attachments = const [],
  });

  bool get isScheduled => scheduledTime != null;
  bool get isPublished => state == AnnouncementState.published;

  factory ClassroomAnnouncement.fromJson(Map<String, dynamic> json) {
    return ClassroomAnnouncement(
      id: json['id'],
      courseId: json['courseId'],
      text: json['text'] ?? '',
      createdAt: DateTime.parse(json['creationTime']),
      scheduledTime: json['scheduledTime'] != null 
          ? DateTime.parse(json['scheduledTime']) 
          : null,
      state: AnnouncementState.values.firstWhere(
        (e) => e.name == json['state'],
        orElse: () => AnnouncementState.published,
      ),
      attachments: (json['materials'] as List<dynamic>?)
          ?.map((material) => DriveFileInfo.fromJson(material['driveFile']))
          .toList() ?? [],
    );
  }
}

/// アナウンスメントの状態
enum AnnouncementState {
  draft,      // 下書き
  published,  // 公開済み
  deleted,    // 削除済み
}