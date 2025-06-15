class AIConciergePlatform {
    constructor() {
        this.sceneManager = null;
        this.chatMessages = [];
        this.isVoiceEnabled = false;
        this.recognition = null;
        this.synthesis = null;
        
        this.init();
    }

    async init() {
        this.showLoadingScreen();
        
        // Initialize components
        await this.initializeScene();
        this.initializeChat();
        this.initializeVoice();
        this.setupEventListeners();
        
        // Hide loading screen
        setTimeout(() => {
            this.hideLoadingScreen();
            this.showWelcomeMessage();
        }, 2000);
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

    async initializeScene() {
        this.sceneManager = new SceneManager();
    }

    initializeChat() {
        const chatInput = document.getElementById('chat-input');
        const sendBtn = document.getElementById('send-btn');
        const messagesContainer = document.getElementById('chat-messages');

        // Enter key handler
        chatInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                this.sendMessage();
            }
        });

        // Send button handler
        sendBtn.addEventListener('click', () => {
            this.sendMessage();
        });
    }

    initializeVoice() {
        // Speech Recognition
        if ('webkitSpeechRecognition' in window || 'SpeechRecognition' in window) {
            const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
            this.recognition = new SpeechRecognition();
            this.recognition.continuous = false;
            this.recognition.interimResults = false;
            this.recognition.lang = 'ja-JP';

            this.recognition.onresult = (event) => {
                const transcript = event.results[0][0].transcript;
                document.getElementById('chat-input').value = transcript;
                this.sendMessage();
            };

            this.recognition.onerror = (event) => {
                console.error('Speech recognition error:', event.error);
                this.updateStatus('音声認識エラーが発生しました');
            };
        }

        // Speech Synthesis
        if ('speechSynthesis' in window) {
            this.synthesis = window.speechSynthesis;
        }
    }

    setupEventListeners() {
        // Voice button
        document.getElementById('voice-btn').addEventListener('click', () => {
            this.toggleVoiceInput();
        });

        // Control buttons
        document.getElementById('tour-btn').addEventListener('click', () => {
            this.startVirtualTour();
        });

        document.getElementById('demo-btn').addEventListener('click', () => {
            this.showTechDemo();
        });

        document.getElementById('contact-btn').addEventListener('click', () => {
            this.showContactForm();
        });

        // XR button
        document.getElementById('xr-btn').addEventListener('click', () => {
            this.startXRExperience();
        });
    }

    async sendMessage() {
        const input = document.getElementById('chat-input');
        const message = input.value.trim();
        
        if (!message) return;

        // Clear input
        input.value = '';

        // Add user message
        this.addMessage(message, 'user');

        // Update AI status
        this.updateStatus('考え中...');

        try {
            // Get AI response
            const response = await aiEngine.processMessage(message);
            
            // Add AI response
            setTimeout(() => {
                this.addMessage(response, 'ai');
                this.updateStatus('お聞きください');
                
                // Text-to-speech for AI response
                if (this.synthesis) {
                    this.speakText(response);
                }
            }, 500);

        } catch (error) {
            console.error('AI processing error:', error);
            this.addMessage('申し訳ございません。システムエラーが発生しました。', 'ai');
            this.updateStatus('エラーが発生しました');
        }
    }

    addMessage(text, sender) {
        const messagesContainer = document.getElementById('chat-messages');
        const messageDiv = document.createElement('div');
        messageDiv.className = `message ${sender}-message`;
        messageDiv.textContent = text;
        
        messagesContainer.appendChild(messageDiv);
        messagesContainer.scrollTop = messagesContainer.scrollHeight;

        // Store message
        this.chatMessages.push({ text, sender, timestamp: new Date() });
    }

    updateStatus(status) {
        document.querySelector('.status').textContent = status;
    }

    showWelcomeMessage() {
        const welcomeMessage = aiEngine.getPersonalizedGreeting();
        setTimeout(() => {
            this.addMessage(welcomeMessage, 'ai');
            this.updateStatus('お聞きください');
            
            if (this.synthesis) {
                this.speakText(welcomeMessage);
            }
        }, 1000);
    }

    toggleVoiceInput() {
        if (!this.recognition) {
            alert('音声認識がサポートされていません');
            return;
        }

        if (this.isVoiceEnabled) {
            this.recognition.stop();
            this.isVoiceEnabled = false;
            document.getElementById('voice-btn').textContent = '🎤';
            this.updateStatus('お聞きください');
        } else {
            this.recognition.start();
            this.isVoiceEnabled = true;
            document.getElementById('voice-btn').textContent = '⏹️';
            this.updateStatus('お話しください...');
        }
    }

    speakText(text) {
        if (!this.synthesis) return;

        // Cancel any ongoing speech
        this.synthesis.cancel();

        const utterance = new SpeechSynthesisUtterance(text);
        utterance.lang = 'ja-JP';
        utterance.rate = 1.0;
        utterance.pitch = 1.0;
        utterance.volume = 0.8;

        // Find Japanese voice if available
        const voices = this.synthesis.getVoices();
        const japaneseVoice = voices.find(voice => 
            voice.lang.includes('ja') || voice.name.includes('Japanese')
        );
        
        if (japaneseVoice) {
            utterance.voice = japaneseVoice;
        }

        this.synthesis.speak(utterance);
    }

    startVirtualTour() {
        this.addMessage('バーチャル見学を開始します！', 'ai');
        this.updateStatus('見学中...');
        
        if (this.sceneManager) {
            this.sceneManager.startVirtualTour();
        }

        setTimeout(() => {
            this.addMessage('見学はいかがでしたか？他にもご質問があればお聞かせください。', 'ai');
            this.updateStatus('お聞きください');
        }, 15000);
    }

    showTechDemo() {
        this.addMessage('技術デモンストレーションを開始します！', 'ai');
        this.updateStatus('デモ実行中...');
        
        if (this.sceneManager) {
            this.sceneManager.showTechDemo();
        }

        setTimeout(() => {
            this.addMessage('弊社の技術力はいかがでしたか？具体的なプロジェクトのご相談もお待ちしています。', 'ai');
            this.updateStatus('お聞きください');
        }, 10000);
    }

    showContactForm() {
        const contactMessage = `
お問い合わせありがとうございます！以下の方法でご連絡いただけます：

✉️ Email: info@innovative-it.co.jp
📞 Tel: 03-1234-5678
🌐 Web: https://innovative-it.co.jp/contact
📅 オンライン相談会: 随時開催中

初回コンサルテーションは無料です。お気軽にどうぞ！
        `;
        
        this.addMessage(contactMessage.trim(), 'ai');
        
        if (this.synthesis) {
            this.speakText('お問い合わせ情報を表示しました。ご確認ください。');
        }
    }

    async startXRExperience() {
        if (!this.sceneManager.isXRSupported) {
            alert('XR体験がサポートされていません');
            return;
        }

        try {
            this.addMessage('VR体験を開始します...', 'ai');
            this.updateStatus('VR準備中...');
            
            // XR session setup would go here
            // This is a simplified example
            alert('VR体験機能は開発中です。近日公開予定！');
            
        } catch (error) {
            console.error('XR initialization error:', error);
            alert('VR体験の開始に失敗しました');
        }
    }

    // Analytics and tracking
    trackUserInteraction(action, data = {}) {
        const eventData = {
            action,
            timestamp: new Date().toISOString(),
            userAgent: navigator.userAgent,
            ...data
        };
        
        console.log('User Interaction:', eventData);
        
        // Here you would send data to analytics service
        // Example: analytics.track(eventData);
    }

    // Cleanup
    destroy() {
        if (this.sceneManager) {
            this.sceneManager.dispose();
        }
        
        if (this.recognition) {
            this.recognition.stop();
        }
        
        if (this.synthesis) {
            this.synthesis.cancel();
        }
    }
}

// Initialize the platform when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.aiConciergePlatform = new AIConciergePlatform();
});

// Handle page unload
window.addEventListener('beforeunload', () => {
    if (window.aiConciergePlatform) {
        window.aiConciergePlatform.destroy();
    }
});