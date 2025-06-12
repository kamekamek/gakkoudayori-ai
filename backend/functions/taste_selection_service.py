"""
テイスト選択サービス

学級通信のスタイル・テイスト管理
"""

import os
import logging
from typing import Dict, List, Optional, Any
from dataclasses import dataclass
from enum import Enum

# 設定
logger = logging.getLogger(__name__)

class TasteType(Enum):
    """テイストタイプ列挙"""
    MODERN = "modern"
    CLASSIC = "classic"
    MINIMAL = "minimal"
    COLORFUL = "colorful"

@dataclass
class TasteConfig:
    """テイスト設定データクラス"""
    taste_type: TasteType
    name: str
    description: str
    color_scheme: Dict[str, str]
    font_style: Dict[str, str]
    layout_style: Dict[str, str]
    prompt_modifiers: List[str]
    sample_html: str

class TasteSelectionService:
    """テイスト選択管理サービス"""
    
    def __init__(self):
        self.taste_configs = self._initialize_taste_configs()
    
    def get_available_tastes(self) -> List[Dict[str, Any]]:
        """
        利用可能なテイスト一覧を取得
        
        Returns:
            List[Dict[str, Any]]: テイスト情報リスト
        """
        tastes = []
        for taste_type, config in self.taste_configs.items():
            tastes.append({
                'type': taste_type.value,
                'name': config.name,
                'description': config.description,
                'color_scheme': config.color_scheme,
                'preview_html': self._generate_preview_html(config)
            })
        return tastes
    
    def get_taste_config(self, taste_type: str) -> Optional[TasteConfig]:
        """
        特定のテイスト設定を取得
        
        Args:
            taste_type (str): テイストタイプ
            
        Returns:
            Optional[TasteConfig]: テイスト設定
        """
        try:
            taste_enum = TasteType(taste_type)
            return self.taste_configs.get(taste_enum)
        except ValueError:
            return None
    
    def generate_taste_prompt(self, base_prompt: str, taste_type: str) -> str:
        """
        テイストに応じたプロンプトを生成
        
        Args:
            base_prompt (str): ベースプロンプト
            taste_type (str): テイストタイプ
            
        Returns:
            str: テイスト適用済みプロンプト
        """
        config = self.get_taste_config(taste_type)
        if not config:
            return base_prompt
        
        # テイスト指示を追加
        taste_instructions = "\n".join(config.prompt_modifiers)
        
        modified_prompt = f"""
{base_prompt}

【スタイル指示 - {config.name}】
{taste_instructions}

【色彩・デザイン指示】
- 主要色: {config.color_scheme.get('primary', '#333333')}
- アクセント色: {config.color_scheme.get('accent', '#007bff')}
- 背景色: {config.color_scheme.get('background', '#ffffff')}
- フォントスタイル: {config.font_style.get('family', 'sans-serif')}

【レイアウト指示】
- スタイル: {config.layout_style.get('style', 'standard')}
- 見出し装飾: {config.layout_style.get('heading_style', 'simple')}
- 段落間隔: {config.layout_style.get('paragraph_spacing', 'normal')}
"""
        
        return modified_prompt
    
    def apply_taste_css(self, html_content: str, taste_type: str) -> str:
        """
        HTMLにテイスト用CSSを適用
        
        Args:
            html_content (str): ベースHTML
            taste_type (str): テイストタイプ
            
        Returns:
            str: テイスト適用済みHTML
        """
        config = self.get_taste_config(taste_type)
        if not config:
            return html_content
        
        # CSSスタイル生成
        css_styles = self._generate_taste_css(config)
        
        # HTMLにスタイル埋め込み
        styled_html = f"""
<style>
{css_styles}
</style>

<div class="newsletter-{taste_type}">
{html_content}
</div>
"""
        
        return styled_html
    
    def _initialize_taste_configs(self) -> Dict[TasteType, TasteConfig]:
        """テイスト設定の初期化"""
        return {
            TasteType.MODERN: TasteConfig(
                taste_type=TasteType.MODERN,
                name="モダン",
                description="現代的でスタイリッシュなデザイン。明るい色調と読みやすいレイアウト",
                color_scheme={
                    'primary': '#2c3e50',
                    'accent': '#3498db',
                    'background': '#f8f9fa',
                    'text': '#2c3e50',
                    'highlight': '#e74c3c'
                },
                font_style={
                    'family': 'system-ui, -apple-system, sans-serif',
                    'size': '16px',
                    'weight': 'normal'
                },
                layout_style={
                    'style': 'card-based',
                    'heading_style': 'gradient-underline',
                    'paragraph_spacing': 'wide',
                    'border_radius': '8px'
                },
                prompt_modifiers=[
                    "カジュアルで親しみやすい文体を使用",
                    "絵文字や記号を適度に使用",
                    "短めの段落で読みやすく構成",
                    "現代的な表現と言葉遣いを採用"
                ],
                sample_html="<h1>🌟 今日の学級活動</h1><p>みなさん、こんにちは！</p>"
            ),
            
            TasteType.CLASSIC: TasteConfig(
                taste_type=TasteType.CLASSIC,
                name="クラシック",
                description="伝統的で格式のあるデザイン。落ち着いた色調と整った文章",
                color_scheme={
                    'primary': '#1a237e',
                    'accent': '#3949ab',
                    'background': '#ffffff',
                    'text': '#212121',
                    'highlight': '#c62828'
                },
                font_style={
                    'family': '"Times New Roman", "YuMincho", "MS Mincho", serif',
                    'size': '15px',
                    'weight': 'normal'
                },
                layout_style={
                    'style': 'formal',
                    'heading_style': 'traditional-border',
                    'paragraph_spacing': 'normal',
                    'border_style': 'solid'
                },
                prompt_modifiers=[
                    "丁寧で格式のある文体を使用",
                    "敬語を適切に使用",
                    "段落を明確に分けて論理的に構成",
                    "伝統的な表現と慣用句を採用"
                ],
                sample_html="<h1>学級通信</h1><p>保護者の皆様におかれましては、ますますご清栄のこととお慶び申し上げます。</p>"
            ),
            
            TasteType.MINIMAL: TasteConfig(
                taste_type=TasteType.MINIMAL,
                name="ミニマル",
                description="シンプルで無駄のないデザイン。白を基調とした清潔感",
                color_scheme={
                    'primary': '#424242',
                    'accent': '#757575',
                    'background': '#ffffff',
                    'text': '#212121',
                    'highlight': '#9e9e9e'
                },
                font_style={
                    'family': '"Helvetica Neue", Arial, sans-serif',
                    'size': '15px',
                    'weight': '300'
                },
                layout_style={
                    'style': 'minimal',
                    'heading_style': 'simple-line',
                    'paragraph_spacing': 'tight',
                    'border_style': 'none'
                },
                prompt_modifiers=[
                    "簡潔で要点を押さえた文体",
                    "装飾的な表現は控えめに",
                    "情報を整理して見やすく配置",
                    "無駄のない効率的な構成"
                ],
                sample_html="<h1>学級通信</h1><p>今日の活動についてお知らせします。</p>"
            ),
            
            TasteType.COLORFUL: TasteConfig(
                taste_type=TasteType.COLORFUL,
                name="カラフル",
                description="明るく楽しいデザイン。子どもらしい色使いと親しみやすさ",
                color_scheme={
                    'primary': '#ff6b6b',
                    'accent': '#4ecdc4',
                    'background': '#fffef7',
                    'text': '#2d3436',
                    'highlight': '#fdcb6e'
                },
                font_style={
                    'family': '"Comic Sans MS", "Kosugi Maru", cursive',
                    'size': '16px',
                    'weight': 'normal'
                },
                layout_style={
                    'style': 'playful',
                    'heading_style': 'colorful-background',
                    'paragraph_spacing': 'wide',
                    'border_radius': '15px'
                },
                prompt_modifiers=[
                    "楽しく活気のある文体を使用",
                    "絵文字や記号を積極的に使用",
                    "子どもたちの活動を生き生きと描写",
                    "ポジティブで明るい表現を採用"
                ],
                sample_html="<h1>🌈 楽しい学級通信 🎈</h1><p>みんな〜！今日も元気いっぱいでした✨</p>"
            )
        }
    
    def _generate_taste_css(self, config: TasteConfig) -> str:
        """テイスト用CSS生成"""
        taste_class = f"newsletter-{config.taste_type.value}"
        
        return f"""
.{taste_class} {{
    font-family: {config.font_style['family']};
    font-size: {config.font_style['size']};
    font-weight: {config.font_style['weight']};
    color: {config.color_scheme['text']};
    background-color: {config.color_scheme['background']};
    line-height: 1.6;
    padding: 20px;
    max-width: 800px;
    margin: 0 auto;
}}

.{taste_class} h1 {{
    color: {config.color_scheme['primary']};
    font-size: 28px;
    margin-bottom: 20px;
    {self._get_heading_style(config, 1)}
}}

.{taste_class} h2 {{
    color: {config.color_scheme['primary']};
    font-size: 22px;
    margin: 25px 0 15px 0;
    {self._get_heading_style(config, 2)}
}}

.{taste_class} h3 {{
    color: {config.color_scheme['accent']};
    font-size: 18px;
    margin: 20px 0 10px 0;
    {self._get_heading_style(config, 3)}
}}

.{taste_class} p {{
    margin-bottom: {self._get_paragraph_spacing(config)};
    text-align: justify;
}}

.{taste_class} strong {{
    color: {config.color_scheme['highlight']};
    font-weight: bold;
}}

.{taste_class} em {{
    color: {config.color_scheme['accent']};
    font-style: italic;
}}

.{taste_class} ul, .{taste_class} ol {{
    margin: 15px 0;
    padding-left: 25px;
}}

.{taste_class} li {{
    margin-bottom: 8px;
}}
"""
    
    def _get_heading_style(self, config: TasteConfig, level: int) -> str:
        """見出しスタイル生成"""
        style_type = config.layout_style.get('heading_style', 'simple')
        
        if style_type == 'gradient-underline':
            return f"border-bottom: 3px solid {config.color_scheme['accent']}; padding-bottom: 8px;"
        elif style_type == 'traditional-border':
            return f"border-bottom: 2px solid {config.color_scheme['primary']}; border-top: 1px solid {config.color_scheme['primary']}; padding: 10px 0;"
        elif style_type == 'simple-line':
            return f"border-bottom: 1px solid {config.color_scheme['accent']}; padding-bottom: 5px;"
        elif style_type == 'colorful-background':
            return f"background: linear-gradient(45deg, {config.color_scheme['primary']}, {config.color_scheme['accent']}); color: white; padding: 10px; border-radius: 8px;"
        else:
            return ""
    
    def _get_paragraph_spacing(self, config: TasteConfig) -> str:
        """段落間隔取得"""
        spacing = config.layout_style.get('paragraph_spacing', 'normal')
        
        if spacing == 'wide':
            return '18px'
        elif spacing == 'tight':
            return '8px'
        else:
            return '12px'
    
    def _generate_preview_html(self, config: TasteConfig) -> str:
        """プレビュー用HTML生成"""
        return f"""
<div class="taste-preview" style="font-family: {config.font_style['family']}; 
     color: {config.color_scheme['text']}; background: {config.color_scheme['background']}; 
     padding: 15px; border-radius: 8px; border: 1px solid #ddd;">
    <h3 style="color: {config.color_scheme['primary']}; margin-top: 0;">
        {config.name}スタイル
    </h3>
    <p style="margin: 10px 0;">{config.description}</p>
    <div style="font-size: 12px; color: {config.color_scheme['accent']};">
        {config.sample_html}
    </div>
</div>
"""

# ==============================================================================
# ユーティリティ関数
# ==============================================================================

def create_taste_service() -> TasteSelectionService:
    """テイスト選択サービスのファクトリ関数"""
    return TasteSelectionService()

def test_taste_selection_service():
    """テイスト選択サービステスト"""
    print("=== テイスト選択サービステスト ===")
    
    service = TasteSelectionService()
    
    # 1. 利用可能テイスト一覧
    print("\n1. 利用可能テイスト一覧...")
    tastes = service.get_available_tastes()
    for taste in tastes:
        print(f"   - {taste['name']}: {taste['description']}")
    
    # 2. テイストプロンプト生成
    print("\n2. テイストプロンプト生成...")
    base_prompt = "今日は運動会の練習をしました。"
    modern_prompt = service.generate_taste_prompt(base_prompt, "modern")
    print(f"   モダンプロンプト: {modern_prompt[:100]}...")
    
    # 3. CSS適用テスト
    print("\n3. CSS適用テスト...")
    base_html = "<h1>学級通信</h1><p>テスト内容</p>"
    styled_html = service.apply_taste_css(base_html, "colorful")
    print(f"   スタイル適用済みHTML長: {len(styled_html)} 文字")
    
    print("\n✅ テイスト選択サービステスト完了")

if __name__ == '__main__':
    test_taste_selection_service() 