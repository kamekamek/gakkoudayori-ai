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
                    sampleRate: 16000,    // Speech-to-Text最適化（16kHzに統一）
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
            
            // 音声レベル監視開始
            this.startAudioLevelMonitoring();

            // 録音開始
            this.mediaRecorder.start();
            this.isRecording = true;
            console.log('🎤 録音開始成功 - 新しい状態:', this.isRecording);
            
            // Flutter側に通知（正しいコールバック関数を使用）
            if (window.onRecordingStarted) {
                            console.log('🔗 [AudioRecorder] Flutter側に録音開始通知送信');
            window.onRecordingStarted();
        } else {
            console.log('⚠️ [AudioRecorder] onRecordingStarted コールバックが未設定');
        }

        // 音声レベル監視開始
        this.startAudioLevelMonitoring();

        console.log('✅ startRecording: true を返します');
        return true;
        } catch (error) {
            console.error('❌ 録音開始エラー:', error);
            this.isRecording = false; // エラー時は確実にfalseに戻す
            console.log('❌ startRecording: false を返します');
            return false;
        }
    }

    // 音声レベル監視開始
    startAudioLevelMonitoring() {
        if (!this.stream) return;
        
        // オーディオコンテキスト作成
        const audioContext = new (window.AudioContext || window.webkitAudioContext)();
        const source = audioContext.createMediaStreamSource(this.stream);
        const analyser = audioContext.createAnalyser();
        
        analyser.fftSize = 512;  // より高精度に
        const bufferLength = analyser.frequencyBinCount;
        const dataArray = new Uint8Array(bufferLength);
        
        source.connect(analyser);
        
        console.log('🎙️ 音声レベル監視開始（感度アップ版）');
        
        // 音声レベル監視ループ
        const monitorLevel = () => {
            if (!this.isRecording) return;
            
            analyser.getByteFrequencyData(dataArray);
            
            // 平均音量計算
            let sum = 0;
            for (let i = 0; i < bufferLength; i++) {
                sum += dataArray[i];
            }
            const average = sum / bufferLength;
            
            // 音声レベルをコンソールに表示（感度を大幅アップ）
            if (average > 1) {  // 閾値を20→1に下げて超敏感に
                const level = Math.min(5, Math.floor(average / 10));  // 30→10に変更
                const bars = '█'.repeat(level) + '░'.repeat(5 - level);
                console.log(`🎙️ 音声レベル: ${bars} (${Math.round(average)}) ${average > 15 ? '🔊' : average > 5 ? '🔉' : '🔈'}`);
            } else if (average > 0.1) {
                console.log(`🎙️ 微弱音声検出: ${Math.round(average * 10)/10} (マイクはアクティブ)`);
            }
            
            setTimeout(monitorLevel, 300); // 0.3秒間隔で頻繁チェック
        };
        
        monitorLevel();
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

        // Flutter側に通知（正しいコールバック関数を使用）
        if (window.onRecordingStopped) {
            console.log('🔗 [AudioRecorder] Flutter側に録音停止通知送信');
            window.onRecordingStopped();
        } else {
            console.log('⚠️ [AudioRecorder] onRecordingStopped コールバックが未設定');
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
            
            // Flutter側に音声データを送信（正しいコールバック関数を使用）
            if (window.onAudioRecorded) {
                console.log('🔗 [AudioRecorder] Flutter側に音声データ送信');
                window.onAudioRecorded({
                    audioData: audioBase64,
                    size: audioBlob.size,
                    duration: this.getRecordingDuration()
                });
            } else {
                console.log('⚠️ [AudioRecorder] onAudioRecorded コールバックが未設定');
            }

            // デバッグ用：音声ファイルダウンロード（一時的に有効化）
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
        
        // 確実にboolean値を返す
        const finalResult = result === true;
        console.log('🔗 JavaScript Bridge: startRecording final result =', finalResult);
        
        return finalResult;
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