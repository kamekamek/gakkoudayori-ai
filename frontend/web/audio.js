// 学級通信AI - 音声録音機能 (Phase R2)
// Web Audio API を使用したシンプルな音声録音

class AudioRecorder {
    constructor() {
        this.mediaRecorder = null;
        this.audioChunks = [];
        this.isRecording = false;
        this.stream = null;
        
        // 初期化ログ
        console.log('🎤 AudioRecorder初期化 - isRecording:', this.isRecording);
        
        // 強制リセット（前回のセッションの状態をクリア）
        this.forceReset();
    }
    
    // 強制状態リセット
    forceReset() {
        this.isRecording = false;
        this.audioChunks = [];
        if (this.mediaRecorder) {
            this.mediaRecorder = null;
        }
        if (this.stream) {
            this.stream.getTracks().forEach(track => track.stop());
            this.stream = null;
        }
        console.log('🔄 AudioRecorder状態リセット完了');
    }

    // マイクアクセス許可を取得
    async requestMicrophoneAccess() {
        try {
            this.stream = await navigator.mediaDevices.getUserMedia({ 
                audio: {
                    sampleRate: 16000,    // Speech-to-Text最適化
                    channelCount: 1,      // モノラル
                    echoCancellation: true,
                    noiseSuppression: true
                } 
            });
            console.log('🎤 マイクアクセス許可取得成功');
            return true;
        } catch (error) {
            console.error('❌ マイクアクセス拒否:', error);
            return false;
        }
    }

    // 録音開始
    async startRecording() {
        console.log('🎤 録音開始処理開始 - 現在の状態:', this.isRecording);
        
        if (this.isRecording) {
            console.warn('⚠️ 既に録音中です');
            return true; // 既に録音中の場合もtrueを返す（状態不整合を防ぐ）
        }

        try {
            // マイクアクセス確認
            if (!this.stream) {
                const accessGranted = await this.requestMicrophoneAccess();
                if (!accessGranted) {
                    throw new Error('マイクアクセスが必要です');
                }
            }

            // MediaRecorder設定（ブラウザ対応形式）
            const candidateTypes = [
                'audio/webm;codecs=opus',
                'audio/webm',
                'audio/mp4',
                'audio/wav',
                '' // 最終フォールバック（ブラウザデフォルト）
            ];
            
            let mimeType = '';
            for (const type of candidateTypes) {
                console.log(`🔍 MIMEタイプテスト: "${type}" -> ${MediaRecorder.isTypeSupported(type)}`);
                if (type === '' || MediaRecorder.isTypeSupported(type)) {
                    mimeType = type;
                    break;
                }
            }
            
            console.log('🎙️ 選択されたMIMEタイプ:', `"${mimeType}"`);
            
            // MediaRecorder初期化（MIMEタイプ指定条件分岐）
            if (mimeType === '') {
                // ブラウザデフォルト設定
                this.mediaRecorder = new MediaRecorder(this.stream);
                console.log('🎙️ ブラウザデフォルト設定で初期化');
            } else {
                // 明示的MIMEタイプ指定
                this.mediaRecorder = new MediaRecorder(this.stream, {
                    mimeType: mimeType
                });
                console.log('🎙️ 指定MIMEタイプで初期化:', mimeType);
            }

            this.audioChunks = [];

            // 録音データイベント
            this.mediaRecorder.ondataavailable = (event) => {
                if (event.data.size > 0) {
                    this.audioChunks.push(event.data);
                }
            };

            // 録音完了イベント
            this.mediaRecorder.onstop = () => {
                // 実際のMIMEタイプを取得（MediaRecorderから）
                const actualMimeType = this.mediaRecorder.mimeType || mimeType || 'audio/webm';
                console.log('🎤 録音完了 - 実際のMIMEタイプ:', actualMimeType);
                
                const audioBlob = new Blob(this.audioChunks, { type: actualMimeType });
                this.onRecordingComplete(audioBlob);
            };

            // 録音開始
            this.mediaRecorder.start();
            this.isRecording = true;
            console.log('🎤 録音開始成功 - 新しい状態:', this.isRecording);
            
            // Flutter側に通知
            if (window.flutter_inappwebview) {
                window.flutter_inappwebview.callHandler('onRecordingStarted');
            }

            console.log('✅ startRecording: true を返します');
            return true;
        } catch (error) {
            console.error('❌ 録音開始エラー:', error);
            this.isRecording = false; // エラー時は確実にfalseに戻す
            console.log('❌ startRecording: false を返します');
            return false;
        }
    }

    // 録音停止
    stopRecording() {
        if (!this.isRecording || !this.mediaRecorder) {
            console.warn('⚠️ 録音中ではありません');
            return false;
        }

        this.mediaRecorder.stop();
        this.isRecording = false;
        console.log('⏹️ 録音停止');

        // Flutter側に通知
        if (window.flutter_inappwebview) {
            window.flutter_inappwebview.callHandler('onRecordingStopped');
        }

        return true;
    }

    // 録音完了処理
    onRecordingComplete(audioBlob) {
        console.log('✅ 録音完了:', audioBlob.size, 'bytes');
        
        // Base64変換
        const reader = new FileReader();
        reader.onload = () => {
            const audioBase64 = reader.result.split(',')[1]; // data:audio/wav;base64, を除去
            
            // Flutter側に音声データを送信
            if (window.flutter_inappwebview) {
                window.flutter_inappwebview.callHandler('onAudioRecorded', {
                    audioData: audioBase64,
                    size: audioBlob.size,
                    duration: this.getRecordingDuration()
                });
            }

            // デバッグ用：音声ファイルダウンロード
            this.downloadAudio(audioBlob);
        };
        reader.readAsDataURL(audioBlob);
    }

    // 録音時間取得（概算）
    getRecordingDuration() {
        return this.audioChunks.length * 100; // ms（概算）
    }

    // デバッグ用：音声ファイルダウンロード
    downloadAudio(audioBlob) {
        const url = URL.createObjectURL(audioBlob);
        const a = document.createElement('a');
        a.href = url;
        
        // MIMEタイプに応じて拡張子を決定
        let extension = 'webm';
        if (audioBlob.type.includes('mp4')) {
            extension = 'mp4';
        } else if (audioBlob.type.includes('wav')) {
            extension = 'wav';
        }
        
        a.download = `recording_${Date.now()}.${extension}`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
        console.log('💾 音声ファイルダウンロード完了:', a.download);
    }

    // リソース解放
    cleanup() {
        if (this.stream) {
            this.stream.getTracks().forEach(track => track.stop());
            this.stream = null;
        }
        this.mediaRecorder = null;
        this.audioChunks = [];
        this.isRecording = false;
        console.log('🧹 AudioRecorderクリーンアップ完了');
    }
}

// グローバルインスタンス
window.audioRecorder = new AudioRecorder();

// Flutter側からの呼び出し用関数
window.startRecording = async () => {
    console.log('🔗 JavaScript Bridge: startRecording開始');
    try {
        console.log('🔗 現在の録音状態（Bridge呼び出し前）:', window.audioRecorder.isRecording);
        const result = await window.audioRecorder.startRecording();
        console.log('🔗 startRecording実行完了 - result:', result);
        console.log('🔗 現在の録音状態（Bridge呼び出し後）:', window.audioRecorder.isRecording);
        console.log('🔗 JavaScript Bridge: startRecording result =', result);
        return result;
    } catch (error) {
        console.error('❌ JavaScript Bridge: startRecording error =', error);
        return false;
    }
};

window.stopRecording = () => {
    try {
        const result = window.audioRecorder.stopRecording();
        console.log('🔗 JavaScript Bridge: stopRecording result =', result);
        return result;
    } catch (error) {
        console.error('❌ JavaScript Bridge: stopRecording error =', error);
        return false;
    }
};

window.isRecording = () => window.audioRecorder.isRecording;

// デバッグ用：強制リセット関数
window.resetAudioRecorder = () => {
    console.log('🔄 手動リセット実行');
    window.audioRecorder.forceReset();
    return 'AudioRecorder reset completed';
};

// デバッグ用：状態確認関数
window.getAudioRecorderStatus = () => {
    const status = {
        isRecording: window.audioRecorder.isRecording,
        hasStream: !!window.audioRecorder.stream,
        hasMediaRecorder: !!window.audioRecorder.mediaRecorder,
        audioChunksLength: window.audioRecorder.audioChunks.length
    };
    console.log('📊 AudioRecorder状態:', status);
    return status;
};

console.log('🎤 Audio Recorder初期化完了 (Phase R2 - Enhanced Debug)'); 