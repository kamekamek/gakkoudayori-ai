// 学級通信AI - 音声録音機能 (Phase R2)
// Web Audio API を使用したシンプルな音声録音

class AudioRecorder {
    constructor() {
        this.mediaRecorder = null;
        this.audioChunks = [];
        this.isRecording = false;
        this.stream = null;
        this.isIOS = this.detectIOS();
        this.audioContext = null;
        this.scriptProcessor = null;
        
        // 初期化ログ
        console.log('🎤 AudioRecorder初期化 - isRecording:', this.isRecording);
        console.log('📱 iOS検出:', this.isIOS);
        console.log('🎙️ MediaRecorder対応:', !!window.MediaRecorder);
        
        // 強制リセット（前回のセッションの状態をクリア）
        this.forceReset();
    }
    
    // iOS検出
    detectIOS() {
        const userAgent = navigator.userAgent;
        return /iPad|iPhone|iPod/.test(userAgent) && !window.MSStream;
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
            // iOS用の設定
            const constraints = this.isIOS ? {
                audio: {
                    echoCancellation: true,
                    noiseSuppression: true,
                    autoGainControl: true
                }
            } : {
                audio: {
                    sampleRate: 16000,    // Speech-to-Text最適化（16kHzに統一）
                    channelCount: 1,      // モノラル
                    echoCancellation: true,
                    noiseSuppression: true
                }
            };
            
            // ブラウザ互換性チェック
            if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
                throw new Error('このブラウザは音声録音に対応していません');
            }
            
            // HTTPSチェック（iOS必須）
            if (this.isIOS && location.protocol !== 'https:' && location.hostname !== 'localhost') {
                throw new Error('iOSでは音声録音にHTTPS接続が必要です');
            }
            
            this.stream = await navigator.mediaDevices.getUserMedia(constraints);
            console.log('🎤 マイクアクセス許可取得成功');
            console.log('📊 ストリーム情報:', {
                tracks: this.stream.getAudioTracks().length,
                settings: this.stream.getAudioTracks()[0]?.getSettings()
            });
            return true;
        } catch (error) {
            console.error('❌ マイクアクセス拒否:', error);
            return false;
        }
    }

    // 録音開始
    async startRecording() {
        console.log('🎤 録音開始処理開始 - 現在の状態:', this.isRecording);
        console.log('📱 iOS判定:', this.isIOS);
        
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

            // iOS対応: Web Audio APIによる録音、その他: MediaRecorder
            if (this.isIOS || !window.MediaRecorder) {
                console.log('📱 iOS/非対応ブラウザ検出 - Web Audio API使用');
                return await this.startWebAudioRecording();
            } else {
                console.log('🖥️ デスクトップブラウザ - MediaRecorder使用');
                return await this.startMediaRecorderRecording();
            }
        } catch (error) {
            console.error('❌ 録音開始エラー:', error);
            this.isRecording = false; // エラー時は確実にfalseに戻す
            console.log('❌ startRecording: false を返します');
            return false;
        }
    }
    
    // MediaRecorder録音（従来の方式）
    async startMediaRecorderRecording() {
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
        console.log('🎤 MediaRecorder録音開始成功');
        
        // Flutter側に通知
        if (window.onRecordingStarted) {
            console.log('🔗 [AudioRecorder] Flutter側に録音開始通知送信');
            window.onRecordingStarted();
        }

        return true;
    }
    
    // Web Audio API録音（iOS対応）
    async startWebAudioRecording() {
        try {
            // Web Audio Context作成
            const AudioContext = window.AudioContext || window.webkitAudioContext;
            if (!AudioContext) {
                throw new Error('Web Audio API未対応');
            }
            
            this.audioContext = new AudioContext();
            const source = this.audioContext.createMediaStreamSource(this.stream);
            
            // iOS Safari用の特別処理
            if (this.audioContext.state === 'suspended') {
                console.log('🔊 AudioContext resume中...');
                await this.audioContext.resume();
            }
            
            // ScriptProcessorNode作成（iOS互換性）
            const bufferSize = 4096;
            this.scriptProcessor = this.audioContext.createScriptProcessor(bufferSize, 1, 1);
            
            this.audioChunks = [];
            this.recordingStartTime = Date.now();
            
            // 音声データ処理
            this.scriptProcessor.onaudioprocess = (event) => {
                if (!this.isRecording) return;
                
                const inputData = event.inputBuffer.getChannelData(0);
                const audioData = new Float32Array(inputData);
                this.audioChunks.push(audioData);
            };
            
            // 音声処理チェーン接続
            source.connect(this.scriptProcessor);
            this.scriptProcessor.connect(this.audioContext.destination);
            
            this.isRecording = true;
            console.log('🎤 Web Audio API録音開始成功');
            
            // Flutter側に通知
            if (window.onRecordingStarted) {
                console.log('🔗 [AudioRecorder] Flutter側に録音開始通知送信');
                window.onRecordingStarted();
            }
            
            // 音声レベル監視開始
            this.startAudioLevelMonitoring();
            
            return true;
        } catch (error) {
            console.error('❌ Web Audio API録音エラー:', error);
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
        if (!this.isRecording) {
            console.warn('⚠️ 録音中ではありません');
            return false;
        }

        this.isRecording = false;
        console.log('⏹️ 録音停止開始');

        // MediaRecorder使用時
        if (this.mediaRecorder) {
            this.mediaRecorder.stop();
            console.log('⏹️ MediaRecorder停止');
        }
        
        // Web Audio API使用時（iOS）
        if (this.scriptProcessor && this.audioContext) {
            console.log('⏹️ Web Audio API停止開始');
            this.stopWebAudioRecording();
        }

        // Flutter側に通知
        if (window.onRecordingStopped) {
            console.log('🔗 [AudioRecorder] Flutter側に録音停止通知送信');
            window.onRecordingStopped();
        } else {
            console.log('⚠️ [AudioRecorder] onRecordingStopped コールバックが未設定');
        }

        return true;
    }
    
    // Web Audio API録音停止（iOS対応）
    stopWebAudioRecording() {
        try {
            // ScriptProcessor切断
            if (this.scriptProcessor) {
                this.scriptProcessor.disconnect();
                this.scriptProcessor = null;
            }
            
            // 録音時間計算
            const recordingDuration = Date.now() - this.recordingStartTime;
            console.log('⏹️ Web Audio API録音完了 - 時間:', recordingDuration + 'ms');
            
            // Float32ArrayからWAVファイル作成
            if (this.audioChunks.length > 0) {
                const audioBlob = this.convertFloat32ArrayToWav(this.audioChunks, 48000);
                this.onRecordingComplete(audioBlob);
            } else {
                console.warn('⚠️ 録音データが空です');
            }
            
            // AudioContext切断（リソース解放）
            if (this.audioContext) {
                this.audioContext.close();
                this.audioContext = null;
            }
        } catch (error) {
            console.error('❌ Web Audio API停止エラー:', error);
        }
    }
    
    // Float32ArrayをWAVファイルに変換（iOS対応）
    convertFloat32ArrayToWav(audioChunks, sampleRate) {
        // 全チャンクを1つの配列に結合
        const totalLength = audioChunks.reduce((sum, chunk) => sum + chunk.length, 0);
        const mergedArray = new Float32Array(totalLength);
        let offset = 0;
        
        for (const chunk of audioChunks) {
            mergedArray.set(chunk, offset);
            offset += chunk.length;
        }
        
        // Float32をInt16に変換
        const int16Array = new Int16Array(mergedArray.length);
        for (let i = 0; i < mergedArray.length; i++) {
            int16Array[i] = Math.max(-32768, Math.min(32767, Math.floor(mergedArray[i] * 32767)));
        }
        
        // WAVヘッダー作成
        const wavHeader = this.createWavHeader(int16Array.length, sampleRate);
        const wavBuffer = new ArrayBuffer(wavHeader.length + int16Array.byteLength);
        const view = new Uint8Array(wavBuffer);
        
        // ヘッダー + 音声データ結合
        view.set(wavHeader, 0);
        view.set(new Uint8Array(int16Array.buffer), wavHeader.length);
        
        console.log('🎵 WAV変換完了:', wavBuffer.byteLength + 'bytes');
        return new Blob([wavBuffer], { type: 'audio/wav' });
    }
    
    // WAVヘッダー作成
    createWavHeader(dataLength, sampleRate) {
        const header = new ArrayBuffer(44);
        const view = new DataView(header);
        
        const writeString = (offset, string) => {
            for (let i = 0; i < string.length; i++) {
                view.setUint8(offset + i, string.charCodeAt(i));
            }
        };
        
        writeString(0, 'RIFF');
        view.setUint32(4, 36 + dataLength * 2, true);
        writeString(8, 'WAVE');
        writeString(12, 'fmt ');
        view.setUint32(16, 16, true);
        view.setUint16(20, 1, true);
        view.setUint16(22, 1, true);
        view.setUint32(24, sampleRate, true);
        view.setUint32(28, sampleRate * 2, true);
        view.setUint16(32, 2, true);
        view.setUint16(34, 16, true);
        writeString(36, 'data');
        view.setUint32(40, dataLength * 2, true);
        
        return new Uint8Array(header);
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

            // デバッグ用：音声ファイルダウンロード（無効化）
            // this.downloadAudio(audioBlob);
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