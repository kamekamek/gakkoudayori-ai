import 'package:googleapis/classroom/v1.dart' as classroom;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:flutter/foundation.dart';
import 'google_auth_service.dart';

/// Google Classroom APIサービス
///
/// Google Classroomでの投稿・ファイル管理機能を提供
class ClassroomService {
  static classroom.ClassroomApi? _classroomApi;
  static drive.DriveApi? _driveApi;

  /// サービスの初期化
  static Future<void> initialize() async {
    final authClient = GoogleAuthService.authClient;
    if (authClient == null) {
      throw Exception('Google認証が必要です');
    }

    _classroomApi = classroom.ClassroomApi(authClient);
    _driveApi = drive.DriveApi(authClient);

    if (kDebugMode) {
      print('Classroom API サービス初期化完了');
    }
  }

  /// 認証チェック
  static Future<void> _checkAuthentication() async {
    if (!GoogleAuthService.isSignedIn) {
      throw Exception('Googleアカウントにログインしてください');
    }

    if (!GoogleAuthService.hasClassroomPermissions()) {
      throw Exception('認証クライアントが初期化されていません。再ログインしてください');
    }
    
    // 実際の権限を確認
    if (!await GoogleAuthService.verifyClassroomPermissions()) {
      throw Exception('Classroom権限が不足しています。Googleアカウントの設定でClassroomへのアクセスを許可してください');
    }
  }

  /// コース一覧を取得
  ///
  /// [teacherOnly] 教師として参加しているコースのみ取得
  /// Returns: コース一覧
  static Future<List<classroom.Course>> getCourses(
      {bool teacherOnly = true}) async {
    await _checkAuthentication();

    try {
      await initialize();

      if (kDebugMode) {
        print('コース一覧取得開始');
      }

      final response = await _classroomApi!.courses.list(
        teacherId: teacherOnly ? 'me' : null,
        courseStates: ['ACTIVE'], // アクティブなコースのみ
      );

      final courses = response.courses ?? [];

      if (kDebugMode) {
        print('取得したコース数: ${courses.length}');
        for (final course in courses) {
          print('- ${course.name} (ID: ${course.id})');
        }
      }

      return courses;
    } catch (e) {
      if (kDebugMode) {
        print('コース一覧取得エラー: $e');
      }
      await GoogleAuthService.handleAuthError(e);
      throw Exception('コース一覧の取得に失敗しました: $e');
    }
  }

  /// 特定のコースの詳細を取得
  ///
  /// [courseId] コースID
  /// Returns: コース詳細
  static Future<classroom.Course> getCourse(String courseId) async {
    await _checkAuthentication();

    try {
      await initialize();

      final course = await _classroomApi!.courses.get(courseId);

      if (kDebugMode) {
        print('コース詳細取得: ${course.name}');
      }

      return course;
    } catch (e) {
      await GoogleAuthService.handleAuthError(e);
      throw Exception('コース詳細の取得に失敗しました: $e');
    }
  }

  /// ファイルをGoogle Driveにアップロード
  ///
  /// [fileBytes] アップロードするファイルのバイトデータ
  /// [fileName] ファイル名
  /// [mimeType] MIMEタイプ
  /// [folderId] アップロード先フォルダID（オプション）
  /// Returns: アップロードされたファイルのID
  static Future<String> uploadFileToDrive({
    required Uint8List fileBytes,
    required String fileName,
    required String mimeType,
    String? folderId,
  }) async {
    await _checkAuthentication();

    try {
      await initialize();

      if (kDebugMode) {
        print('Google Driveへファイルアップロード開始: $fileName');
        print('ファイルサイズ: ${fileBytes.length} bytes');
      }

      final media = drive.Media(
        Stream.fromIterable([fileBytes]),
        fileBytes.length,
        contentType: mimeType,
      );

      final driveFile = drive.File()
        ..name = fileName
        ..parents = folderId != null ? [folderId] : null;

      final uploadedFile = await _driveApi!.files.create(
        driveFile,
        uploadMedia: media,
      );

      if (uploadedFile.id == null) {
        throw Exception('ファイルIDが取得できませんでした');
      }

      if (kDebugMode) {
        print('ファイルアップロード完了: ${uploadedFile.id}');
      }

      return uploadedFile.id!;
    } catch (e) {
      if (kDebugMode) {
        print('ファイルアップロードエラー: $e');
      }
      await GoogleAuthService.handleAuthError(e);
      throw Exception('ファイルのアップロードに失敗しました: $e');
    }
  }

  /// Classroomでアナウンスメントを投稿
  ///
  /// [courseId] 投稿先コースID
  /// [title] 投稿タイトル
  /// [description] 投稿内容
  /// [attachmentFileIds] 添付ファイルのDriveファイルIDリスト
  /// [scheduledTime] 予約投稿時刻（オプション）
  /// Returns: 作成されたアナウンスメントのID
  static Future<String> createAnnouncement({
    required String courseId,
    required String title,
    required String description,
    List<String> attachmentFileIds = const [],
    DateTime? scheduledTime,
  }) async {
    await _checkAuthentication();

    try {
      await initialize();

      if (kDebugMode) {
        print('アナウンスメント投稿開始');
        print('コースID: $courseId');
        print('タイトル: $title');
        print('添付ファイル数: ${attachmentFileIds.length}');
      }

      // 添付ファイルのマテリアルを作成
      final materials = <classroom.Material>[];

      // DriveFileを正しい形式で添付
      for (final fileId in attachmentFileIds) {
        // ファイル情報を取得してタイトルを設定
        String fileName;
        try {
          final driveFile = await _driveApi!.files.get(fileId) as drive.File;
          fileName = driveFile.name ?? 'attachment_$fileId';
        } catch (e) {
          fileName = 'attachment_$fileId';
          if (kDebugMode) {
            print('ファイル名取得エラー: $e');
          }
        }

        final driveFileMaterial = classroom.Material()
          ..driveFile = (classroom.SharedDriveFile()
            ..driveFile = (classroom.DriveFile()
              ..id = fileId
              ..title = fileName)
            ..shareMode = 'VIEW'); // 学生は閲覧のみ可能

        materials.add(driveFileMaterial);

        if (kDebugMode) {
          print('添付ファイル追加: $fileName (ID: $fileId)');
        }
      }

      // アナウンスメントオブジェクトを作成
      final announcement = classroom.Announcement()
        ..text = description
        ..materials = materials.isNotEmpty ? materials : null;

      // 予約投稿の設定
      if (scheduledTime != null) {
        announcement.scheduledTime = scheduledTime.toUtc().toIso8601String();
        announcement.state = 'DRAFT'; // 予約投稿の場合はドラフト状態

        if (kDebugMode) {
          print('予約投稿時刻: ${scheduledTime.toIso8601String()}');
        }
      } else {
        announcement.state = 'PUBLISHED'; // 即座に公開
      }

      // アナウンスメントを投稿
      final createdAnnouncement =
          await _classroomApi!.courses.announcements.create(
        announcement,
        courseId,
      );

      if (createdAnnouncement.id == null) {
        throw Exception('投稿IDが取得できませんでした');
      }

      if (kDebugMode) {
        print('アナウンスメント投稿完了: ${createdAnnouncement.id}');
      }

      return createdAnnouncement.id!;
    } catch (e) {
      if (kDebugMode) {
        print('アナウンスメント投稿エラー: $e');
      }
      await GoogleAuthService.handleAuthError(e);
      throw Exception('Classroomへの投稿に失敗しました: $e');
    }
  }

  /// 学級通信をClassroomに投稿（完全版）
  ///
  /// PDFファイルと画像を添付してClassroomに投稿
  /// [courseId] 投稿先コースID
  /// [title] 投稿タイトル
  /// [description] 投稿内容
  /// [pdfBytes] 学級通信PDFのバイトデータ
  /// [imageFiles] 添付画像ファイルのリスト
  /// [scheduledTime] 予約投稿時刻（オプション）
  /// Returns: 投稿結果情報
  static Future<Map<String, dynamic>> postNewsletterToClassroom({
    required String courseId,
    required String title,
    required String description,
    required Uint8List pdfBytes,
    List<Map<String, dynamic>> imageFiles = const [],
    DateTime? scheduledTime,
  }) async {
    try {
      final uploadedFileIds = <String>[];

      // PDFファイルをアップロード
      final pdfFileName =
          '${title}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final pdfFileId = await uploadFileToDrive(
        fileBytes: pdfBytes,
        fileName: pdfFileName,
        mimeType: 'application/pdf',
      );
      uploadedFileIds.add(pdfFileId);

      // 画像ファイルをアップロード
      for (int i = 0; i < imageFiles.length; i++) {
        final imageFile = imageFiles[i];
        final imageBytes = imageFile['bytes'] as Uint8List;
        final originalName = imageFile['name'] as String? ?? 'image_$i.jpg';
        final mimeType = imageFile['mimeType'] as String? ?? 'image/jpeg';

        final imageFileId = await uploadFileToDrive(
          fileBytes: imageBytes,
          fileName: originalName,
          mimeType: mimeType,
        );
        uploadedFileIds.add(imageFileId);
      }

      // Classroomに投稿
      final announcementId = await createAnnouncement(
        courseId: courseId,
        title: title,
        description: description,
        attachmentFileIds: uploadedFileIds,
        scheduledTime: scheduledTime,
      );

      return {
        'success': true,
        'announcementId': announcementId,
        'uploadedFileIds': uploadedFileIds,
        'pdfFileId': pdfFileId,
        'message': scheduledTime != null ? '予約投稿が設定されました' : 'Classroomに投稿しました',
      };
    } catch (e) {
      if (kDebugMode) {
        print('学級通信投稿エラー: $e');
      }

      return {
        'success': false,
        'error': e.toString(),
        'message': '投稿に失敗しました',
      };
    }
  }

  /// アナウンスメント一覧を取得
  ///
  /// [courseId] コースID
  /// [limit] 取得件数制限
  /// Returns: アナウンスメント一覧
  static Future<List<classroom.Announcement>> getAnnouncements(
    String courseId, {
    int limit = 20,
  }) async {
    await _checkAuthentication();

    try {
      await initialize();

      final response = await _classroomApi!.courses.announcements.list(
        courseId,
        pageSize: limit,
        announcementStates: ['PUBLISHED', 'DRAFT'],
        orderBy: 'updateTime desc',
      );

      final announcements = response.announcements ?? [];

      if (kDebugMode) {
        print('取得したアナウンスメント数: ${announcements.length}');
      }

      return announcements;
    } catch (e) {
      await GoogleAuthService.handleAuthError(e);
      throw Exception('アナウンスメント一覧の取得に失敗しました: $e');
    }
  }

  /// Classroom機能の動作テスト
  ///
  /// 各API機能が正常に動作するかテスト
  static Future<Map<String, bool>> testClassroomIntegration() async {
    final results = <String, bool>{};

    try {
      // 認証チェック
      results['authentication'] = GoogleAuthService.isSignedIn;

      if (!results['authentication']!) {
        return results;
      }

      // コース一覧取得テスト
      try {
        final courses = await getCourses();
        results['getCourses'] = courses.isNotEmpty;
      } catch (e) {
        results['getCourses'] = false;
        if (kDebugMode) {
          print('コース一覧取得テストエラー: $e');
        }
      }

      // Drive API アクセステスト（小さなテストファイル）
      try {
        final testData = Uint8List.fromList('test'.codeUnits);
        await uploadFileToDrive(
          fileBytes: testData,
          fileName: 'classroom_test.txt',
          mimeType: 'text/plain',
        );
        results['uploadFile'] = true;
      } catch (e) {
        results['uploadFile'] = false;
        if (kDebugMode) {
          print('ファイルアップロードテストエラー: $e');
        }
      }

      return results;
    } catch (e) {
      if (kDebugMode) {
        print('Classroom統合テストエラー: $e');
      }
      return results;
    }
  }
}
