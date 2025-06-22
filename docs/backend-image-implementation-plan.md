# 🖼️ バックエンド画像処理 実装計画書

## 📋 概要

学校だよりAIのバックエンド画像処理機能の詳細実装計画。フロントエンドUI完成後に実装予定。

## 🎯 推奨アーキテクチャ: **ハイブリッド方式**

### 基本方針
- **小さい画像**: フロントエンド → Firebase Storage直接アップロード
- **大きい画像**: フロントエンド → バックエンド → 処理 → Firebase Storage
- **メタデータ**: すべてバックエンドのFirestoreで管理

## 📁 実装予定ファイル構成

```
backend/functions/
├── image_service.py           # 画像処理メインサービス
├── image_validation.py       # 画像バリデーション
├── image_metadata_service.py # メタデータ管理
├── newsletter_image_service.py # 学級通信画像統合
└── requirements.txt          # 新規依存関係追加
```

## 🔧 実装内容詳細

### 1. **画像処理API** (`image_service.py`)

```python
from fastapi import UploadFile, HTTPException, Depends
from google.cloud import storage
from PIL import Image, ImageOps
import io
from typing import List, Dict, Optional

class ImageProcessingService:
    def __init__(self):
        self.storage_client = storage.Client()
        self.bucket = self.storage_client.bucket('gakkoudayori-ai.appspot.com')
        self.max_size = (1920, 1080)
        self.quality = 85
        
    async def process_image(
        self,
        file: UploadFile,
        user_id: str,
        newsletter_id: Optional[str] = None,
        auto_optimize: bool = True
    ) -> Dict:
        """画像を処理してアップロード"""
        
        # 1. バリデーション
        self._validate_image(file)
        
        # 2. 画像読み込み
        image_data = await file.read()
        original_size = len(image_data)
        
        # 3. 画像処理（必要に応じて）
        if auto_optimize or original_size > 2 * 1024 * 1024:  # 2MB以上
            processed_data, metadata = self._optimize_image(image_data, file.filename)
        else:
            processed_data = image_data
            metadata = self._extract_metadata(image_data)
        
        # 4. Firebase Storageアップロード
        blob_path = self._generate_blob_path(user_id, newsletter_id, file.filename)
        download_url = await self._upload_to_storage(processed_data, blob_path, file.content_type)
        
        # 5. メタデータ整理
        result = {
            "id": self._generate_image_id(),
            "name": file.filename,
            "url": download_url,
            "blob_path": blob_path,
            "size": len(processed_data),
            "original_size": original_size,
            "content_type": file.content_type,
            "metadata": metadata,
            "created_at": datetime.utcnow().isoformat(),
            "user_id": user_id,
            "newsletter_id": newsletter_id
        }
        
        return result
    
    def _optimize_image(self, image_data: bytes, filename: str) -> tuple[bytes, dict]:
        """画像最適化処理"""
        with Image.open(io.BytesIO(image_data)) as img:
            # EXIFデータに基づく回転補正
            img = ImageOps.exif_transpose(img)
            
            # RGBに変換（透明度削除）
            if img.mode in ('RGBA', 'LA', 'P'):
                background = Image.new('RGB', img.size, (255, 255, 255))
                if img.mode == 'P':
                    img = img.convert('RGBA')
                background.paste(img, mask=img.split()[-1] if img.mode == 'RGBA' else None)
                img = background
            
            # リサイズ
            original_size = img.size
            img.thumbnail(self.max_size, Image.Resampling.LANCZOS)
            
            # 保存
            output = io.BytesIO()
            img.save(output, format='JPEG', quality=self.quality, optimize=True)
            
            metadata = {
                "width": img.size[0],
                "height": img.size[1],
                "original_width": original_size[0],
                "original_height": original_size[1],
                "is_optimized": True,
                "compression_ratio": output.tell() / len(image_data)
            }
            
            return output.getvalue(), metadata

# APIエンドポイント
@app.post("/api/v1/images/upload")
async def upload_image(
    file: UploadFile,
    user_id: str = Header(...),
    newsletter_id: Optional[str] = None,
    auto_optimize: bool = True,
    image_service: ImageProcessingService = Depends()
):
    """画像アップロードAPI"""
    try:
        result = await image_service.process_image(
            file, user_id, newsletter_id, auto_optimize
        )
        
        # Firestoreにメタデータ保存
        await save_image_metadata(result)
        
        return {"success": True, "image": result}
        
    except Exception as e:
        raise HTTPException(500, f"Image upload failed: {str(e)}")
```

### 2. **学級通信画像統合** (`newsletter_image_service.py`)

```python
class NewsletterImageService:
    def __init__(self):
        self.gemini_service = GeminiApiService()
        
    async def integrate_images_to_newsletter(
        self,
        newsletter_id: str,
        content: str,
        images: List[Dict],
        style: str = "classic"
    ) -> str:
        """学級通信に画像を統合"""
        
        # 1. 画像の最適な配置位置をAIで判断
        image_placements = await self._analyze_image_placements(content, images)
        
        # 2. HTMLテンプレートに画像挿入
        html_content = self._insert_images_to_html(content, image_placements, style)
        
        # 3. レスポンシブ対応
        final_html = self._make_responsive(html_content)
        
        return final_html
    
    async def _analyze_image_placements(self, content: str, images: List[Dict]) -> List[Dict]:
        """Gemini AIで画像の最適配置を判断"""
        
        prompt = f"""
        以下の学級通信の文章に、{len(images)}枚の画像を効果的に配置してください。
        
        文章: {content}
        
        画像情報:
        {[{'name': img['name'], 'description': img.get('alt_text', '')} for img in images]}
        
        以下の形式でJSON回答してください:
        {{
            "placements": [
                {{
                    "image_index": 0,
                    "position": "paragraph_2_after",
                    "size": "medium",
                    "alignment": "center",
                    "caption": "適切なキャプション"
                }}
            ]
        }}
        """
        
        response = await self.gemini_service.generate_content(prompt)
        return json.loads(response)["placements"]
    
    def _insert_images_to_html(self, content: str, placements: List[Dict], style: str) -> str:
        """HTMLに画像を挿入"""
        
        # スタイルに応じたCSSクラス
        style_classes = {
            "classic": "newsletter-classic",
            "modern": "newsletter-modern"
        }
        
        html_template = f"""
        <div class="newsletter-container {style_classes.get(style, '')}">
            <style>
            .image-container {{
                margin: 16px 0;
                text-align: center;
            }}
            .image-container.left {{ text-align: left; }}
            .image-container.right {{ text-align: right; }}
            .newsletter-image {{
                max-width: 100%;
                height: auto;
                border-radius: 8px;
                box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            }}
            .image-caption {{
                font-size: 0.9em;
                color: #666;
                margin-top: 8px;
                font-style: italic;
            }}
            </style>
            {{content_with_images}}
        </div>
        """
        
        # 段落分割して画像挿入
        paragraphs = content.split('\n\n')
        
        for placement in placements:
            image_html = self._generate_image_html(
                images[placement['image_index']], 
                placement
            )
            # 指定位置に挿入logic
            
        return html_template.format(content_with_images=final_content)

# APIエンドポイント
@app.post("/api/v1/newsletters/{newsletter_id}/generate-with-images")
async def generate_newsletter_with_images(
    newsletter_id: str,
    content: str,
    image_ids: List[str],
    style: str = "classic",
    user_id: str = Header(...),
    newsletter_service: NewsletterImageService = Depends()
):
    """画像付き学級通信生成"""
    
    # 画像メタデータ取得
    images = await get_images_metadata(image_ids, user_id)
    
    # 学級通信生成
    html_result = await newsletter_service.integrate_images_to_newsletter(
        newsletter_id, content, images, style
    )
    
    return {"success": True, "html": html_result}
```

### 3. **メタデータ管理** (`image_metadata_service.py`)

```python
class ImageMetadataService:
    def __init__(self):
        self.db = firestore.client()
        
    async def save_image_metadata(self, image_data: Dict) -> str:
        """画像メタデータをFirestoreに保存"""
        
        doc_ref = self.db.collection('images').document(image_data['id'])
        await doc_ref.set({
            **image_data,
            'created_at': firestore.SERVER_TIMESTAMP,
            'updated_at': firestore.SERVER_TIMESTAMP
        })
        
        return image_data['id']
    
    async def get_user_images(
        self,
        user_id: str,
        newsletter_id: Optional[str] = None,
        limit: int = 50
    ) -> List[Dict]:
        """ユーザーの画像一覧取得"""
        
        query = self.db.collection('images').where('user_id', '==', user_id)
        
        if newsletter_id:
            query = query.where('newsletter_id', '==', newsletter_id)
            
        docs = query.order_by('created_at', direction=firestore.Query.DESCENDING).limit(limit).get()
        
        return [doc.to_dict() for doc in docs]
    
    async def delete_image(self, image_id: str, user_id: str) -> bool:
        """画像削除（Storage + Firestore）"""
        
        # メタデータ取得
        doc_ref = self.db.collection('images').document(image_id)
        doc = await doc_ref.get()
        
        if not doc.exists or doc.to_dict().get('user_id') != user_id:
            return False
            
        image_data = doc.to_dict()
        
        # Storage削除
        blob = self.storage_client.bucket().blob(image_data['blob_path'])
        blob.delete()
        
        # Firestore削除
        await doc_ref.delete()
        
        return True

# APIエンドポイント群
@app.get("/api/v1/images")
async def get_images(user_id: str = Header(...), newsletter_id: Optional[str] = None):
    """画像一覧取得"""
    
@app.delete("/api/v1/images/{image_id}")
async def delete_image(image_id: str, user_id: str = Header(...)):
    """画像削除"""
```

### 4. **バリデーション** (`image_validation.py`)

```python
class ImageValidator:
    ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
    MAX_SIZE = 10 * 1024 * 1024  # 10MB
    MAX_DIMENSIONS = (4000, 4000)
    
    @classmethod
    def validate_upload(cls, file: UploadFile) -> None:
        """アップロード画像のバリデーション"""
        
        # ファイルサイズ
        if file.size > cls.MAX_SIZE:
            raise HTTPException(413, f"File too large. Max {cls.MAX_SIZE/1024/1024:.1f}MB")
        
        # MIMEタイプ
        if file.content_type not in cls.ALLOWED_TYPES:
            raise HTTPException(400, f"Unsupported file type: {file.content_type}")
        
        # ファイル名
        if not file.filename or len(file.filename) > 255:
            raise HTTPException(400, "Invalid filename")
    
    @classmethod
    def validate_image_content(cls, image_data: bytes) -> None:
        """画像内容のバリデーション"""
        
        try:
            with Image.open(io.BytesIO(image_data)) as img:
                # 寸法チェック
                if img.size[0] > cls.MAX_DIMENSIONS[0] or img.size[1] > cls.MAX_DIMENSIONS[1]:
                    raise HTTPException(400, f"Image too large. Max {cls.MAX_DIMENSIONS}")
                
                # 最小サイズチェック
                if img.size[0] < 50 or img.size[1] < 50:
                    raise HTTPException(400, "Image too small. Min 50x50px")
                    
        except Exception as e:
            raise HTTPException(400, f"Invalid image data: {str(e)}")
```

### 5. **requirements.txt 追加**

```txt
# 既存の依存関係に追加
Pillow==10.2.0
google-cloud-storage==2.10.0
python-magic==0.4.27
```

## 🚀 実装フェーズ

### Phase 1: 基本画像API
- [x] 画像アップロードエンドポイント
- [x] 画像メタデータ管理
- [x] 基本的な画像処理

### Phase 2: 学級通信統合
- [x] 画像付きHTML生成
- [x] AIによる最適配置
- [x] スタイル適用

### Phase 3: 高度機能
- [x] 画像認識・自動キャプション
- [x] 不適切コンテンツフィルタリング
- [x] 高度な画像編集

## 📊 パフォーマンス最適化

### キャッシュ戦略
- **CDN**: Firebase Storage CDN活用
- **サムネイル**: 複数サイズ生成
- **遅延読み込み**: lazy loading対応

### セキュリティ
- **認証**: Firebase Auth必須
- **認可**: ユーザー自身の画像のみアクセス
- **スキャン**: Google Vision API SafeSearch

## 🔄 フロントエンド統合ポイント

```dart
// フロントエンドでの統合例
class ImageUploadService {
  // 小さい画像: 直接Firebase Storage
  // 大きい画像: バックエンド経由
  
  Future<ImageUploadResult> uploadImage(Uint8List bytes, String fileName) async {
    if (bytes.length < 2 * 1024 * 1024) {
      return await _uploadDirectToStorage(bytes, fileName);
    } else {
      return await _uploadViaBackend(bytes, fileName);
    }
  }
}
```

---

**📝 実装開始タイミング**: フロントエンドUI完成後
**🎯 実装担当**: バックエンド担当者
**⏱️ 推定工数**: 3-5日間
**📋 依存関係**: Firebase Storage設定、Firestore設定

このプランに従って、画像機能の完全なバックエンド統合を実装予定です！