import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;
import 'dart:convert';
import '../utils/html_processing_utils.dart';

/// Playwrightと統一されたプレビューウィジェット
/// PDF生成時と同じスタイリング・レンダリングを提供
class UnifiedPreviewWidget extends StatefulWidget {
  final String htmlContent;
  final double height;
  final bool showLoadingIndicator;
  final VoidCallback? onContentReady;
  final Function(String)? onError;

  const UnifiedPreviewWidget({
    Key? key,
    required this.htmlContent,
    this.height = 600,
    this.showLoadingIndicator = true,
    this.onContentReady,
    this.onError,
  }) : super(key: key);

  @override
  State<UnifiedPreviewWidget> createState() => _UnifiedPreviewWidgetState();
}

class _UnifiedPreviewWidgetState extends State<UnifiedPreviewWidget> {
  String? _viewId;
  web.HTMLIFrameElement? _iframe;
  String _cachedContent = '';
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializePreview();
  }

  void _initializePreview() {
    if (_viewId != null && _cachedContent == widget.htmlContent) {
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // HTMLコンテンツの検証とサニタイズ
      final validation = HtmlProcessingUtils.validateHtmlContent(widget.htmlContent);
      
      if (!validation['isValid']) {
        final issues = validation['issues'] as List<String>;
        throw Exception('無効なHTMLコンテンツ: ${issues.join(', ')}');
      }

      // 警告がある場合はログ出力
      final warnings = validation['warnings'] as List<String>;
      if (warnings.isNotEmpty && kDebugMode) {
        debugPrint('📋 [UnifiedPreview] HTML警告: ${warnings.join(', ')}');
      }

      _viewId = 'unified-preview-${DateTime.now().millisecondsSinceEpoch}';
      _cachedContent = widget.htmlContent;

      // iframeエレメントの作成
      final safeHeight = widget.height.isFinite ? widget.height : 600.0;
      _iframe = web.HTMLIFrameElement()
        ..width = '100%'
        ..height = '${safeHeight.toInt()}px'
        ..style.width = '100%'
        ..style.height = '${safeHeight}px'
        ..style.border = 'none'
        ..style.borderRadius = '8px'
        ..style.backgroundColor = '#ffffff';

      // PlaywrightベースのフルHTMLドキュメントを生成
      final fullHtml = HtmlProcessingUtils.generateFullHtmlDocument(
        widget.htmlContent,
        title: '学級通信プレビュー',
        includePrintStyles: false,
      );

      // HTMLをData URLとして設定
      final encodedHtml = Uri.dataFromString(
        fullHtml,
        mimeType: 'text/html',
        encoding: Encoding.getByName('utf-8')!,
      ).toString();

      _iframe!.src = encodedHtml;

      // iframe読み込み完了イベント
      _iframe!.onLoad.listen((_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          widget.onContentReady?.call();
          
          if (kDebugMode) {
            debugPrint('📄 [UnifiedPreview] プレビュー読み込み完了');
          }
        }
      });

      // エラーハンドリング
      _iframe!.onError.listen((event) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = 'プレビューの読み込みに失敗しました';
          });
          widget.onError?.call(_errorMessage);
        }
      });

      // プラットフォームビューとして登録
      ui_web.platformViewRegistry.registerViewFactory(
        _viewId!,
        (int viewId) => _iframe!,
      );

    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'プレビューの初期化に失敗しました: $e';
      });
      widget.onError?.call(_errorMessage);
      
      if (kDebugMode) {
        debugPrint('📄 [UnifiedPreview] 初期化エラー: $e');
      }
    }
  }

  /// コンテンツを動的に更新
  void _updateContent(String newContent) {
    if (_iframe?.contentWindow != null && newContent != _cachedContent) {
      try {
        // 新しいHTMLドキュメントを生成
        final fullHtml = HtmlProcessingUtils.generateFullHtmlDocument(
          newContent,
          title: '学級通信プレビュー',
          includePrintStyles: false,
        );

        // iframeの内容を更新
        final encodedHtml = Uri.dataFromString(
          fullHtml,
          mimeType: 'text/html',
          encoding: Encoding.getByName('utf-8')!,
        ).toString();

        _iframe!.src = encodedHtml;
        _cachedContent = newContent;

        if (kDebugMode) {
          debugPrint('📄 [UnifiedPreview] コンテンツ動的更新完了');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('📄 [UnifiedPreview] 動的更新失敗、iframe再作成: $e');
        }
        // 動的更新が失敗した場合は再作成
        _initializePreview();
      }
    }
  }

  @override
  void didUpdateWidget(UnifiedPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.htmlContent != widget.htmlContent) {
      if (_iframe != null && _viewId != null) {
        _updateContent(widget.htmlContent);
      } else {
        _initializePreview();
      }
    }
  }

  @override
  void dispose() {
    // プラットフォームビューのクリーンアップは自動的に行われる
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeHeight = widget.height.isFinite ? widget.height : 600.0;

    if (_hasError) {
      return _buildErrorState(safeHeight);
    }

    if (_viewId == null) {
      return _buildLoadingState(safeHeight);
    }

    return Container(
      height: safeHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
        color: Colors.white,
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: HtmlElementView(
              viewType: _viewId!,
            ),
          ),
          if (_isLoading && widget.showLoadingIndicator)
            _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildLoadingState(double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'プレビューを初期化中...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'コンテンツ読み込み中...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[300]!),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red[400],
              ),
              const SizedBox(height: 16),
              Text(
                'プレビューエラー',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _errorMessage = '';
                  });
                  _initializePreview();
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('再試行'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// プレビューウィジェットのステータス
class PreviewStatus {
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final bool isContentReady;

  const PreviewStatus({
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
    this.isContentReady = false,
  });

  @override
  String toString() {
    return 'PreviewStatus(isLoading: $isLoading, hasError: $hasError, errorMessage: $errorMessage, isContentReady: $isContentReady)';
  }
}