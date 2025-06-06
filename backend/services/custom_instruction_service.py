"""
カスタム指示機能サービス
「やさしい語り口」「学年主任らしい口調」等のワンフレーズ反映機能
"""
import time
import asyncio
import json
from typing import Dict, List, Optional, Any
import logging

from config.gcloud_config import cloud_config

# ログ設定
logger = logging.getLogger(__name__)

class CustomInstructionService:
    """カスタム指示管理サービスクラス"""
    
    def __init__(self):
        """カスタム指示サービス初期化"""
        self.project_id = cloud_config.project_id
        
        # プリセット指示テンプレート
        self.preset_instructions = {
            # 語り口スタイル
            "gentle": {
                "name": "やさしい語り口",
                "description": "温かく親しみやすい表現で、保護者に寄り添う語調",
                "instruction": "温かく親しみやすい表現を使い、保護者の気持ちに寄り添うような優しい語調で書いてください。敬語は適度に使い、堅すぎないようにしてください。",
                "examples": ["心配なことがありましたら、いつでもお声かけください", "お子様の頑張りを一緒に見守っていきましょう"],
                "category": "tone"
            },
            
            "formal": {
                "name": "丁寧で礼儀正しい口調",
                "description": "適切な敬語を使った格式ある表現",
                "instruction": "適切な敬語を使い、格式ある丁寧な表現で書いてください。保護者への敬意を込めた文体にしてください。",
                "examples": ["ご理解とご協力を賜りますよう、よろしくお願い申し上げます", "お忙しい中恐れ入りますが"],
                "category": "tone"
            },
            
            "energetic": {
                "name": "元気で明るい表現",
                "description": "活気があり前向きな雰囲気の文体",
                "instruction": "元気で明るく、前向きな気持ちが伝わるような表現で書いてください。子どもたちの活動の様子が生き生きと伝わるようにしてください。",
                "examples": ["今日も子どもたちは元気いっぱいでした！", "みんなで楽しく取り組んでいます"],
                "category": "tone"
            },
            
            # 役職・立場スタイル
            "homeroom_teacher": {
                "name": "担任らしい親近感",
                "description": "クラスの子どもたちを身近に感じる温かい表現",
                "instruction": "担任教師として、クラスの子どもたち一人ひとりへの愛情と理解が伝わるような表現で書いてください。具体的なエピソードを交えて親近感を演出してください。",
                "examples": ["○○さんが「先生見て見て！」と嬉しそうに見せてくれました", "いつも元気な△△くんですが"],
                "category": "role"
            },
            
            "head_teacher": {
                "name": "学年主任らしい口調",
                "description": "責任感と経験を感じさせる安定した文体",
                "instruction": "学年主任として、責任感と豊富な経験に基づいた安定感のある表現で書いてください。学年全体を見渡した視点と、保護者への信頼感を込めた文体にしてください。",
                "examples": ["学年として一丸となって取り組んでまいります", "これまでの経験を踏まえ、適切に指導してまいります"],
                "category": "role"
            },
            
            "principal": {
                "name": "校長らしい格調高い表現",
                "description": "学校全体を統括する立場としての威厳ある文体",
                "instruction": "校長として、学校全体の教育方針と理念が伝わるような格調高い表現で書いてください。教育への深い理解と責任感を込めた文体にしてください。",
                "examples": ["本校の教育方針に基づき", "お子様の健やかな成長を願って"],
                "category": "role"
            },
            
            # 内容・目的スタイル
            "event_report": {
                "name": "行事報告向けの表現",
                "description": "イベントの様子を生き生きと伝える描写重視の文体",
                "instruction": "行事やイベントの様子を生き生きと伝えるため、具体的な描写と子どもたちの表情や動きが目に浮かぶような表現で書いてください。",
                "examples": ["運動会では、最後まで諦めずに走り抜く姿が印象的でした", "みんなの笑顔がキラキラと輝いていました"],
                "category": "purpose"
            },
            
            "learning_progress": {
                "name": "学習状況報告向け",
                "description": "学習の進度や成果を分かりやすく伝える説明重視の文体",
                "instruction": "学習の進度や成果について、保護者が理解しやすいように具体的で分かりやすい説明を心がけて書いてください。専門用語は避け、家庭でのサポート方法も含めてください。",
                "examples": ["算数では、九九の暗記が着実に進んでいます", "家庭学習では復習を中心に取り組んでいただけると"],
                "category": "purpose"
            },
            
            "announcement": {
                "name": "お知らせ・連絡事項向け",
                "description": "重要な情報を明確に伝える簡潔で分かりやすい文体",
                "instruction": "重要な連絡事項やお知らせを、誤解が生じないよう明確で簡潔に伝えてください。必要な情報は漏れなく、分かりやすい順序で記載してください。",
                "examples": ["日時：○月○日（○）○時～○時", "ご不明な点がございましたら、担任までお尋ねください"],
                "category": "purpose"
            }
        }
        
        logger.info(f"カスタム指示サービス初期化成功: {len(self.preset_instructions)}個のプリセット")
    
    async def apply_custom_instruction(
        self,
        original_text: str,
        instruction_id: Optional[str] = None,
        custom_instruction: Optional[str] = None,
        intensity: str = "medium",
        preserve_facts: bool = True
    ) -> Dict[str, Any]:
        """
        カスタム指示を適用してテキストを変換
        
        Args:
            original_text: 元のテキスト
            instruction_id: プリセット指示ID
            custom_instruction: カスタム指示文
            intensity: 適用強度 ('light', 'medium', 'strong')
            preserve_facts: 事実関係を保持するか
            
        Returns:
            Dict containing transformed text and metadata
        """
        start_time = time.time()
        
        try:
            # 使用する指示を決定
            final_instruction = await self._build_final_instruction(
                instruction_id=instruction_id,
                custom_instruction=custom_instruction,
                intensity=intensity,
                preserve_facts=preserve_facts
            )
            
            # AI サービスを使用してテキスト変換
            from services.ai_service import ai_service
            
            result = await ai_service.rewrite_text(
                original_text=original_text,
                style="custom",
                custom_instruction=final_instruction["instruction"],
                grade_level="elementary"
            )
            
            elapsed_time = time.time() - start_time
            
            # 結果に追加情報を付与
            enhanced_result = {
                **result,
                "custom_instruction_applied": final_instruction,
                "transformation_type": "custom_instruction",
                "intensity": intensity,
                "preserve_facts": preserve_facts,
                "processing_time_ms": int(elapsed_time * 1000),
                "timestamp": int(time.time())
            }
            
            logger.info(f"カスタム指示適用成功: {instruction_id or 'custom'}, {elapsed_time:.3f}s")
            return enhanced_result
            
        except Exception as e:
            logger.error(f"カスタム指示適用失敗: {e}")
            raise RuntimeError(f"Failed to apply custom instruction: {str(e)}")
    
    async def get_preset_instructions(
        self,
        category: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        プリセット指示一覧を取得
        
        Args:
            category: カテゴリフィルタ ('tone', 'role', 'purpose')
            
        Returns:
            Dict containing preset instructions
        """
        try:
            filtered_instructions = {}
            
            for inst_id, instruction in self.preset_instructions.items():
                if category is None or instruction.get("category") == category:
                    filtered_instructions[inst_id] = {
                        "id": inst_id,
                        "name": instruction["name"],
                        "description": instruction["description"],
                        "category": instruction["category"],
                        "examples": instruction["examples"][:2]  # 最初の2例のみ
                    }
            
            result = {
                "presets": filtered_instructions,
                "categories": list(set(inst["category"] for inst in self.preset_instructions.values())),
                "total_count": len(filtered_instructions),
                "filter_applied": category
            }
            
            logger.info(f"プリセット指示取得: {len(filtered_instructions)}個, カテゴリ: {category or '全て'}")
            return result
            
        except Exception as e:
            logger.error(f"プリセット指示取得失敗: {e}")
            raise RuntimeError(f"Failed to get preset instructions: {str(e)}")
    
    async def create_user_instruction(
        self,
        user_id: str,
        name: str,
        instruction: str,
        description: Optional[str] = None,
        examples: Optional[List[str]] = None
    ) -> Dict[str, Any]:
        """
        ユーザー独自の指示を作成
        
        Args:
            user_id: ユーザーID
            name: 指示名
            instruction: 指示内容
            description: 説明
            examples: 使用例
            
        Returns:
            Dict containing created instruction
        """
        try:
            instruction_id = f"user_{user_id}_{int(time.time())}"
            
            user_instruction = {
                "id": instruction_id,
                "user_id": user_id,
                "name": name,
                "instruction": instruction,
                "description": description or f"{name}の指示",
                "examples": examples or [],
                "category": "user_custom",
                "created_at": int(time.time()),
                "usage_count": 0
            }
            
            # TODO: Firestoreに保存（Phase 1で実装予定）
            # await self._save_user_instruction(user_id, instruction_id, user_instruction)
            
            # 暫定的にメモリ内保存
            await self._save_to_memory(user_id, instruction_id, user_instruction)
            
            logger.info(f"ユーザー指示作成成功: {user_id}, {name}")
            return user_instruction
            
        except Exception as e:
            logger.error(f"ユーザー指示作成失敗: {e}")
            raise RuntimeError(f"Failed to create user instruction: {str(e)}")
    
    async def get_user_instructions(self, user_id: str) -> Dict[str, Any]:
        """
        ユーザーの指示一覧を取得
        
        Args:
            user_id: ユーザーID
            
        Returns:
            Dict containing user instructions
        """
        try:
            # TODO: Firestoreから取得（Phase 1で実装予定）
            # user_instructions = await self._get_user_instructions_from_firestore(user_id)
            
            # 暫定的にメモリから取得
            user_instructions = await self._get_from_memory(user_id)
            
            result = {
                "user_id": user_id,
                "instructions": user_instructions,
                "count": len(user_instructions),
                "timestamp": int(time.time())
            }
            
            logger.info(f"ユーザー指示取得: {user_id}, {len(user_instructions)}個")
            return result
            
        except Exception as e:
            logger.error(f"ユーザー指示取得失敗: {e}")
            raise RuntimeError(f"Failed to get user instructions: {str(e)}")
    
    async def _build_final_instruction(
        self,
        instruction_id: Optional[str],
        custom_instruction: Optional[str],
        intensity: str,
        preserve_facts: bool
    ) -> Dict[str, Any]:
        """
        最終的な指示を構築
        """
        base_instruction = ""
        instruction_name = "カスタム指示"
        
        # プリセット指示の場合
        if instruction_id and instruction_id in self.preset_instructions:
            preset = self.preset_instructions[instruction_id]
            base_instruction = preset["instruction"]
            instruction_name = preset["name"]
        
        # カスタム指示の場合
        elif custom_instruction:
            base_instruction = custom_instruction
            instruction_name = "ユーザー指定"
        
        # 強度調整
        intensity_modifiers = {
            "light": "軽く",
            "medium": "適度に",
            "strong": "しっかりと"
        }
        intensity_text = intensity_modifiers.get(intensity, "適度に")
        
        # 事実保持の指示
        fact_preservation = "元の事実関係や重要な情報は必ず保持してください。" if preserve_facts else ""
        
        # 最終指示を構築
        final_instruction = f"""以下の指示に{intensity_text}従って文章を書き直してください：

{base_instruction}

{fact_preservation}

変更する際は、内容の意味を変えず、指定されたスタイルを{intensity_text}反映させてください。"""
        
        return {
            "instruction": final_instruction,
            "name": instruction_name,
            "preset_id": instruction_id,
            "intensity": intensity,
            "preserve_facts": preserve_facts
        }
    
    async def _save_to_memory(self, user_id: str, instruction_id: str, instruction: Dict[str, Any]) -> None:
        """メモリ内にユーザー指示を保存（開発用）"""
        if not hasattr(self, '_memory_storage'):
            self._memory_storage = {}
        
        if user_id not in self._memory_storage:
            self._memory_storage[user_id] = {}
        
        self._memory_storage[user_id][instruction_id] = instruction
    
    async def _get_from_memory(self, user_id: str) -> List[Dict[str, Any]]:
        """メモリからユーザー指示を取得（開発用）"""
        if not hasattr(self, '_memory_storage'):
            return []
        
        user_instructions = self._memory_storage.get(user_id, {})
        return list(user_instructions.values())

# グローバルサービスインスタンス
custom_instruction_service = CustomInstructionService()