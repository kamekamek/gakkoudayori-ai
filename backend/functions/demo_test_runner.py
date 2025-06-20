#!/usr/bin/env python3
"""
ADK準拠システム デモ用テストランナー

実際のユーザーシナリオに基づく動作確認ツール
"""

import os
import json
import time
from datetime import datetime

# デモ用環境設定
os.environ['ADK_MIGRATION_PERCENTAGE'] = '50'
os.environ['GOOGLE_CLOUD_PROJECT'] = 'gakkoudayori-ai-demo'

from adk_compliant_tools import (
    generate_newsletter_content,
    generate_design_specification,
    generate_html_newsletter,
    modify_html_content,
    validate_newsletter_quality
)

def print_section(title: str):
    """セクション区切り表示"""
    print(f"\n{'='*60}")
    print(f"🎯 {title}")
    print('='*60)

def print_result(step: str, result: dict, show_content: bool = True):
    """結果表示"""
    status_emoji = "✅" if result.get('status') == 'success' else "❌"
    print(f"\n{status_emoji} {step}")
    print(f"   ステータス: {result.get('status')}")
    
    if result.get('status') == 'success':
        if show_content and 'content' in result:
            content = result['content'][:200] + "..." if len(result.get('content', '')) > 200 else result.get('content', '')
            print(f"   コンテンツ: {content}")
        if 'processing_time_ms' in result:
            print(f"   処理時間: {result['processing_time_ms']}ms")
        if 'word_count' in result:
            print(f"   文字数: {result['word_count']}文字")
        if 'quality_score' in result:
            print(f"   品質スコア: {result['quality_score']}/100")
    else:
        print(f"   エラー: {result.get('error_message')}")
        print(f"   エラーコード: {result.get('error_code')}")

def run_user_scenario_1():
    """ユーザーシナリオ1: 運動会の学級通信作成"""
    print_section("シナリオ1: 運動会の学級通信作成")
    
    # 模擬音声認識結果
    audio_transcript = """
    今日は運動会の練習をしました。
    子どもたちは徒競走とリレーの練習を頑張っていました。
    特にたかしくんは最初は走るのが苦手でしたが、
    毎日練習を重ねて今ではクラスで3番目に速くなりました。
    みんなで応援し合う姿がとても印象的でした。
    来週の本番が楽しみです。
    """
    
    # Step 1: コンテンツ生成
    print("\n📝 Step 1: 音声からコンテンツ生成")
    content_result = generate_newsletter_content(
        audio_transcript=audio_transcript.strip(),
        grade_level="3年1組",
        content_type="newsletter"
    )
    print_result("コンテンツ生成", content_result)
    
    if content_result['status'] != 'success':
        print("❌ コンテンツ生成に失敗したため、シナリオを中断します")
        return None
    
    # Step 2: デザイン仕様生成
    print("\n🎨 Step 2: デザイン仕様生成")
    design_result = generate_design_specification(
        content=content_result['content'],
        theme="seasonal",
        grade_level="3年1組"
    )
    print_result("デザイン仕様生成", design_result, show_content=False)
    
    if design_result['status'] == 'success':
        print(f"   季節: {design_result['season']}")
        print(f"   テーマ: {design_result['theme']}")
        color_scheme = design_result['design_spec']['color_scheme']
        print(f"   プライマリカラー: {color_scheme['primary']}")
    
    if design_result['status'] != 'success':
        print("❌ デザイン仕様生成に失敗したため、シナリオを中断します")
        return None
    
    # Step 3: HTML生成
    print("\n🌐 Step 3: HTML学級通信生成")
    html_result = generate_html_newsletter(
        content=content_result['content'],
        design_spec=design_result['design_spec'],
        template_type="newsletter"
    )
    print_result("HTML生成", html_result, show_content=False)
    
    if html_result['status'] == 'success':
        print(f"   HTML文字数: {html_result['char_count']}")
        print(f"   制約チェック: {'✅ 合格' if html_result['validation_passed'] else '❌ 不合格'}")
        # HTMLプレビュー（最初の100文字）
        html_preview = html_result['html'][:100] + "..." if len(html_result['html']) > 100 else html_result['html']
        print(f"   HTMLプレビュー: {html_preview}")
    
    if html_result['status'] != 'success':
        print("❌ HTML生成に失敗したため、シナリオを中断します")
        return None
    
    # Step 4: 品質検証
    print("\n🔍 Step 4: 品質検証")
    quality_result = validate_newsletter_quality(
        html_content=html_result['html'],
        original_content=content_result['content']
    )
    print_result("品質検証", quality_result, show_content=False)
    
    if quality_result['status'] == 'success':
        print(f"   総合評価: {quality_result['assessment']}")
        print(f"   カテゴリ別スコア:")
        for category, score in quality_result['category_scores'].items():
            print(f"     - {category}: {score}/100")
        if quality_result['suggestions']:
            print(f"   改善提案: {', '.join(quality_result['suggestions'][:2])}")
    
    return {
        'content': content_result,
        'design': design_result,
        'html': html_result,
        'quality': quality_result
    }

def run_user_scenario_2():
    """ユーザーシナリオ2: HTML修正機能のテスト"""
    print_section("シナリオ2: HTML修正機能テスト")
    
    # 既存のHTMLサンプル
    sample_html = '''<h1 style="color: #4CAF50; font-family: 'Noto Sans JP';">3年1組 学級通信 6月号</h1>
<p style="font-family: 'Hiragino Sans';">保護者の皆様へ</p>
<p style="font-family: 'Hiragino Sans';">今日は運動会の練習を行いました。子どもたちの頑張る姿をご紹介します。</p>'''
    
    print("📄 元のHTML:")
    print(sample_html)
    
    # HTML修正テスト
    print("\n✏️ 修正要求: タイトルの色を青色に変更")
    modification_result = modify_html_content(
        current_html=sample_html,
        modification_request="タイトルの色を青色に変更してください"
    )
    print_result("HTML修正", modification_result, show_content=False)
    
    if modification_result['status'] == 'success':
        print(f"   変更内容: {modification_result['changes_made']}")
        print(f"   修正タイプ: {modification_result['modification_type']}")
        print("📄 修正後のHTML:")
        print(modification_result['modified_html'])
    
    return modification_result

def run_error_handling_test():
    """エラーハンドリングテスト"""
    print_section("エラーハンドリングテスト")
    
    # テスト1: 空の音声認識結果
    print("\n🚫 テスト1: 空の音声認識結果")
    error_result1 = generate_newsletter_content(
        audio_transcript="",
        grade_level="3年1組",
        content_type="newsletter"
    )
    print_result("空入力エラー", error_result1)
    
    # テスト2: 不正なデザイン仕様
    print("\n🚫 テスト2: 不正なデザイン仕様")
    error_result2 = generate_html_newsletter(
        content="テスト内容",
        design_spec={},  # 空の辞書
        template_type="newsletter"
    )
    print_result("不正仕様エラー", error_result2)
    
    # テスト3: 不十分なコンテンツ
    print("\n🚫 テスト3: 不十分なコンテンツ")
    error_result3 = validate_newsletter_quality(
        html_content="",
        original_content="テスト"
    )
    print_result("不十分コンテンツエラー", error_result3)
    
    return [error_result1, error_result2, error_result3]

def run_performance_test():
    """パフォーマンステスト"""
    print_section("パフォーマンステスト")
    
    test_content = "パフォーマンステスト用のサンプルコンテンツです。" * 10
    
    # 複数回実行して平均時間を測定
    times = []
    iterations = 3
    
    print(f"🏃 デザイン仕様生成を{iterations}回実行してパフォーマンス測定...")
    
    for i in range(iterations):
        start_time = time.time()
        result = generate_design_specification(
            content=test_content,
            theme="modern",
            grade_level="4年2組"
        )
        end_time = time.time()
        
        if result['status'] == 'success':
            processing_time = (end_time - start_time) * 1000  # ミリ秒
            times.append(processing_time)
            print(f"   実行{i+1}: {processing_time:.2f}ms")
    
    if times:
        avg_time = sum(times) / len(times)
        print(f"\n📊 パフォーマンス結果:")
        print(f"   平均処理時間: {avg_time:.2f}ms")
        print(f"   最小時間: {min(times):.2f}ms")
        print(f"   最大時間: {max(times):.2f}ms")
        print(f"   目標時間(5000ms)との比較: {'✅ 達成' if avg_time < 5000 else '❌ 未達成'}")
    
    return times

def generate_demo_report(scenario1_result, scenario2_result, error_results, performance_times):
    """デモレポート生成"""
    print_section("📊 デモ実行レポート")
    
    print(f"実行日時: {datetime.now().strftime('%Y年%m月%d日 %H:%M:%S')}")
    print(f"環境: ADK準拠システム (移行率: {os.getenv('ADK_MIGRATION_PERCENTAGE')}%)")
    
    # 成功率計算
    total_tests = 0
    successful_tests = 0
    
    if scenario1_result:
        for key, result in scenario1_result.items():
            total_tests += 1
            if result['status'] == 'success':
                successful_tests += 1
    
    if scenario2_result:
        total_tests += 1
        if scenario2_result['status'] == 'success':
            successful_tests += 1
    
    # エラーハンドリングテスト（エラーが正しく返されることが成功）
    for error_result in error_results:
        total_tests += 1
        if error_result['status'] == 'error' and 'error_code' in error_result:
            successful_tests += 1
    
    success_rate = (successful_tests / total_tests) * 100 if total_tests > 0 else 0
    
    print(f"\n📈 実行統計:")
    print(f"   総テスト数: {total_tests}")
    print(f"   成功数: {successful_tests}")
    print(f"   成功率: {success_rate:.1f}%")
    
    if performance_times:
        avg_performance = sum(performance_times) / len(performance_times)
        print(f"   平均処理時間: {avg_performance:.2f}ms")
    
    print(f"\n🎯 システム評価:")
    if success_rate >= 90:
        print("   ✅ 優秀 - システムは正常に動作しています")
    elif success_rate >= 70:
        print("   ⚠️ 良好 - 軽微な問題がある可能性があります")
    else:
        print("   ❌ 要改善 - システムに問題があります")
    
    print(f"\n📋 次のステップ:")
    print("   1. 実際のAPIサーバー起動テスト")
    print("   2. フロントエンドとの連携テスト")
    print("   3. 段階的本番デプロイ")

def main():
    """メイン実行関数"""
    print("🚀 ADK準拠システム デモ開始")
    print(f"環境: ADK移行率 {os.getenv('ADK_MIGRATION_PERCENTAGE')}%")
    
    try:
        # シナリオ1: 通常の学級通信作成フロー
        scenario1_result = run_user_scenario_1()
        
        # シナリオ2: HTML修正機能
        scenario2_result = run_user_scenario_2()
        
        # エラーハンドリングテスト
        error_results = run_error_handling_test()
        
        # パフォーマンステスト
        performance_times = run_performance_test()
        
        # デモレポート生成
        generate_demo_report(scenario1_result, scenario2_result, error_results, performance_times)
        
        print("\n🎉 デモ完了!")
        
    except Exception as e:
        print(f"\n❌ デモ実行中にエラーが発生しました: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()