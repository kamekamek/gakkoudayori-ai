class SocketClient {
    constructor() {
        this.socket = null;
        this.isConnected = false;
        this.connectionRetries = 0;
        this.maxRetries = 5;
        this.userId = this.generateUserId();
        this.userName = '';
        this.userAvatar = '👤';
        this.onlineUsers = new Map();
        
        // イベントハンドラー
        this.onConnectionChange = null;
        this.onUserJoined = null;
        this.onUserLeft = null;
        this.onCanvasEvent = null;
        this.onChatMessage = null;
        this.onCursorMove = null;
    }

    generateUserId() {
        return 'user_' + Math.random().toString(36).substr(2, 9) + '_' + Date.now();
    }

    // 模擬サーバー接続（実際のSocket.ioサーバーの代替）
    connect(username, avatar) {
        this.userName = username;
        this.userAvatar = avatar;
        
        // 模擬接続遅延
        setTimeout(() => {
            this.isConnected = true;
            this.connectionRetries = 0;
            
            if (this.onConnectionChange) {
                this.onConnectionChange(true);
            }
            
            // 自分を参加者リストに追加
            this.onlineUsers.set(this.userId, {
                id: this.userId,
                name: this.userName,
                avatar: this.userAvatar,
                isLocal: true
            });
            
            // 模擬的な他のユーザーを追加
            this.addMockUsers();
            
            if (this.onUserJoined) {
                this.onUserJoined({
                    users: Array.from(this.onlineUsers.values())
                });
            }
            
            // 定期的な模擬イベント
            this.startMockEvents();
            
        }, 1000 + Math.random() * 2000);
    }

    addMockUsers() {
        const mockUsers = [
            { name: 'デザイナーA', avatar: '🎨' },
            { name: 'エンジニアB', avatar: '👨‍💻' },
            { name: 'プロダクトC', avatar: '👩‍💻' }
        ];
        
        mockUsers.forEach((user, index) => {
            setTimeout(() => {
                const userId = 'mock_user_' + index;
                this.onlineUsers.set(userId, {
                    id: userId,
                    name: user.name,
                    avatar: user.avatar,
                    isLocal: false
                });
                
                if (this.onUserJoined) {
                    this.onUserJoined({
                        users: Array.from(this.onlineUsers.values())
                    });
                }
            }, (index + 1) * 3000);
        });
    }

    startMockEvents() {
        // 模擬カーソル移動
        setInterval(() => {
            if (this.onCursorMove && Math.random() > 0.7) {
                const mockUserId = Array.from(this.onlineUsers.keys())
                    .find(id => id.startsWith('mock_user_'));
                
                if (mockUserId) {
                    this.onCursorMove({
                        userId: mockUserId,
                        x: Math.random() * 800,
                        y: Math.random() * 600,
                        userName: this.onlineUsers.get(mockUserId).name
                    });
                }
            }
        }, 500);
        
        // 模擬チャットメッセージ
        const mockMessages = [
            'このデザイン素晴らしいですね！',
            '色をもう少し明るくしてみましょう',
            'ユーザビリティを考慮すると...',
            'レスポンシブ対応も検討が必要ですね',
            'プロトタイプが完成しました！'
        ];
        
        let messageIndex = 0;
        setInterval(() => {
            if (this.onChatMessage && Math.random() > 0.8 && messageIndex < mockMessages.length) {
                const mockUserId = Array.from(this.onlineUsers.keys())
                    .find(id => id.startsWith('mock_user_'));
                
                if (mockUserId) {
                    this.onChatMessage({
                        userId: mockUserId,
                        userName: this.onlineUsers.get(mockUserId).name,
                        message: mockMessages[messageIndex],
                        timestamp: new Date()
                    });
                    messageIndex++;
                }
            }
        }, 8000);
    }

    disconnect() {
        this.isConnected = false;
        this.onlineUsers.clear();
        
        if (this.onConnectionChange) {
            this.onConnectionChange(false);
        }
    }

    // Canvas events
    emitCanvasEvent(eventType, data) {
        if (!this.isConnected) return;
        
        const eventData = {
            userId: this.userId,
            userName: this.userName,
            eventType,
            data,
            timestamp: new Date()
        };
        
        // 即座にローカルで処理
        if (this.onCanvasEvent) {
            this.onCanvasEvent(eventData);
        }
        
        // 他のクライアントに送信（模擬）
        setTimeout(() => {
            // 模擬的な他のユーザーからの応答
            if (Math.random() > 0.7) {
                this.simulateRemoteCanvasEvent(eventType, data);
            }
        }, 200 + Math.random() * 500);
    }

    simulateRemoteCanvasEvent(originalEventType, originalData) {
        const mockUserId = Array.from(this.onlineUsers.keys())
            .find(id => id.startsWith('mock_user_'));
        
        if (!mockUserId) return;
        
        let mockData = null;
        
        switch (originalEventType) {
            case 'path:created':
                mockData = {
                    path: this.createMockPath(),
                    color: this.getRandomColor()
                };
                break;
            case 'text:added':
                mockData = {
                    text: '素晴らしいアイデア！',
                    x: originalData.x + 50,
                    y: originalData.y + 30,
                    color: this.getRandomColor()
                };
                break;
            case 'object:added':
                mockData = {
                    object: this.createMockObject(),
                    x: originalData.x + 100,
                    y: originalData.y + 50
                };
                break;
        }
        
        if (mockData && this.onCanvasEvent) {
            this.onCanvasEvent({
                userId: mockUserId,
                userName: this.onlineUsers.get(mockUserId).name,
                eventType: originalEventType,
                data: mockData,
                timestamp: new Date()
            });
        }
    }

    createMockPath() {
        const startX = Math.random() * 600;
        const startY = Math.random() * 400;
        const path = [];
        
        for (let i = 0; i < 20; i++) {
            path.push({
                x: startX + Math.sin(i * 0.3) * 50,
                y: startY + i * 5
            });
        }
        
        return path;
    }

    createMockObject() {
        const objects = ['circle', 'rectangle', 'triangle'];
        return {
            type: objects[Math.floor(Math.random() * objects.length)],
            width: 50,
            height: 50,
            color: this.getRandomColor()
        };
    }

    getRandomColor() {
        const colors = ['#ff6b6b', '#4ecdc4', '#45b7d1', '#f9ca24', '#f0932b', '#eb4d4b'];
        return colors[Math.floor(Math.random() * colors.length)];
    }

    // Chat events
    sendChatMessage(message) {
        if (!this.isConnected || !message.trim()) return;
        
        const chatData = {
            userId: this.userId,
            userName: this.userName,
            message: message.trim(),
            timestamp: new Date()
        };
        
        if (this.onChatMessage) {
            this.onChatMessage(chatData);
        }
    }

    // Cursor events
    emitCursorMove(x, y) {
        if (!this.isConnected) return;
        
        // ローカルカーソルは表示しない（自分のカーソルは見えない）
        // リモートへの送信のみ模擬
    }

    // Connection status
    getConnectionStatus() {
        return {
            isConnected: this.isConnected,
            userId: this.userId,
            userName: this.userName,
            userCount: this.onlineUsers.size
        };
    }

    getOnlineUsers() {
        return Array.from(this.onlineUsers.values());
    }

    // Demo methods
    startDrawingDemo() {
        if (!this.isConnected) return;
        
        // 自動描画デモ
        const demoShapes = [
            { type: 'circle', x: 100, y: 100, radius: 50 },
            { type: 'rectangle', x: 200, y: 150, width: 100, height: 60 },
            { type: 'line', x1: 50, y1: 250, x2: 300, y2: 280 }
        ];
        
        demoShapes.forEach((shape, index) => {
            setTimeout(() => {
                this.emitCanvasEvent('demo:shape', shape);
            }, index * 2000);
        });
    }

    startCollaborationDemo() {
        if (!this.isConnected) return;
        
        // 複数ユーザーによる同時編集のデモ
        const collaborativeActions = [
            { action: 'addText', data: { text: 'チームワーク!', x: 150, y: 200 } },
            { action: 'addArrow', data: { x1: 100, y1: 300, x2: 250, y2: 320 } },
            { action: 'addNote', data: { text: 'レビュー完了', x: 300, y: 250 } }
        ];
        
        collaborativeActions.forEach((action, index) => {
            setTimeout(() => {
                this.emitCanvasEvent('collaboration:action', action);
            }, index * 1500);
        });
    }
}

// Export for use in other modules
window.SocketClient = SocketClient;