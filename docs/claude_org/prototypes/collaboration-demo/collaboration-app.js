class CollaborationApp {
    constructor() {
        this.socketClient = null;
        this.canvasManager = null;
        this.isJoined = false;
        this.userName = '';
        this.userAvatar = '👤';
        this.chatMessages = [];
        
        this.init();
    }

    async init() {
        this.showLoadingScreen();
        
        // Initialize components
        await this.initializeComponents();
        this.setupEventListeners();
        
        // Show join modal
        setTimeout(() => {
            this.hideLoadingScreen();
            this.showJoinModal();
        }, 1500);
    }

    showLoadingScreen() {
        document.getElementById('loading-screen').style.opacity = '1';
    }

    hideLoadingScreen() {
        const loadingScreen = document.getElementById('loading-screen');
        loadingScreen.style.opacity = '0';
        setTimeout(() => {
            loadingScreen.style.display = 'none';
        }, 500);
    }

    async initializeComponents() {
        // Initialize Socket Client
        this.socketClient = new SocketClient();
        
        // Setup socket event handlers
        this.socketClient.onConnectionChange = (isConnected) => {
            this.updateConnectionStatus(isConnected);
        };
        
        this.socketClient.onUserJoined = (data) => {
            this.updateParticipantsList(data.users);
        };
        
        this.socketClient.onUserLeft = (data) => {
            this.updateParticipantsList(data.users);
        };
        
        this.socketClient.onCanvasEvent = (eventData) => {
            this.canvasManager.handleRemoteEvent(eventData);
        };
        
        this.socketClient.onChatMessage = (messageData) => {
            this.addChatMessage(messageData);
        };
        
        this.socketClient.onCursorMove = (cursorData) => {
            this.canvasManager.updateRemoteCursor(
                cursorData.userId, 
                cursorData.x, 
                cursorData.y, 
                cursorData.userName
            );
        };
        
        // Initialize Canvas Manager
        this.canvasManager = new CanvasManager('collaboration-canvas');
        
        // Setup canvas event handlers
        this.canvasManager.onCanvasEvent = (eventType, data) => {
            this.socketClient.emitCanvasEvent(eventType, data);
        };
        
        this.canvasManager.onCursorMove = (x, y) => {
            this.socketClient.emitCursorMove(x, y);
        };
    }

    setupEventListeners() {
        // Join modal
        document.getElementById('join-collaboration').addEventListener('click', () => {
            this.joinCollaboration();
        });
        
        document.getElementById('username-input').addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                this.joinCollaboration();
            }
        });
        
        // Avatar selection
        document.querySelectorAll('.avatar-option').forEach(option => {
            option.addEventListener('click', (e) => {
                document.querySelectorAll('.avatar-option').forEach(opt => 
                    opt.classList.remove('selected')
                );
                e.target.classList.add('selected');
                this.userAvatar = e.target.dataset.avatar;
            });
        });
        
        // Chat
        document.getElementById('send-message').addEventListener('click', () => {
            this.sendChatMessage();
        });
        
        document.getElementById('chat-input').addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                this.sendChatMessage();
            }
        });
        
        document.getElementById('chat-toggle').addEventListener('click', () => {
            this.toggleChatPanel();
        });
        
        // Demo controls
        document.getElementById('demo-drawing').addEventListener('click', () => {
            this.startDrawingDemo();
        });
        
        document.getElementById('demo-collaboration').addEventListener('click', () => {
            this.startCollaborationDemo();
        });
        
        document.getElementById('demo-presentation').addEventListener('click', () => {
            this.startPresentationDemo();
        });
        
        // Canvas interactions for text and shape tools
        document.getElementById('collaboration-canvas').addEventListener('dblclick', (e) => {
            if (this.canvasManager.currentTool === 'text') {
                const rect = e.target.getBoundingClientRect();
                const x = e.clientX - rect.left;
                const y = e.clientY - rect.top;
                this.canvasManager.addText(x, y);
            }
        });
        
        document.getElementById('collaboration-canvas').addEventListener('click', (e) => {
            if (this.canvasManager.currentTool === 'shape') {
                const rect = e.target.getBoundingClientRect();
                const x = e.clientX - rect.left;
                const y = e.clientY - rect.top;
                
                // Show shape selection menu
                this.showShapeMenu(e.clientX, e.clientY, x, y);
            }
        });
    }

    showJoinModal() {
        document.getElementById('join-modal').style.display = 'flex';
        document.getElementById('username-input').focus();
    }

    hideJoinModal() {
        document.getElementById('join-modal').style.display = 'none';
    }

    joinCollaboration() {
        const usernameInput = document.getElementById('username-input');
        const username = usernameInput.value.trim();
        
        if (!username) {
            alert('お名前を入力してください');
            usernameInput.focus();
            return;
        }
        
        if (username.length > 20) {
            alert('お名前は20文字以内で入力してください');
            return;
        }
        
        this.userName = username;
        this.isJoined = true;
        
        // Update UI
        this.hideJoinModal();
        this.updateUserInfo();
        
        // Connect to collaboration
        this.socketClient.connect(this.userName, this.userAvatar);
        
        // Show welcome message
        this.addSystemMessage(`${this.userName}さんがコラボレーションに参加しました`);
    }

    updateUserInfo() {
        document.getElementById('user-name').textContent = this.userName;
        document.getElementById('user-avatar').textContent = this.userAvatar;
    }

    updateConnectionStatus(isConnected) {
        const indicator = document.querySelector('.status-indicator');
        const text = document.getElementById('connection-text');
        
        if (isConnected) {
            indicator.classList.remove('offline');
            indicator.classList.add('online');
            text.textContent = '接続済み';
        } else {
            indicator.classList.remove('online');
            indicator.classList.add('offline');
            text.textContent = '再接続中...';
        }
        
        this.updateUserCount();
    }

    updateUserCount() {
        const status = this.socketClient.getConnectionStatus();
        document.getElementById('user-count').textContent = status.userCount;
    }

    updateParticipantsList(users) {
        const participantsList = document.getElementById('participants-list');
        participantsList.innerHTML = '';
        
        users.forEach(user => {
            const participantDiv = document.createElement('div');
            participantDiv.className = 'participant-item';
            
            participantDiv.innerHTML = `
                <span class="participant-avatar">${user.avatar}</span>
                <span class="participant-name">${user.name}</span>
                ${user.isLocal ? '<span style="font-size: 10px; color: #3498db;">(あなた)</span>' : ''}
            `;
            
            participantsList.appendChild(participantDiv);
        });
        
        this.updateUserCount();
    }

    // Chat functionality
    sendChatMessage() {
        const input = document.getElementById('chat-input');
        const message = input.value.trim();
        
        if (!message) return;
        
        input.value = '';
        this.socketClient.sendChatMessage(message);
    }

    addChatMessage(messageData) {
        const { userId, userName, message, timestamp } = messageData;
        const messagesContainer = document.getElementById('chat-messages');
        
        const messageDiv = document.createElement('div');
        messageDiv.className = `chat-message ${userId === this.socketClient.userId ? 'own' : 'other'}`;
        
        const timeStr = new Date(timestamp).toLocaleTimeString('ja-JP', {
            hour: '2-digit',
            minute: '2-digit'
        });
        
        messageDiv.innerHTML = `
            <div class="sender">${userName}</div>
            <div class="text">${this.escapeHtml(message)}</div>
            <div class="timestamp">${timeStr}</div>
        `;
        
        messagesContainer.appendChild(messageDiv);
        messagesContainer.scrollTop = messagesContainer.scrollHeight;
        
        // Store message
        this.chatMessages.push(messageData);
        
        // Limit stored messages
        if (this.chatMessages.length > 100) {
            this.chatMessages.splice(0, 50);
        }
    }

    addSystemMessage(message) {
        const messagesContainer = document.getElementById('chat-messages');
        
        const messageDiv = document.createElement('div');
        messageDiv.className = 'chat-message system';
        messageDiv.style.cssText = `
            background: #ecf0f1;
            color: #7f8c8d;
            text-align: center;
            font-style: italic;
            font-size: 11px;
            margin: 10px auto;
            max-width: 90%;
        `;
        
        messageDiv.innerHTML = `<div class="text">${this.escapeHtml(message)}</div>`;
        
        messagesContainer.appendChild(messageDiv);
        messagesContainer.scrollTop = messagesContainer.scrollHeight;
    }

    toggleChatPanel() {
        const chatPanel = document.getElementById('chat-panel');
        const isHidden = chatPanel.style.transform === 'translateX(100%)';
        
        if (isHidden) {
            chatPanel.style.transform = 'translateX(0)';
            document.getElementById('chat-toggle').textContent = '✖️';
        } else {
            chatPanel.style.transform = 'translateX(100%)';
            document.getElementById('chat-toggle').textContent = '💬';
        }
    }

    // Shape menu
    showShapeMenu(screenX, screenY, canvasX, canvasY) {
        const menu = document.createElement('div');
        menu.className = 'shape-menu';
        menu.style.cssText = `
            position: fixed;
            left: ${screenX}px;
            top: ${screenY}px;
            background: white;
            border: 1px solid #ddd;
            border-radius: 5px;
            padding: 10px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.2);
            z-index: 1000;
            display: flex;
            gap: 10px;
        `;
        
        const shapes = [
            { type: 'rectangle', label: '⬜', title: '四角形' },
            { type: 'circle', label: '⭕', title: '円' },
            { type: 'triangle', label: '🔺', title: '三角形' }
        ];
        
        shapes.forEach(shape => {
            const button = document.createElement('button');
            button.textContent = shape.label;
            button.title = shape.title;
            button.style.cssText = `
                padding: 8px;
                border: none;
                border-radius: 3px;
                background: #f8f9fa;
                cursor: pointer;
                font-size: 16px;
            `;
            
            button.addEventListener('click', () => {
                this.canvasManager.addShape(shape.type, canvasX, canvasY);
                menu.remove();
            });
            
            menu.appendChild(button);
        });
        
        document.body.appendChild(menu);
        
        // Remove menu when clicking outside
        setTimeout(() => {
            const handleClickOutside = (e) => {
                if (!menu.contains(e.target)) {
                    menu.remove();
                    document.removeEventListener('click', handleClickOutside);
                }
            };
            document.addEventListener('click', handleClickOutside);
        }, 100);
    }

    // Demo functionality
    startDrawingDemo() {
        this.addSystemMessage('描画デモを開始します...');
        this.socketClient.startDrawingDemo();
        
        // Local demo actions
        setTimeout(() => {
            this.canvasManager.addText(50, 50, '描画デモ実行中!');
        }, 1000);
        
        setTimeout(() => {
            this.addSystemMessage('描画デモが完了しました');
        }, 8000);
    }

    startCollaborationDemo() {
        this.addSystemMessage('コラボレーションデモを開始します...');
        this.socketClient.startCollaborationDemo();
        
        setTimeout(() => {
            this.addSystemMessage('複数ユーザーによるリアルタイム共同編集をご覧ください');
        }, 2000);
        
        setTimeout(() => {
            this.addSystemMessage('コラボレーションデモが完了しました');
        }, 10000);
    }

    startPresentationDemo() {
        this.addSystemMessage('プレゼンテーションデモを開始します...');
        
        // Presentation mode simulation
        const presentationSteps = [
            () => {
                this.canvasManager.addText(100, 80, '企業概要', '24px');
                this.addSystemMessage('セクション1: 企業概要');
            },
            () => {
                this.canvasManager.addShape('rectangle', 50, 150);
                this.canvasManager.addText(200, 180, '革新的IT企業');
                this.addSystemMessage('セクション2: 技術力');
            },
            () => {
                this.canvasManager.addShape('circle', 100, 300);
                this.canvasManager.addText(250, 320, 'リアルタイム\nコラボレーション');
                this.addSystemMessage('セクション3: ソリューション');
            },
            () => {
                this.addSystemMessage('プレゼンテーションデモが完了しました');
            }
        ];
        
        presentationSteps.forEach((step, index) => {
            setTimeout(step, (index + 1) * 3000);
        });
    }

    // Utility functions
    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    // Analytics and tracking
    trackUserAction(action, data = {}) {
        const eventData = {
            action,
            userId: this.socketClient?.userId,
            userName: this.userName,
            timestamp: new Date().toISOString(),
            ...data
        };
        
        console.log('User Action:', eventData);
        // Here you would send data to analytics service
    }

    // Cleanup
    destroy() {
        if (this.socketClient) {
            this.socketClient.disconnect();
        }
        
        // Clean up event listeners
        window.removeEventListener('resize', this.canvasManager?.resizeCanvas);
        
        // Clear intervals/timeouts
        // (if any were set)
    }
}

// Initialize the app when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.collaborationApp = new CollaborationApp();
});

// Handle page unload
window.addEventListener('beforeunload', () => {
    if (window.collaborationApp) {
        window.collaborationApp.destroy();
    }
});