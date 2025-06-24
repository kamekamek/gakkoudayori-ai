# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import re
import json
import logging
from typing import Dict, List, Any, Optional
from bs4 import BeautifulSoup, NavigableString
from urllib.parse import urlparse

logger = logging.getLogger(__name__)


def validate_html_structure(html_content: str) -> Dict[str, Any]:
    """HTMLの構造を検証し、詳細な分析結果を返します。"""
    try:
        soup = BeautifulSoup(html_content, 'html.parser')
        
        validation_results = {
            "structure": _validate_basic_structure(soup, html_content),
            "accessibility": _validate_accessibility(soup),
            "performance": _validate_performance(soup, html_content),
            "seo": _validate_seo(soup),
            "printing": _validate_printing_compatibility(soup),
            "overall_score": 0,
            "recommendations": []
        }
        
        # 全体スコアを計算
        validation_results["overall_score"] = _calculate_overall_score(validation_results)
        
        # 推奨事項をまとめる
        validation_results["recommendations"] = _compile_recommendations(validation_results)
        
        return validation_results
        
    except Exception as e:
        logger.error(f"HTML validation error: {e}", exc_info=True)
        return {
            "structure": {"valid": False, "errors": [f"Parse error: {str(e)}"]},
            "accessibility": {"score": 0, "issues": []},
            "performance": {"score": 0, "issues": []},
            "seo": {"score": 0, "issues": []},
            "printing": {"score": 0, "issues": []},
            "overall_score": 0,
            "recommendations": ["HTMLの解析に失敗しました。構文エラーをチェックしてください。"]
        }


def _validate_basic_structure(soup: BeautifulSoup, html_content: str) -> Dict[str, Any]:
    """基本的なHTML構造を検証"""
    errors = []
    warnings = []
    
    # DOCTYPE宣言のチェック
    if not html_content.strip().upper().startswith('<!DOCTYPE'):
        errors.append("DOCTYPE宣言が見つかりません")
    
    # html要素のチェック
    if not soup.find('html'):
        errors.append("html要素が見つかりません")
    
    # head要素のチェック
    head = soup.find('head')
    if not head:
        errors.append("head要素が見つかりません")
    else:
        # title要素のチェック
        if not head.find('title'):
            errors.append("title要素が見つかりません")
        
        # meta charset のチェック
        if not head.find('meta', attrs={'charset': True}):
            warnings.append("文字エンコーディング指定が見つかりません")
    
    # body要素のチェック
    if not soup.find('body'):
        errors.append("body要素が見つかりません")
    
    # 見出し階層のチェック
    headings = soup.find_all(['h1', 'h2', 'h3', 'h4', 'h5', 'h6'])
    if headings:
        heading_levels = [int(h.name[1]) for h in headings]
        if heading_levels and heading_levels[0] != 1:
            warnings.append("最初の見出しがh1ではありません")
        
        # 見出しレベルの飛びをチェック
        for i in range(1, len(heading_levels)):
            if heading_levels[i] - heading_levels[i-1] > 1:
                warnings.append(f"見出しレベルが飛んでいます: h{heading_levels[i-1]} → h{heading_levels[i]}")
    
    return {
        "valid": len(errors) == 0,
        "errors": errors,
        "warnings": warnings,
        "elements_count": len(soup.find_all())
    }


def _validate_accessibility(soup: BeautifulSoup) -> Dict[str, Any]:
    """アクセシビリティを検証"""
    issues = []
    score = 100
    
    # img要素のalt属性チェック
    images = soup.find_all('img')
    for img in images:
        if not img.get('alt'):
            issues.append("alt属性のない画像があります")
            score -= 10
        elif img.get('alt').strip() == '':
            issues.append("空のalt属性を持つ画像があります")
            score -= 5
    
    # フォーム要素のラベルチェック
    inputs = soup.find_all('input')
    for inp in inputs:
        if inp.get('type') not in ['hidden', 'submit', 'button']:
            input_id = inp.get('id')
            if not input_id:
                issues.append("id属性のないinput要素があります")
                score -= 8
            else:
                # 対応するlabel要素をチェック
                label = soup.find('label', attrs={'for': input_id})
                if not label:
                    # input要素を包むlabel要素をチェック
                    parent_label = inp.find_parent('label')
                    if not parent_label:
                        issues.append(f"ラベルのないinput要素があります（id: {input_id}）")
                        score -= 8
    
    # 色コントラストの基本チェック（CSSスタイルから）
    style_tags = soup.find_all('style')
    for style in style_tags:
        if style.string:
            # 背景色と文字色の組み合わせを大まかにチェック
            if 'background' in style.string and 'color' in style.string:
                if '#fff' in style.string and '#000' not in style.string:
                    issues.append("色コントラストが不十分な可能性があります")
                    score -= 5
    
    # リンクのテキスト内容チェック
    links = soup.find_all('a')
    for link in links:
        link_text = link.get_text().strip()
        if not link_text:
            issues.append("テキストのないリンクがあります")
            score -= 10
        elif link_text.lower() in ['click here', 'here', 'more', 'こちら', 'もっと見る']:
            issues.append("リンクテキストが不明確です")
            score -= 3
    
    # tableのキャプションとヘッダーチェック
    tables = soup.find_all('table')
    for table in tables:
        if not table.find('caption'):
            issues.append("キャプションのないテーブルがあります")
            score -= 5
        
        if not table.find('th'):
            issues.append("ヘッダーセルのないテーブルがあります")
            score -= 8
    
    return {
        "score": max(0, score),
        "issues": issues,
        "images_without_alt": len([img for img in images if not img.get('alt')]),
        "total_images": len(images)
    }


def _validate_performance(soup: BeautifulSoup, html_content: str) -> Dict[str, Any]:
    """パフォーマンスを検証"""
    issues = []
    score = 100
    
    # HTMLサイズチェック
    html_size_kb = len(html_content.encode('utf-8')) / 1024
    if html_size_kb > 100:
        issues.append(f"HTMLサイズが大きすぎます（{html_size_kb:.1f}KB）")
        score -= 15
    elif html_size_kb > 50:
        issues.append(f"HTMLサイズがやや大きいです（{html_size_kb:.1f}KB）")
        score -= 5
    
    # CSSの最適化チェック
    style_tags = soup.find_all('style')
    total_css_length = sum(len(style.get_text()) for style in style_tags)
    if total_css_length > 10000:
        issues.append("CSSコードが長すぎます")
        score -= 10
    
    # インラインスタイルの使用チェック
    inline_style_elements = soup.find_all(attrs={'style': True})
    if len(inline_style_elements) > 5:
        issues.append("インラインスタイルが多用されています")
        score -= 8
    
    # 不要なネストのチェック
    deeply_nested = soup.find_all(lambda tag: len(list(tag.parents)) > 10)
    if deeply_nested:
        issues.append("深くネストされた要素があります")
        score -= 5
    
    # 画像の最適化チェック
    images = soup.find_all('img')
    for img in images:
        src = img.get('src', '')
        if src and not src.startswith('data:'):
            # 画像形式のチェック
            if not any(ext in src.lower() for ext in ['.webp', '.jpg', '.jpeg', '.png', '.svg']):
                issues.append("最適化されていない画像形式の可能性があります")
                score -= 3
    
    # 不要な空白の除去チェック
    if re.search(r'\s{3,}', html_content):
        issues.append("不要な空白が含まれています")
        score -= 3
    
    return {
        "score": max(0, score),
        "issues": issues,
        "html_size_kb": round(html_size_kb, 1),
        "css_length": total_css_length,
        "inline_styles_count": len(inline_style_elements)
    }


def _validate_seo(soup: BeautifulSoup) -> Dict[str, Any]:
    """SEO要素を検証"""
    issues = []
    score = 100
    
    # title要素の内容チェック
    title = soup.find('title')
    if title:
        title_text = title.get_text().strip()
        if len(title_text) < 10:
            issues.append("タイトルが短すぎます")
            score -= 10
        elif len(title_text) > 60:
            issues.append("タイトルが長すぎます")
            score -= 5
    
    # meta description チェック
    meta_desc = soup.find('meta', attrs={'name': 'description'})
    if not meta_desc:
        issues.append("meta description が見つかりません")
        score -= 15
    else:
        desc_content = meta_desc.get('content', '')
        if len(desc_content) < 50:
            issues.append("meta description が短すぎます")
            score -= 8
        elif len(desc_content) > 160:
            issues.append("meta description が長すぎます")
            score -= 5
    
    # 見出し構造のチェック
    h1_tags = soup.find_all('h1')
    if len(h1_tags) == 0:
        issues.append("h1タグが見つかりません")
        score -= 20
    elif len(h1_tags) > 1:
        issues.append("複数のh1タグがあります")
        score -= 10
    
    # 画像のSEO対応チェック
    images = soup.find_all('img')
    for img in images:
        if img.get('alt') and len(img.get('alt')) > 100:
            issues.append("alt属性が長すぎる画像があります")
            score -= 3
    
    return {
        "score": max(0, score),
        "issues": issues,
        "title_length": len(title.get_text()) if title else 0,
        "has_meta_description": meta_desc is not None,
        "h1_count": len(h1_tags)
    }


def _validate_printing_compatibility(soup: BeautifulSoup) -> Dict[str, Any]:
    """印刷互換性を検証"""
    issues = []
    score = 100
    
    # 印刷用CSSの存在チェック
    has_print_css = False
    style_tags = soup.find_all('style')
    for style in style_tags:
        if style.string and '@media print' in style.string:
            has_print_css = True
            break
    
    if not has_print_css:
        # link要素での印刷用CSSチェック
        link_tags = soup.find_all('link', rel='stylesheet')
        for link in link_tags:
            if link.get('media') == 'print':
                has_print_css = True
                break
    
    if not has_print_css:
        issues.append("印刷用CSSが指定されていません")
        score -= 15
    
    # 印刷に適さない要素のチェック
    problematic_elements = soup.find_all(['video', 'audio', 'iframe'])
    if problematic_elements:
        issues.append("印刷に適さないメディア要素が含まれています")
        score -= 10
    
    # 固定幅の要素チェック
    style_tags = soup.find_all('style')
    for style in style_tags:
        if style.string:
            # px単位での固定サイズ指定をチェック
            if re.search(r'width:\s*\d+px', style.string):
                issues.append("固定幅（px）指定があります（印刷時に問題となる可能性）")
                score -= 5
                break
    
    # 色に依存する情報のチェック
    color_dependent_elements = soup.find_all(attrs={'style': re.compile(r'color|background')})
    if len(color_dependent_elements) > 3:
        issues.append("色に依存する要素が多く含まれています")
        score -= 8
    
    return {
        "score": max(0, score),
        "issues": issues,
        "has_print_css": has_print_css,
        "media_elements_count": len(problematic_elements)
    }


def _calculate_overall_score(validation_results: Dict[str, Any]) -> int:
    """全体スコアを計算"""
    scores = []
    
    # 構造の重要度は高い
    if validation_results["structure"]["valid"]:
        scores.append(100)
    else:
        scores.append(50)  # 構造エラーがある場合は大幅減点
    
    # 各カテゴリのスコアを重み付きで加算
    weights = {
        "accessibility": 0.3,
        "performance": 0.25,
        "seo": 0.2,
        "printing": 0.15
    }
    
    for category, weight in weights.items():
        if category in validation_results:
            scores.append(validation_results[category]["score"] * weight)
    
    return int(sum(scores) / len(scores))


def _compile_recommendations(validation_results: Dict[str, Any]) -> List[str]:
    """推奨事項をまとめる"""
    recommendations = []
    
    # 構造的な問題
    if validation_results["structure"]["errors"]:
        recommendations.append("HTMLの基本構造を修正してください")
    
    # アクセシビリティ
    if validation_results["accessibility"]["score"] < 80:
        recommendations.append("アクセシビリティの改善（alt属性、ラベル等）を行なってください")
    
    # パフォーマンス
    if validation_results["performance"]["score"] < 80:
        recommendations.append("パフォーマンスの最適化（ファイルサイズ、CSS効率化）を検討してください")
    
    # SEO
    if validation_results["seo"]["score"] < 80:
        recommendations.append("SEO対策（タイトル、メタディスクリプション）を改善してください")
    
    # 印刷対応
    if validation_results["printing"]["score"] < 70:
        recommendations.append("印刷対応（印刷用CSS、メディアクエリ）を追加してください")
    
    return recommendations


def generate_validation_report(html_content: str) -> str:
    """HTML検証レポートを生成し、JSON文字列として返します。"""
    try:
        validation_results = validate_html_structure(html_content)
        
        # レポート形式に整形
        report = {
            "validation_timestamp": "現在の日時",
            "overall_assessment": {
                "score": validation_results["overall_score"],
                "grade": _get_grade(validation_results["overall_score"]),
                "summary": _generate_summary(validation_results)
            },
            "detailed_results": validation_results,
            "priority_actions": _get_priority_actions(validation_results),
            "compliance_status": {
                "wcag_aa": validation_results["accessibility"]["score"] >= 80,
                "print_ready": validation_results["printing"]["score"] >= 70,
                "seo_optimized": validation_results["seo"]["score"] >= 80,
                "performance_optimized": validation_results["performance"]["score"] >= 80
            }
        }
        
        return json.dumps(report, ensure_ascii=False, indent=2)
        
    except Exception as e:
        logger.error(f"Error generating validation report: {e}", exc_info=True)
        return json.dumps({
            "error": "検証レポートの生成に失敗しました",
            "details": str(e)
        }, ensure_ascii=False, indent=2)


def _get_grade(score: int) -> str:
    """スコアに基づいてグレードを返す"""
    if score >= 90:
        return "A（優秀）"
    elif score >= 80:
        return "B（良好）"
    elif score >= 70:
        return "C（普通）"
    elif score >= 60:
        return "D（要改善）"
    else:
        return "F（要大幅改善）"


def _generate_summary(validation_results: Dict[str, Any]) -> str:
    """検証結果のサマリーを生成"""
    score = validation_results["overall_score"]
    issues_count = sum([
        len(validation_results["accessibility"]["issues"]),
        len(validation_results["performance"]["issues"]),
        len(validation_results["seo"]["issues"]),
        len(validation_results["printing"]["issues"])
    ])
    
    if score >= 90:
        return f"HTMLの品質は非常に優秀です。{issues_count}個の軽微な改善点があります。"
    elif score >= 80:
        return f"HTMLの品質は良好です。{issues_count}個の改善点があります。"
    elif score >= 70:
        return f"HTMLの品質は普通です。{issues_count}個の改善点を対応することを推奨します。"
    elif score >= 60:
        return f"HTMLの品質に改善が必要です。{issues_count}個の問題を解決してください。"
    else:
        return f"HTMLの品質に大幅な改善が必要です。{issues_count}個の重要な問題があります。"


def _get_priority_actions(validation_results: Dict[str, Any]) -> List[str]:
    """優先度の高いアクションを抽出"""
    actions = []
    
    # 構造エラーは最優先
    if validation_results["structure"]["errors"]:
        actions.extend([f"【緊急】{error}" for error in validation_results["structure"]["errors"]])
    
    # アクセシビリティの重要な問題
    if validation_results["accessibility"]["score"] < 60:
        actions.append("【高】アクセシビリティの重要な問題を修正")
    
    # パフォーマンスの問題
    if validation_results["performance"]["html_size_kb"] > 100:
        actions.append("【高】HTMLファイルサイズの削減")
    
    # SEOの基本的な問題
    if validation_results["seo"]["h1_count"] == 0:
        actions.append("【高】h1タグの追加")
    
    if not validation_results["seo"]["has_meta_description"]:
        actions.append("【中】meta descriptionの追加")
    
    return actions[:5]  # 最大5つまで