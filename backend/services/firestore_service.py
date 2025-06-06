"""
Firestore データベース操作サービス
ゆとり職員室システムのデータ管理を担当
"""

import json
import uuid
from datetime import datetime
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, asdict, field
from enum import Enum

from google.cloud import firestore
from google.cloud.firestore_v1.base_query import FieldFilter
from google.api_core.exceptions import NotFound, PermissionDenied


class DocumentStatus(Enum):
    """ドキュメントのステータス"""
    DRAFT = "draft"
    IN_REVIEW = "in_review"
    PUBLISHED = "published"
    ARCHIVED = "archived"


class TemplateCategory(Enum):
    """テンプレートのカテゴリ"""
    SEASONAL = "seasonal"
    EVENT = "event"
    ACADEMIC = "academic"
    GENERAL = "general"


@dataclass
class User:
    """ユーザー情報"""
    uid: str
    email: str
    display_name: str
    created_at: datetime = field(default_factory=datetime.now)
    updated_at: datetime = field(default_factory=datetime.now)
    settings: Dict[str, Any] = field(default_factory=dict)
    
    def to_dict(self) -> Dict[str, Any]:
        data = asdict(self)
        # datetimeオブジェクトをFirestore形式に変換
        data['created_at'] = self.created_at
        data['updated_at'] = self.updated_at
        return data


@dataclass
class Document:
    """学級通信ドキュメント"""
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    user_id: str = ""
    title: str = ""
    content: str = ""
    html_content: str = ""
    status: DocumentStatus = DocumentStatus.DRAFT
    tags: List[str] = field(default_factory=list)
    template_id: Optional[str] = None
    created_at: datetime = field(default_factory=datetime.now)
    updated_at: datetime = field(default_factory=datetime.now)
    version: int = 1
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    def to_dict(self) -> Dict[str, Any]:
        data = asdict(self)
        data['status'] = self.status.value
        data['created_at'] = self.created_at
        data['updated_at'] = self.updated_at
        return data
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'Document':
        # ステータスをenumに変換
        if 'status' in data:
            data['status'] = DocumentStatus(data['status'])
        
        # datetimeフィールドの処理
        if 'created_at' in data and hasattr(data['created_at'], 'timestamp'):
            data['created_at'] = data['created_at'].timestamp()
        if 'updated_at' in data and hasattr(data['updated_at'], 'timestamp'):
            data['updated_at'] = data['updated_at'].timestamp()
            
        return cls(**data)


@dataclass
class Template:
    """テンプレート情報"""
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    name: str = ""
    description: str = ""
    category: TemplateCategory = TemplateCategory.GENERAL
    html_template: str = ""
    css_styles: str = ""
    preview_url: str = ""
    is_active: bool = True
    order: int = 0
    created_at: datetime = field(default_factory=datetime.now)
    updated_at: datetime = field(default_factory=datetime.now)
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    def to_dict(self) -> Dict[str, Any]:
        data = asdict(self)
        data['category'] = self.category.value
        data['created_at'] = self.created_at
        data['updated_at'] = self.updated_at
        return data
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'Template':
        if 'category' in data:
            data['category'] = TemplateCategory(data['category'])
            
        if 'created_at' in data and hasattr(data['created_at'], 'timestamp'):
            data['created_at'] = data['created_at'].timestamp()
        if 'updated_at' in data and hasattr(data['updated_at'], 'timestamp'):
            data['updated_at'] = data['updated_at'].timestamp()
            
        return cls(**data)


class FirestoreService:
    """Firestore データベース操作サービス"""
    
    def __init__(self):
        self.db = firestore.Client()
    
    # ユーザー操作
    async def create_user(self, user: User) -> str:
        """ユーザーを作成"""
        try:
            doc_ref = self.db.collection('users').document(user.uid)
            doc_ref.set(user.to_dict())
            return user.uid
        except Exception as e:
            raise Exception(f"ユーザー作成エラー: {str(e)}")
    
    async def get_user(self, uid: str) -> Optional[User]:
        """ユーザー情報を取得"""
        try:
            doc_ref = self.db.collection('users').document(uid)
            doc = doc_ref.get()
            
            if doc.exists:
                data = doc.to_dict()
                data['uid'] = uid
                return User(**data)
            return None
        except Exception as e:
            raise Exception(f"ユーザー取得エラー: {str(e)}")
    
    async def update_user(self, uid: str, updates: Dict[str, Any]) -> bool:
        """ユーザー情報を更新"""
        try:
            updates['updated_at'] = datetime.now()
            doc_ref = self.db.collection('users').document(uid)
            doc_ref.update(updates)
            return True
        except Exception as e:
            raise Exception(f"ユーザー更新エラー: {str(e)}")
    
    # ドキュメント操作
    async def create_document(self, document: Document) -> str:
        """ドキュメントを作成"""
        try:
            doc_ref = self.db.collection('documents').document(document.id)
            doc_ref.set(document.to_dict())
            return document.id
        except Exception as e:
            raise Exception(f"ドキュメント作成エラー: {str(e)}")
    
    async def get_document(self, document_id: str) -> Optional[Document]:
        """ドキュメントを取得"""
        try:
            doc_ref = self.db.collection('documents').document(document_id)
            doc = doc_ref.get()
            
            if doc.exists:
                data = doc.to_dict()
                data['id'] = document_id
                return Document.from_dict(data)
            return None
        except Exception as e:
            raise Exception(f"ドキュメント取得エラー: {str(e)}")
    
    async def update_document(self, document_id: str, updates: Dict[str, Any]) -> bool:
        """ドキュメントを更新"""
        try:
            updates['updated_at'] = datetime.now()
            if 'status' in updates and isinstance(updates['status'], DocumentStatus):
                updates['status'] = updates['status'].value
                
            doc_ref = self.db.collection('documents').document(document_id)
            doc_ref.update(updates)
            return True
        except Exception as e:
            raise Exception(f"ドキュメント更新エラー: {str(e)}")
    
    async def delete_document(self, document_id: str) -> bool:
        """ドキュメントを削除"""
        try:
            doc_ref = self.db.collection('documents').document(document_id)
            doc_ref.delete()
            return True
        except Exception as e:
            raise Exception(f"ドキュメント削除エラー: {str(e)}")
    
    async def get_user_documents(
        self, 
        user_id: str, 
        status: Optional[DocumentStatus] = None,
        limit: int = 50,
        offset: int = 0
    ) -> List[Document]:
        """ユーザーのドキュメント一覧を取得"""
        try:
            query = self.db.collection('documents').where(
                filter=FieldFilter('user_id', '==', user_id)
            )
            
            if status:
                query = query.where(filter=FieldFilter('status', '==', status.value))
            
            query = query.order_by('created_at', direction=firestore.Query.DESCENDING)
            query = query.limit(limit).offset(offset)
            
            docs = query.stream()
            documents = []
            
            for doc in docs:
                data = doc.to_dict()
                data['id'] = doc.id
                documents.append(Document.from_dict(data))
            
            return documents
        except Exception as e:
            raise Exception(f"ドキュメント一覧取得エラー: {str(e)}")
    
    # テンプレート操作
    async def create_template(self, template: Template) -> str:
        """テンプレートを作成"""
        try:
            doc_ref = self.db.collection('templates').document(template.id)
            doc_ref.set(template.to_dict())
            return template.id
        except Exception as e:
            raise Exception(f"テンプレート作成エラー: {str(e)}")
    
    async def get_template(self, template_id: str) -> Optional[Template]:
        """テンプレートを取得"""
        try:
            doc_ref = self.db.collection('templates').document(template_id)
            doc = doc_ref.get()
            
            if doc.exists:
                data = doc.to_dict()
                data['id'] = template_id
                return Template.from_dict(data)
            return None
        except Exception as e:
            raise Exception(f"テンプレート取得エラー: {str(e)}")
    
    async def get_templates(
        self, 
        category: Optional[TemplateCategory] = None,
        is_active: bool = True
    ) -> List[Template]:
        """テンプレート一覧を取得"""
        try:
            query = self.db.collection('templates')
            
            if category:
                query = query.where(filter=FieldFilter('category', '==', category.value))
            
            query = query.where(filter=FieldFilter('is_active', '==', is_active))
            query = query.order_by('order').order_by('created_at')
            
            docs = query.stream()
            templates = []
            
            for doc in docs:
                data = doc.to_dict()
                data['id'] = doc.id
                templates.append(Template.from_dict(data))
            
            return templates
        except Exception as e:
            raise Exception(f"テンプレート一覧取得エラー: {str(e)}")
    
    # ユーザー辞書操作
    async def add_dictionary_entry(self, user_id: str, word: str, reading: str) -> str:
        """ユーザー辞書にエントリを追加"""
        try:
            entry_id = str(uuid.uuid4())
            entry_data = {
                'word': word,
                'reading': reading,
                'created_at': datetime.now(),
                'updated_at': datetime.now()
            }
            
            doc_ref = self.db.collection('users').document(user_id)
            doc_ref = doc_ref.collection('dictionary').document(entry_id)
            doc_ref.set(entry_data)
            
            return entry_id
        except Exception as e:
            raise Exception(f"辞書エントリ追加エラー: {str(e)}")
    
    async def get_user_dictionary(self, user_id: str) -> List[Dict[str, Any]]:
        """ユーザー辞書を取得"""
        try:
            collection_ref = self.db.collection('users').document(user_id).collection('dictionary')
            docs = collection_ref.order_by('word').stream()
            
            dictionary = []
            for doc in docs:
                data = doc.to_dict()
                data['id'] = doc.id
                dictionary.append(data)
            
            return dictionary
        except Exception as e:
            raise Exception(f"辞書取得エラー: {str(e)}")
    
    async def delete_dictionary_entry(self, user_id: str, entry_id: str) -> bool:
        """ユーザー辞書のエントリを削除"""
        try:
            doc_ref = self.db.collection('users').document(user_id)
            doc_ref = doc_ref.collection('dictionary').document(entry_id)
            doc_ref.delete()
            return True
        except Exception as e:
            raise Exception(f"辞書エントリ削除エラー: {str(e)}")
    
    # 検索機能
    async def search_documents(
        self, 
        user_id: str, 
        query: str, 
        limit: int = 20
    ) -> List[Document]:
        """ドキュメントを検索（タイトルと内容）"""
        try:
            # Firestoreの全文検索は制限があるため、
            # 実際の実装では外部検索サービス（Algolia等）の利用を推奨
            
            # 現在はタイトルでの部分マッチのみ実装
            query_ref = self.db.collection('documents')
            query_ref = query_ref.where(filter=FieldFilter('user_id', '==', user_id))
            query_ref = query_ref.where(filter=FieldFilter('title', '>=', query))
            query_ref = query_ref.where(filter=FieldFilter('title', '<=', query + '\uf8ff'))
            query_ref = query_ref.limit(limit)
            
            docs = query_ref.stream()
            documents = []
            
            for doc in docs:
                data = doc.to_dict()
                data['id'] = doc.id
                documents.append(Document.from_dict(data))
            
            return documents
        except Exception as e:
            raise Exception(f"ドキュメント検索エラー: {str(e)}")


# サービスインスタンス
firestore_service = FirestoreService() 