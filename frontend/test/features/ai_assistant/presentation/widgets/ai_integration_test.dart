import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:yutori_kyoshitu/features/ai_assistant/presentation/widgets/ai_assistant_panel.dart';
import 'package:yutori_kyoshitu/features/ai_assistant/presentation/widgets/ai_functions_grid.dart';
import 'package:yutori_kyoshitu/features/ai_assistant/presentation/widgets/custom_instruction_field.dart';
import 'package:yutori_kyoshitu/features/ai_assistant/presentation/widgets/ai_function_button.dart';
import 'package:yutori_kyoshitu/features/editor/providers/quill_editor_provider.dart';
import 'package:yutori_kyoshitu/core/services/api_service.dart';
import 'package:yutori_kyoshitu/core/models/ai_suggestion.dart';

import 'ai_integration_test.mocks.dart';

@GenerateMocks([ApiService])
void main() {
  group('T3-UI-004-H: AI統合連携実装 Tests', () {
    late MockApiService mockApiService;
    late QuillEditorProvider provider;

    setUp(() {
      mockApiService = MockApiService();
      provider = QuillEditorProvider();
    });

    group('AI統合連携 - UI → API連携', () {
      testWidgets('AI機能ボタンがAPI呼び出しを実行する', (WidgetTester tester) async {
        // Mock API response
        when(mockApiService.callAIAssist(
          action: anyNamed('action'),
          selectedText: anyNamed('selectedText'),
          instruction: anyNamed('instruction'),
          context: anyNamed('context'),
        )).thenAnswer((_) async => {
              'success': true,
              'suggestions': [
                {
                  'text': '生成された挨拶文です',
                  'confidence': 0.9,
                  'explanation': 'AI生成の説明',
                }
              ]
            });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChangeNotifierProvider<QuillEditorProvider>(
                create: (_) => provider,
                child: AIFunctionsGrid(
                  onFunctionPressed: (type) async {
                    await provider.executeAIFunction(type, mockApiService);
                  },
                ),
              ),
            ),
          ),
        );

        // AI補助パネルを展開
        provider.showAiAssist(selectedText: 'テストテキスト', cursorPosition: 0);
        await tester.pump();

        // 挨拶文生成ボタンをタップ
        await tester.tap(find.text('挨拶文生成'));
        await tester.pump();

        // API呼び出しが実行されることを確認
        verify(mockApiService.callAIAssist(
          action: 'add_greeting',
          selectedText: 'テストテキスト',
          instruction: any,
          context: any,
        )).called(1);
      });

      testWidgets('カスタム指示がAPI呼び出しに含まれる', (WidgetTester tester) async {
        String customInstruction = '';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChangeNotifierProvider<QuillEditorProvider>(
                create: (_) => provider,
                child: Column(
                  children: [
                    CustomInstructionField(
                      instruction: customInstruction,
                      onChanged: (value) {
                        customInstruction = value;
                        provider.setCustomInstruction(value);
                      },
                      onSubmit: () async {
                        await provider.executeCustomInstruction(mockApiService);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // カスタム指示を入力
        await tester.enterText(find.byType(TextField), 'もっと親しみやすく');
        await tester.pump();

        // 生成ボタンをタップ
        await tester.tap(find.text('生成'));
        await tester.pump();

        // カスタム指示が API 呼び出しに含まれることを確認
        verify(mockApiService.callAIAssist(
          action: 'custom_instruction',
          selectedText: any,
          instruction: 'もっと親しみやすく',
          context: any,
        )).called(1);
      });
    });

    group('AI統合連携 - レスポンス処理', () {
      testWidgets('AI API レスポンスが正しく処理される', (WidgetTester tester) async {
        final mockResponse = {
          'success': true,
          'suggestions': [
            {
              'text': 'AI生成コンテンツ',
              'confidence': 0.9,
              'explanation': '生成理由の説明',
            }
          ]
        };

        when(mockApiService.callAIAssist(
          action: anyNamed('action'),
          selectedText: anyNamed('selectedText'),
          instruction: anyNamed('instruction'),
          context: anyNamed('context'),
        )).thenAnswer((_) async => mockResponse);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChangeNotifierProvider<QuillEditorProvider>(
                create: (_) => provider,
                child: AIAssistantPanel(),
              ),
            ),
          ),
        );

        // AI機能を実行
        await provider.executeAIFunction(
            AIFunctionType.rewrite, mockApiService);
        await tester.pump();

        // プロバイダーにレスポンスが正しく保存されることを確認
        expect(provider.suggestions, isNotEmpty);
        expect(provider.suggestions.first.text, equals('AI生成コンテンツ'));
        expect(provider.suggestions.first.confidence, equals(0.9));
      });

      testWidgets('API エラーが適切にハンドリングされる', (WidgetTester tester) async {
        when(mockApiService.callAIAssist(
          action: anyNamed('action'),
          selectedText: anyNamed('selectedText'),
          instruction: anyNamed('instruction'),
          context: anyNamed('context'),
        )).thenThrow(Exception('API エラー'));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChangeNotifierProvider<QuillEditorProvider>(
                create: (_) => provider,
                child: AIAssistantPanel(),
              ),
            ),
          ),
        );

        // AI機能を実行（エラーが発生）
        await provider.executeAIFunction(
            AIFunctionType.rewrite, mockApiService);
        await tester.pump();

        // エラーメッセージが設定されることを確認
        expect(provider.errorMessage, isNotNull);
        expect(provider.errorMessage, contains('AI処理でエラーが発生しました'));
      });
    });

    group('AI統合連携 - エディタ挿入機能', () {
      testWidgets('AI提案がエディタに挿入される', (WidgetTester tester) async {
        final testSuggestion = AISuggestion(
          text: '挿入テストコンテンツ',
          confidence: 0.8,
          explanation: 'テスト用の提案',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChangeNotifierProvider<QuillEditorProvider>(
                create: (_) => provider,
                child: AIAssistantPanel(),
              ),
            ),
          ),
        );

        // 提案を適用
        provider.applySuggestion(testSuggestion);
        await tester.pump();

        // 提案が適用された後、リストがクリアされることを確認
        expect(provider.suggestions, isEmpty);
      });

      testWidgets('エディタ挿入でエラーハンドリングされる', (WidgetTester tester) async {
        // Bridge service が null の場合のテスト
        provider.setBridgeService(null);

        final testSuggestion = AISuggestion(
          text: 'テストコンテンツ',
          confidence: 0.8,
          explanation: 'テスト用',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChangeNotifierProvider<QuillEditorProvider>(
                create: (_) => provider,
                child: AIAssistantPanel(),
              ),
            ),
          ),
        );

        // エラーハンドリングが正しく動作することを確認
        expect(() => provider.applySuggestion(testSuggestion), returnsNormally);
      });
    });

    group('AI統合連携 - 統合テスト', () {
      testWidgets('完全なAI統合フローが動作する', (WidgetTester tester) async {
        final mockResponse = {
          'success': true,
          'suggestions': [
            {
              'text': '統合テスト用コンテンツ',
              'confidence': 0.95,
              'explanation': '統合テスト説明',
            }
          ]
        };

        when(mockApiService.callAIAssist(
          action: anyNamed('action'),
          selectedText: anyNamed('selectedText'),
          instruction: anyNamed('instruction'),
          context: anyNamed('context'),
        )).thenAnswer((_) async => mockResponse);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChangeNotifierProvider<QuillEditorProvider>(
                create: (_) => provider,
                child: Column(
                  children: [
                    AIAssistantPanel(),
                    AIFunctionsGrid(
                      onFunctionPressed: (type) async {
                        await provider.executeAIFunction(type, mockApiService);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // 1. AI補助パネルを展開
        await tester.tap(find.text('AI補助'));
        await tester.pump();

        // 2. AI機能ボタンをクリック
        await tester.tap(find.text('文章改善'));
        await tester.pump();

        // 3. API 呼び出しが正しく実行される
        verify(mockApiService.callAIAssist(
          action: 'rewrite',
          selectedText: any,
          instruction: any,
          context: any,
        )).called(1);

        // 4. レスポンスが正しく処理される
        expect(provider.suggestions, isNotEmpty);

        // 5. 提案をエディタに適用
        provider.applySuggestion(provider.suggestions.first);
        await tester.pump();

        // 6. 提案リストがクリアされる
        expect(provider.suggestions, isEmpty);
      });
    });
  });
}
