import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../exceptions/app_exceptions.dart';
import '../providers/error_provider.dart';

/// エラー表示ウィジェット
class ErrorDisplayWidget extends StatelessWidget {
  final bool showDismissButton;
  final bool showRetryButton;
  final VoidCallback? onRetry;
  final EdgeInsets margin;

  const ErrorDisplayWidget({
    super.key,
    this.showDismissButton = true,
    this.showRetryButton = false,
    this.onRetry,
    this.margin = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ErrorProvider>(
      builder: (context, errorProvider, child) {
        final currentError = errorProvider.currentError;
        
        if (currentError == null) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: margin,
          child: Card(
            color: Color(errorProvider.getErrorColor(currentError)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        errorProvider.getErrorIcon(currentError),
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getErrorTitle(currentError.exception),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (showDismissButton)
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => errorProvider.clearError(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentError.exception.userMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  if (currentError.exception.isRetryable && showRetryButton) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: onRetry,
                          child: const Text(
                            '再試行',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (currentError.context != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Context: ${currentError.context}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getErrorTitle(AppException exception) {
    return switch (exception) {
      NetworkException _ => 'ネットワークエラー',
      ApiException _ => 'サーバーエラー',
      AudioException _ => '音声エラー',
      SessionException _ => 'セッションエラー',
      ValidationException _ => '入力エラー',
      ContentException _ => 'コンテンツエラー',
      PermissionException _ => '権限エラー',
      _ => 'エラーが発生しました',
    };
  }
}

/// エラー統計表示ウィジェット（デバッグ用）
class ErrorStatsWidget extends StatelessWidget {
  const ErrorStatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ErrorProvider>(
      builder: (context, errorProvider, child) {
        final stats = errorProvider.getErrorStatistics();
        final debugInfo = errorProvider.getDebugInfo();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'エラー統計',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('総エラー数: ${debugInfo['total_errors']}'),
                Text('クリティカルエラー数: ${debugInfo['critical_errors']}'),
                Text('最近のエラー数: ${debugInfo['recent_errors_count']}'),
                Text('リトライ中: ${debugInfo['is_retrying']}'),
                if (stats.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('エラー種別:'),
                  ...stats.entries.map(
                    (entry) => Text('  ${entry.key}: ${entry.value}件'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// エラーリスト表示ウィジェット
class ErrorListWidget extends StatelessWidget {
  final int maxItems;
  final bool showDismissed;

  const ErrorListWidget({
    super.key,
    this.maxItems = 10,
    this.showDismissed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ErrorProvider>(
      builder: (context, errorProvider, child) {
        var errors = errorProvider.errors;
        
        if (!showDismissed) {
          errors = errors.where((error) => !error.isDismissed).toList();
        }
        
        errors = errors.take(maxItems).toList();

        if (errors.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('エラーはありません'),
            ),
          );
        }

        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'エラー履歴',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...errors.map((error) => _buildErrorListItem(context, error, errorProvider)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorListItem(BuildContext context, ErrorInfo error, ErrorProvider errorProvider) {
    return ListTile(
      leading: Text(
        errorProvider.getErrorIcon(error),
        style: const TextStyle(fontSize: 20),
      ),
      title: Text(
        error.exception.errorType,
        style: TextStyle(
          decoration: error.isDismissed ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(error.exception.userMessage),
          Text(
            error.timestamp.toString().substring(0, 19),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      trailing: !error.isDismissed
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => errorProvider.dismissError(error),
            )
          : null,
      tileColor: error.isDismissed ? Colors.grey[100] : null,
    );
  }
}

/// スナックバー形式のエラー表示
class ErrorSnackBar {
  static void show(BuildContext context, AppException exception, {VoidCallback? onRetry}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getIconData(exception),
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(exception.userMessage),
            ),
          ],
        ),
        backgroundColor: _getBackgroundColor(exception),
        action: exception.isRetryable && onRetry != null
            ? SnackBarAction(
                label: '再試行',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
        duration: Duration(seconds: exception.severity >= 3 ? 5 : 3),
      ),
    );
  }

  static IconData _getIconData(AppException exception) {
    switch (exception.severity) {
      case 1: // info
        return Icons.info;
      case 2: // warning
        return Icons.warning;
      case 3: // error
        return Icons.error;
      case 4: // critical
        return Icons.dangerous;
      default:
        return Icons.help;
    }
  }

  static Color _getBackgroundColor(AppException exception) {
    switch (exception.severity) {
      case 1: // info
        return Colors.blue;
      case 2: // warning
        return Colors.orange;
      case 3: // error
        return Colors.red;
      case 4: // critical
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}