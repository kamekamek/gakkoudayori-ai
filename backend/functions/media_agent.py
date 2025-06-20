"""
メディアエージェント - ADKマルチエージェントシステム統合

Vertex AI Imagen統合による画像生成・挿入・最適化を専門化するエージェント
学級通信の視覚的魅力向上と教育効果最大化を実現
"""

import asyncio
import json
import logging
import os
import tempfile
import time
import base64
import re
from typing import Dict, Any, List, Optional, Tuple
from datetime import datetime
from pathlib import Path
import requests
from urllib.parse import urlparse

# Google ADK imports
try:
    from google.adk.agents import LlmAgent, Agent
    from google.adk.tools import google_search
    from google.adk.orchestration import Sequential, Parallel
    ADK_AVAILABLE = True
except ImportError:
    ADK_AVAILABLE = False
    logging.warning("Google ADK not available, using fallback implementation")

# Google Cloud / Vertex AI imports
try:
    from google.cloud import storage
    from google.cloud import aiplatform
    from vertexai.preview.vision_models import ImageGenerationModel
    VERTEX_AI_AVAILABLE = True
except ImportError:
    VERTEX_AI_AVAILABLE = False
    logging.warning("Vertex AI not available, image generation disabled")

# 画像処理
try:
    from PIL import Image, ImageEnhance, ImageFilter
    import io
    PIL_AVAILABLE = True
except ImportError:
    PIL_AVAILABLE = False
    logging.warning("PIL not available, image processing limited")

# 既存サービス
from gemini_api_service import generate_text

logger = logging.getLogger(__name__)


# ==============================================================================
# 画像生成・処理ツール定義
# ==============================================================================

def analyze_content_for_images(
    content: str,
    sections: List[Dict[str, Any]]
) -> List[Dict[str, Any]]:
    """コンテンツを分析して適切な画像挿入位置とプロンプトを提案するツール"""
    
    image_suggestions = []
    
    try:
        # セクション別に画像の必要性を分析
        for i, section in enumerate(sections):
            section_type = section.get("type", "main")
            section_content = section.get("content", "")
            section_title = section.get("title", "")
            
            # 画像が効果的なセクションタイプ
            image_effective_types = ["main", "event", "announcement"]
            
            if section_type in image_effective_types and len(section_content) > 100:
                
                # コンテンツから画像プロンプトを生成
                image_prompt = _generate_image_prompt_from_content(
                    section_content, 
                    section_title,
                    section_type
                )
                
                if image_prompt:
                    suggestion = {
                        "section_index": i,
                        "section_type": section_type,
                        "section_title": section_title,
                        "insertion_point": "end_of_section",
                        "image_prompt": image_prompt,
                        "image_style": _determine_image_style(section_content),
                        "priority": _calculate_image_priority(section_content, section_type),
                        "caption_suggestion": _generate_caption_suggestion(section_content)
                    }
                    
                    image_suggestions.append(suggestion)
        
        # 優先度順にソート
        image_suggestions.sort(key=lambda x: x["priority"], reverse=True)
        
        # 最大3つの画像に制限（学級通信の適切な画像数）
        return image_suggestions[:3]
        
    except Exception as e:
        logger.error(f"画像分析エラー: {e}")
        return []


def _generate_image_prompt_from_content(content: str, title: str, section_type: str) -> str:
    """コンテンツから画像生成プロンプトを作成"""
    
    # 教育関連キーワードの検出
    education_keywords = {
        "運動会": "school sports day, children running and playing",
        "算数": "children learning mathematics, classroom setting",
        "国語": "children reading books, Japanese classroom",
        "理科": "science experiment, children observing",
        "図工": "art class, children creating artwork",
        "音楽": "music class, children singing",
        "給食": "school lunch, children eating together",
        "掃除": "children cleaning classroom",
        "休み時間": "children playing during break time",
        "遠足": "school trip, children walking outdoors"
    }
    
    # キーワードマッチング
    for keyword, prompt_base in education_keywords.items():
        if keyword in content:
            return f"Educational illustration: {prompt_base}, warm and friendly style, suitable for elementary school newsletter, bright colors, cartoon style"
    
    # 一般的な学校活動のプロンプト
    if section_type == "event":
        return "Educational illustration: school event scene, happy children participating, warm and inviting atmosphere, suitable for elementary school newsletter"
    elif section_type == "announcement":
        return "Educational illustration: school announcement scene, clear and informative style, suitable for elementary school newsletter"
    else:
        return "Educational illustration: classroom scene with children learning, warm and friendly atmosphere, suitable for elementary school newsletter"


def _determine_image_style(content: str) -> str:
    """コンテンツに基づいて画像スタイルを決定"""
    
    if any(word in content for word in ["運動", "体育", "スポーツ"]):
        return "active_sports"
    elif any(word in content for word in ["音楽", "歌", "演奏"]):
        return "musical"
    elif any(word in content for word in ["図工", "絵", "工作"]):
        return "artistic"
    elif any(word in content for word in ["読書", "本", "国語"]):
        return "academic"
    else:
        return "general_classroom"


def _calculate_image_priority(content: str, section_type: str) -> int:
    """画像の優先度を計算"""
    
    priority = 50  # ベース優先度
    
    # セクションタイプによる優先度調整
    if section_type == "main":
        priority += 20
    elif section_type == "event":
        priority += 15
    elif section_type == "announcement":
        priority += 10
    
    # コンテンツ長による調整
    if len(content) > 200:
        priority += 15
    elif len(content) > 100:
        priority += 10
    
    # 視覚的効果の高いキーワード
    visual_keywords = ["運動会", "発表", "作品", "活動", "イベント", "行事"]
    for keyword in visual_keywords:
        if keyword in content:
            priority += 5
    
    return min(priority, 100)  # 最大100


def _generate_caption_suggestion(content: str) -> str:
    """画像キャプションの提案生成"""
    
    # コンテンツから主要な活動を抽出
    sentences = content.split("。")
    if sentences:
        # 最初の文から動詞を抽出してキャプション案を作成
        first_sentence = sentences[0].strip()
        return f"{first_sentence[:30]}の様子" if len(first_sentence) > 30 else f"{first_sentence}の様子"
    
    return "学級活動の様子"


def generate_image_with_vertex_ai(
    prompt: str,
    style: str = "cartoon",
    aspect_ratio: str = "1:1",
    safety_level: str = "block_few"
) -> Dict[str, Any]:
    """Vertex AI Imageを使用した画像生成ツール"""
    
    start_time = time.time()
    
    try:
        if not VERTEX_AI_AVAILABLE:
            return {
                "success": False,
                "error": "Vertex AI not available",
                "error_code": "VERTEX_AI_NOT_AVAILABLE"
            }
        
        # Vertex AI初期化
        aiplatform.init(project="your-project-id", location="us-central1")
        
        # 画像生成モデル取得
        model = ImageGenerationModel.from_pretrained("imagegeneration@005")
        
        # スタイル調整されたプロンプト
        enhanced_prompt = _enhance_prompt_for_education(prompt, style)
        
        # 画像生成
        response = model.generate_images(
            prompt=enhanced_prompt,
            number_of_images=1,
            aspect_ratio=aspect_ratio,
            safety_filter_level=safety_level,
            person_generation="allow_adult"  # 教師の描画を許可
        )
        
        if not response.images:
            return {
                "success": False,
                "error": "No images generated",
                "error_code": "NO_IMAGES_GENERATED"
            }
        
        image = response.images[0]
        
        # 画像データをBase64エンコード
        image_bytes = image._image_bytes
        image_base64 = base64.b64encode(image_bytes).decode('utf-8')
        
        # 一時ファイルに保存
        temp_file = tempfile.NamedTemporaryFile(delete=False, suffix='.png')
        temp_file.write(image_bytes)
        temp_file.close()
        
        # 画像サイズ情報取得
        if PIL_AVAILABLE:
            with Image.open(io.BytesIO(image_bytes)) as img:
                width, height = img.size
        else:
            width, height = 1024, 1024  # デフォルト値
        
        processing_time = time.time() - start_time
        
        return {
            "success": True,
            "data": {
                "image_path": temp_file.name,
                "image_base64": image_base64,
                "width": width,
                "height": height,
                "file_size_bytes": len(image_bytes),
                "prompt_used": enhanced_prompt,
                "style": style,
                "aspect_ratio": aspect_ratio,
                "processing_time_ms": int(processing_time * 1000),
                "generated_at": datetime.now().isoformat()
            }
        }
        
    except Exception as e:
        error_msg = f"Vertex AI画像生成エラー: {str(e)}"
        logger.error(error_msg)
        return {
            "success": False,
            "error": error_msg,
            "error_code": "VERTEX_AI_ERROR",
            "processing_time_ms": int((time.time() - start_time) * 1000)
        }


def _enhance_prompt_for_education(prompt: str, style: str) -> str:
    """教育向けプロンプトの強化"""
    
    # 基本的な教育コンテンツ向けの修飾子
    education_modifiers = [
        "safe for children",
        "educational content",
        "positive atmosphere",
        "inclusive representation",
        "bright and cheerful"
    ]
    
    # スタイル別の調整
    style_modifiers = {
        "cartoon": "cute cartoon style, child-friendly illustration",
        "realistic": "warm realistic style, professional photography look",
        "artistic": "colorful artistic style, creative illustration",
        "simple": "simple and clear illustration, minimalist design"
    }
    
    # プロンプト強化
    enhanced = f"{prompt}, {style_modifiers.get(style, style_modifiers['cartoon'])}"
    enhanced += f", {', '.join(education_modifiers)}"
    
    return enhanced


def optimize_image_for_newsletter(
    image_path: str,
    target_width: int = 400,
    quality: int = 85,
    format: str = "JPEG"
) -> Dict[str, Any]:
    """学級通信向けに画像を最適化するツール"""
    
    start_time = time.time()
    
    try:
        if not PIL_AVAILABLE:
            return {
                "success": False,
                "error": "PIL not available for image optimization",
                "error_code": "PIL_NOT_AVAILABLE"
            }
        
        # 画像読み込み
        with Image.open(image_path) as img:
            
            # RGBA画像をRGBに変換（JPEG対応）
            if img.mode == 'RGBA' and format.upper() == 'JPEG':
                # 白い背景に合成
                rgb_img = Image.new('RGB', img.size, (255, 255, 255))
                rgb_img.paste(img, mask=img.split()[-1])  # アルファチャンネルをマスクとして使用
                img = rgb_img
            
            # リサイズ（アスペクト比保持）
            original_width, original_height = img.size
            
            if original_width > target_width:
                aspect_ratio = original_height / original_width
                new_height = int(target_width * aspect_ratio)
                img = img.resize((target_width, new_height), Image.Resampling.LANCZOS)
            
            # 画質向上フィルタ適用
            img = img.filter(ImageFilter.SMOOTH_MORE)
            
            # 色彩強化（学級通信向けに明るく）
            enhancer = ImageEnhance.Color(img)
            img = enhancer.enhance(1.1)  # 色彩を10%強化
            
            enhancer = ImageEnhance.Brightness(img)
            img = enhancer.enhance(1.05)  # 明度を5%向上
            
            # 最適化後の画像を保存
            optimized_path = image_path.replace('.png', f'_optimized.{format.lower()}')
            
            save_kwargs = {'format': format, 'optimize': True}
            if format.upper() == 'JPEG':
                save_kwargs['quality'] = quality
                save_kwargs['progressive'] = True
            
            img.save(optimized_path, **save_kwargs)
            
            # 画像をBase64エンコード
            with open(optimized_path, 'rb') as img_file:
                image_base64 = base64.b64encode(img_file.read()).decode('utf-8')
            
            # ファイルサイズ取得
            file_size = os.path.getsize(optimized_path)
            
            processing_time = time.time() - start_time
            
            return {
                "success": True,
                "data": {
                    "optimized_path": optimized_path,
                    "image_base64": image_base64,
                    "width": img.width,
                    "height": img.height,
                    "file_size_bytes": file_size,
                    "file_size_kb": round(file_size / 1024, 2),
                    "format": format,
                    "quality": quality,
                    "compression_ratio": round(file_size / os.path.getsize(image_path), 2),
                    "processing_time_ms": int(processing_time * 1000)
                }
            }
            
    except Exception as e:
        error_msg = f"画像最適化エラー: {str(e)}"
        logger.error(error_msg)
        return {
            "success": False,
            "error": error_msg,
            "error_code": "IMAGE_OPTIMIZATION_ERROR",
            "processing_time_ms": int((time.time() - start_time) * 1000)
        }


def insert_images_into_html(
    html_content: str,
    image_data_list: List[Dict[str, Any]],
    layout_style: str = "responsive"
) -> str:
    """HTMLに画像を挿入するツール"""
    
    try:
        modified_html = html_content
        
        for image_data in image_data_list:
            section_index = image_data.get("section_index", 0)
            image_base64 = image_data.get("image_base64", "")
            caption = image_data.get("caption", "")
            insertion_point = image_data.get("insertion_point", "end_of_section")
            width = image_data.get("width", 400)
            height = image_data.get("height", 300)
            
            if not image_base64:
                continue
            
            # 画像HTMLの生成
            image_html = _generate_image_html(
                image_base64=image_base64,
                caption=caption,
                width=width,
                height=height,
                layout_style=layout_style
            )
            
            # セクション別の挿入処理
            if insertion_point == "end_of_section":
                modified_html = _insert_at_section_end(
                    modified_html, 
                    section_index, 
                    image_html
                )
            elif insertion_point == "beginning_of_section":
                modified_html = _insert_at_section_beginning(
                    modified_html,
                    section_index,
                    image_html
                )
        
        return modified_html
        
    except Exception as e:
        logger.error(f"HTML画像挿入エラー: {e}")
        return html_content  # エラー時は元のHTMLを返す


def _generate_image_html(
    image_base64: str,
    caption: str,
    width: int,
    height: int,
    layout_style: str
) -> str:
    """画像HTML要素の生成"""
    
    # Base64データURL形式
    data_url = f"data:image/jpeg;base64,{image_base64}"
    
    # レスポンシブ画像スタイル（学級通信用）
    if layout_style == "responsive":
        image_html = f'''
        <div class="newsletter-image" style="text-align: center; margin: 15px 0; padding: 10px;">
            <img src="{data_url}" 
                 alt="{caption}" 
                 style="max-width: 100%; height: auto; border-radius: 8px; 
                        box-shadow: 0 2px 8px rgba(0,0,0,0.15); max-height: 300px;" />
            <p style="font-size: 11px; color: #666; margin: 8px 0 0 0; 
                     font-style: italic; text-align: center;">{caption}</p>
        </div>
        '''
    elif layout_style == "inline":
        image_html = f'''
        <img src="{data_url}" alt="{caption}" 
             style="float: right; margin: 0 0 10px 15px; max-width: 200px; 
                    height: auto; border-radius: 5px;" />
        '''
    else:  # block
        image_html = f'''
        <div style="margin: 10px 0; text-align: center;">
            <img src="{data_url}" alt="{caption}" 
                 style="max-width: 400px; height: auto; border-radius: 5px;" />
            <div style="font-size: 10px; color: #777; margin-top: 5px;">{caption}</div>
        </div>
        '''
    
    return image_html


def _insert_at_section_end(html_content: str, section_index: int, image_html: str) -> str:
    """セクション末尾に画像を挿入"""
    
    # h2, h3タグでセクションを特定
    section_pattern = r'(<h[23][^>]*>.*?</h[23]>.*?)(?=<h[23]|$)'
    sections = re.findall(section_pattern, html_content, re.DOTALL)
    
    if section_index < len(sections):
        original_section = sections[section_index]
        modified_section = original_section + image_html
        html_content = html_content.replace(original_section, modified_section, 1)
    
    return html_content


def _insert_at_section_beginning(html_content: str, section_index: int, image_html: str) -> str:
    """セクション開始部分に画像を挿入"""
    
    section_pattern = r'(<h[23][^>]*>.*?</h[23]>)(.*?)(?=<h[23]|$)'
    matches = re.finditer(section_pattern, html_content, re.DOTALL)
    
    for i, match in enumerate(matches):
        if i == section_index:
            header = match.group(1)
            content = match.group(2)
            modified_section = header + image_html + content
            html_content = html_content.replace(match.group(0), modified_section, 1)
            break
    
    return html_content


# ==============================================================================
# メディアエージェント本体
# ==============================================================================

class MediaAgent:
    """メディア生成・処理専門エージェント - ADK統合対応"""
    
    def __init__(self, project_id: str, credentials_path: str):
        self.project_id = project_id
        self.credentials_path = credentials_path
        self.agent = None
        
        if ADK_AVAILABLE:
            self._initialize_adk_agent()
        else:
            logger.warning("ADK not available for MediaAgent, using fallback mode")
    
    def _initialize_adk_agent(self):
        """ADKエージェントの初期化"""
        
        self.agent = LlmAgent(
            model="gemini-2.5-pro-preview-06-05",
            name="media_agent",
            description="学級通信の画像生成・挿入・最適化の専門エージェント",
            instruction="""
            あなたは学級通信のビジュアルコンテンツ専門家です。
            
            専門分野:
            - 教育コンテンツに適した画像生成
            - Vertex AI Imagen活用による高品質イラスト作成
            - 画像配置とレイアウト最適化
            - 学習効果を高めるビジュアル設計
            - 保護者にとって親しみやすい画像選択
            
            責任:
            - 教育的価値のある画像コンテンツ提供
            - 子供たちが安心して見られる安全な画像
            - 学級通信の視覚的魅力向上
            - 印刷・デジタル両方に適した画像最適化
            
            制約:
            - 教育現場に適したコンテンツのみ
            - 著作権フリーの生成画像使用
            - ファイルサイズ制限遵守
            - アクセシビリティ配慮（alt text必須）
            """,
            tools=[
                analyze_content_for_images,
                generate_image_with_vertex_ai,
                optimize_image_for_newsletter,
                insert_images_into_html
            ]
        )
    
    async def enhance_newsletter_with_media(
        self,
        html_content: str,
        newsletter_data: Dict[str, Any],
        options: Dict[str, Any] = None
    ) -> Dict[str, Any]:
        """学級通信のメディア強化 - ADK統合版"""
        
        start_time = time.time()
        logger.info("メディアエージェント: 学級通信メディア強化開始")
        
        try:
            # デフォルトオプション
            default_options = {
                "max_images": 3,
                "image_style": "cartoon",
                "auto_optimize": True,
                "layout_style": "responsive",
                "target_width": 400,
                "quality": 85,
                "generate_images": True
            }
            
            options = {**default_options, **(options or {})}
            
            # Step 1: コンテンツ分析による画像提案
            logger.info("メディアエージェント: コンテンツ分析実行")
            sections = newsletter_data.get("sections", [])
            
            image_suggestions = analyze_content_for_images(
                html_content,
                sections
            )
            
            if not image_suggestions:
                logger.info("メディアエージェント: 画像挿入の提案なし")
                return {
                    "success": True,
                    "data": {
                        "enhanced_html": html_content,
                        "images_added": 0,
                        "image_data": [],
                        "processing_notes": ["画像を挿入する適切な位置が見つかりませんでした"]
                    },
                    "metadata": {
                        "agent": "media_agent",
                        "processing_time_ms": int((time.time() - start_time) * 1000)
                    }
                }
            
            # 最大画像数制限
            max_images = min(options["max_images"], len(image_suggestions))
            selected_suggestions = image_suggestions[:max_images]
            
            logger.info(f"メディアエージェント: {len(selected_suggestions)}個の画像生成予定")
            
            # Step 2: 画像生成（並行処理）
            generated_images = []
            
            if options.get("generate_images", True):
                generation_tasks = []
                
                for suggestion in selected_suggestions:
                    task = self._generate_single_image(
                        suggestion,
                        options["image_style"],
                        options
                    )
                    generation_tasks.append(task)
                
                # 並行実行
                generation_results = await asyncio.gather(*generation_tasks, return_exceptions=True)
                
                # 結果処理
                for i, result in enumerate(generation_results):
                    if isinstance(result, Exception):
                        logger.error(f"画像生成エラー (#{i}): {result}")
                        continue
                    
                    if result["success"]:
                        # 画像最適化
                        if options.get("auto_optimize", True):
                            opt_result = optimize_image_for_newsletter(
                                result["data"]["image_path"],
                                target_width=options["target_width"],
                                quality=options["quality"]
                            )
                            
                            if opt_result["success"]:
                                result["data"].update(opt_result["data"])
                        
                        # メタデータ追加
                        result["data"]["suggestion"] = selected_suggestions[len(generated_images)]
                        result["data"]["caption"] = selected_suggestions[len(generated_images)]["caption_suggestion"]
                        
                        generated_images.append(result["data"])
                    else:
                        logger.warning(f"画像生成失敗: {result['error']}")
            
            logger.info(f"メディアエージェント: {len(generated_images)}個の画像生成完了")
            
            # Step 3: HTML への画像挿入
            enhanced_html = html_content
            
            if generated_images:
                logger.info("メディアエージェント: HTML画像挿入実行")
                
                # 画像データの準備
                image_data_for_html = []
                for img_data in generated_images:
                    suggestion = img_data["suggestion"]
                    image_data_for_html.append({
                        "section_index": suggestion["section_index"],
                        "image_base64": img_data["image_base64"],
                        "caption": img_data["caption"],
                        "insertion_point": suggestion["insertion_point"],
                        "width": img_data.get("width", 400),
                        "height": img_data.get("height", 300)
                    })
                
                enhanced_html = insert_images_into_html(
                    html_content,
                    image_data_for_html,
                    options["layout_style"]
                )
            
            # 処理時間計算
            processing_time = time.time() - start_time
            
            # 結果構築
            result = {
                "success": True,
                "data": {
                    "enhanced_html": enhanced_html,
                    "images_added": len(generated_images),
                    "image_data": generated_images,
                    "image_suggestions": image_suggestions,
                    "media_options": options,
                    "processing_notes": [
                        f"{len(generated_images)}個の画像を生成し、HTMLに挿入しました",
                        f"コンテンツ分析により{len(image_suggestions)}個の挿入候補を特定しました"
                    ]
                },
                "metadata": {
                    "agent": "media_agent",
                    "processing_time_ms": int(processing_time * 1000),
                    "generated_at": datetime.now().isoformat(),
                    "adk_enabled": ADK_AVAILABLE and self.agent is not None,
                    "vertex_ai_enabled": VERTEX_AI_AVAILABLE
                }
            }
            
            logger.info(f"メディアエージェント: 処理完了 ({processing_time:.2f}s)")
            return result
            
        except Exception as e:
            error_msg = f"メディアエージェント: 予期せぬエラー - {str(e)}"
            logger.error(error_msg)
            return {
                "success": False,
                "error": error_msg,
                "agent": "media_agent",
                "processing_time_ms": int((time.time() - start_time) * 1000)
            }
    
    async def _generate_single_image(
        self,
        suggestion: Dict[str, Any],
        style: str,
        options: Dict[str, Any]
    ) -> Dict[str, Any]:
        """単一画像の生成"""
        
        try:
            prompt = suggestion["image_prompt"]
            aspect_ratio = "3:2"  # 学級通信に適した比率
            
            result = generate_image_with_vertex_ai(
                prompt=prompt,
                style=style,
                aspect_ratio=aspect_ratio
            )
            
            return result
            
        except Exception as e:
            logger.error(f"単一画像生成エラー: {e}")
            return {
                "success": False,
                "error": str(e)
            }
    
    def cleanup_temp_images(self, image_paths: List[str]) -> int:
        """一時画像ファイルのクリーンアップ"""
        deleted_count = 0
        
        for path in image_paths:
            try:
                if os.path.exists(path):
                    os.unlink(path)
                    deleted_count += 1
                    logger.info(f"削除: {path}")
            except Exception as e:
                logger.warning(f"一時ファイル削除失敗 {path}: {e}")
        
        return deleted_count


# ==============================================================================
# 統合API関数
# ==============================================================================

async def enhance_media_with_adk(
    html_content: str,
    newsletter_data: Dict[str, Any],
    project_id: str,
    credentials_path: str,
    options: Dict[str, Any] = None
) -> Dict[str, Any]:
    """
    ADK メディアエージェントを使用した学級通信メディア強化
    
    Args:
        html_content: 元のHTMLコンテンツ
        newsletter_data: 学級通信データ
        project_id: Google Cloud プロジェクトID
        credentials_path: 認証情報ファイルパス
        options: メディア生成オプション
    
    Returns:
        Dict[str, Any]: メディア強化結果
    """
    agent = MediaAgent(project_id, credentials_path)
    
    result = await agent.enhance_newsletter_with_media(
        html_content=html_content,
        newsletter_data=newsletter_data,
        options=options
    )
    
    return result


# ==============================================================================
# テスト機能
# ==============================================================================

async def test_media_agent():
    """メディアエージェントのテスト"""
    
    # テスト用データ
    test_html = """
    <h1 style="color: #2c3e50;">3年1組 学級通信</h1>
    
    <h2 style="color: #3498db;">運動会の練習</h2>
    <p>今日は運動会の練習をしました。子どもたちは徒競走とダンスの練習を頑張っていました。
    特にたかしくんは最初は走るのが苦手でしたが、毎日練習を重ねて今ではクラスで3番目に速くなりました。</p>
    
    <h2 style="color: #e74c3c;">算数の授業</h2>
    <p>九九の練習をしました。7の段が少し難しそうでしたが、みんなで協力して覚えました。
    かけ算カードを使った練習が特に効果的でした。</p>
    
    <h2 style="color: #27ae60;">お知らせ</h2>
    <p>来週の運動会に向けて、体操服の準備をお願いします。</p>
    """
    
    test_newsletter_data = {
        "main_title": "3年1組 学級通信",
        "grade": "3年1組",
        "sections": [
            {
                "type": "main",
                "title": "運動会の練習",
                "content": "今日は運動会の練習をしました。子どもたちは徒競走とダンスの練習を頑張っていました。特にたかしくんは最初は走るのが苦手でしたが、毎日練習を重ねて今ではクラスで3番目に速くなりました。"
            },
            {
                "type": "main", 
                "title": "算数の授業",
                "content": "九九の練習をしました。7の段が少し難しそうでしたが、みんなで協力して覚えました。かけ算カードを使った練習が特に効果的でした。"
            },
            {
                "type": "announcement",
                "title": "お知らせ",
                "content": "来週の運動会に向けて、体操服の準備をお願いします。"
            }
        ]
    }
    
    test_options = {
        "max_images": 2,
        "image_style": "cartoon",
        "generate_images": False,  # テスト時は実際の画像生成をスキップ
        "auto_optimize": True
    }
    
    print("=== メディアエージェント テスト ===")
    
    try:
        result = await enhance_media_with_adk(
            html_content=test_html,
            newsletter_data=test_newsletter_data,
            project_id="test-project",
            credentials_path="test-credentials.json",
            options=test_options
        )
        
        print("=== メディアエージェント テスト結果 ===")
        print(json.dumps(result, ensure_ascii=False, indent=2))
        
        if result["success"]:
            print("✅ メディアエージェント: テスト成功")
            data = result["data"]
            print(f"画像追加数: {data['images_added']}")
            print(f"画像提案数: {len(data['image_suggestions'])}")
            print(f"HTMLサイズ: {len(data['enhanced_html'])}文字")
        else:
            print("❌ メディアエージェント: テスト失敗")
            print(f"エラー: {result['error']}")
        
        return result
        
    except Exception as e:
        print(f"❌ テストエラー: {e}")
        return {"success": False, "error": str(e)}


if __name__ == "__main__":
    # テスト実行
    asyncio.run(test_media_agent())