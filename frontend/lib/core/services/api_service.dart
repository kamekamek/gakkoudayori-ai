import 'dart:convert';
import 'package:http/http.dart' as http;

/// AI機能のAPIサービス
class ApiService {
  final String baseUrl;
  final Map<String, String> _headers;

  ApiService({
    this.baseUrl = 'http://localhost:5000',
  }) : _headers = {
          'Content-Type': 'application/json',
        };

  /// AI補助機能を呼び出し
  Future<Map<String, dynamic>> callAIAssist({
    required String action,
    required String selectedText,
    required String instruction,
    required Map<String, dynamic> context,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/ai/assist');
      final body = jsonEncode({
        'action': action,
        'selected_text': selectedText,
        'instruction': instruction,
        'context': context,
      });

      final response = await http.post(
        url,
        headers: _headers,
        body: body,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('API call failed with status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('AI API call failed: $e');
    }
  }

  /// 音声転写機能
  Future<Map<String, dynamic>> transcribeAudio(String audioPath) async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/ai/transcribe');

      final request = http.MultipartRequest('POST', url);
      request.files.add(await http.MultipartFile.fromPath('audio', audioPath));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        return jsonDecode(responseBody) as Map<String, dynamic>;
      } else {
        throw Exception(
            'Transcription failed with status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Audio transcription failed: $e');
    }
  }

  /// HTML制約プロンプト生成
  Future<Map<String, dynamic>> generateConstrainedHTML({
    required String prompt,
    String customInstruction = '',
    String seasonTheme = '',
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/ai/generate-html');
      final body = jsonEncode({
        'prompt': prompt,
        'custom_instruction': customInstruction,
        'season_theme': seasonTheme,
      });

      final response = await http.post(
        url,
        headers: _headers,
        body: body,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
            'HTML generation failed with status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('HTML generation failed: $e');
    }
  }

  /// PDF生成機能
  Future<Map<String, dynamic>> generatePDF({
    required String htmlContent,
    String title = '学級通信',
    String pageSize = 'A4',
    String margin = '20mm',
    bool includeHeader = true,
    bool includeFooter = true,
    String customCss = '',
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/ai/generate-pdf');
      final body = jsonEncode({
        'html_content': htmlContent,
        'title': title,
        'page_size': pageSize,
        'margin': margin,
        'include_header': includeHeader,
        'include_footer': includeFooter,
        'custom_css': customCss,
      });

      final response = await http.post(
        url,
        headers: _headers,
        body: body,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
            'PDF generation failed with status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('PDF generation failed: $e');
    }
  }
}
