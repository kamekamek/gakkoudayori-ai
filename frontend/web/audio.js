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
        this.audioWorkletNode = null;
        
        // 初期化ログ
        console.log('🎤 AudioRecorder初期化 - isRecording:', this.isRecording);
        console.log('📱 iOS検出:', this.isIOS);
        console.log('🎙️ MediaRecorder対応:', !!window.MediaRecorder);
        
        // 強制リセット（前回のセッションの状態をクリア）
        this.forceReset();
    }
    
    // iOS検出（iOS 18.5対応強化）
    detectIOS() {
        const userAgent = navigator.userAgent;
        const isIOS = /iPad|iPhone|iPod/.test(userAgent) && !window.MSStream;
        
        if (isIOS) {
            // iOS バージョン検出
            const versionMatch = userAgent.match(/OS (\d+)_(\d+)_?(\d+)?/);
            if (versionMatch) {
                const majorVersion = parseInt(versionMatch[1]);
                const minorVersion = parseInt(versionMatch[2]);
                console.log(`📱 iOS ${majorVersion}.${minorVersion} 検出`);
                
                // iOS 18.5以降でScriptProcessorNode廃止警告
                if (majorVersion >= 18 && minorVersion >= 5) {
                    console.warn('⚠️ iOS 18.5+ 検出 - ScriptProcessorNode廃止対象');
                }
            }
        }
        
        return isIOS;
    }
    
    // 強制状態リセット
    forceReset() {
        this.isRecording = false;
        this.audioChunks = [];
        
        if (this.mediaRecorder) {
            this.mediaRecorder = null;
        }
        
        if (this.audioWorkletNode) {
            this.audioWorkletNode.disconnect();
            this.audioWorkletNode = null;
        }
        
        if (this.scriptProcessor) {
            this.scriptProcessor.disconnect();
            this.scriptProcessor = null;
        }
        
        if (this.audioContext) {
            this.audioContext.close();
            this.audioContext = null;
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
            console.log('🎤 マイクアクセス許可要求開始...');
            console.log('🌍 現在のURL:', location.href);
            console.log('🔒 プロトコル:', location.protocol);
            console.log('📱 iOS判定:', this.isIOS);
            
            // ブラウザ互換性チェック
            if (!navigator.mediaDevices) {
                throw new Error('navigator.mediaDevices が利用できません');
            }
            
            if (!navigator.mediaDevices.getUserMedia) {
                throw new Error('navigator.mediaDevices.getUserMedia が利用できません');
            }
            
            console.log('✅ ブラウザ互換性チェック通過');
            
            // HTTPSチェック（iOS必須）
            if (this.isIOS && location.protocol !== 'https:' && location.hostname !== 'localhost') {
                throw new Error('iOSでは音声録音にHTTPS接続が必要です');
            }
            
            // シンプルな制約から開始
            let constraints = { audio: true };
            
            console.log('🎙️ getUserMedia呼び出し中... 制約:', constraints);
            this.stream = await navigator.mediaDevices.getUserMedia(constraints);
            
            console.log('✅ getUserMedia成功!');
            console.log('📊 ストリーム情報:', {
                id: this.stream.id,
                active: this.stream.active,
                tracks: this.stream.getAudioTracks().length,
                trackInfo: this.stream.getAudioTracks().map(track => ({
                    id: track.id,
                    kind: track.kind,
                    label: track.label,
                    enabled: track.enabled,
                    muted: track.muted,
                    readyState: track.readyState,
                    settings: track.getSettings ? track.getSettings() : 'getSettings未対応'
                }))
            });
            
            return true;
        } catch (error) {
            console.error('❌ マイクアクセス失敗:');
            console.error('  - エラー名:', error.name);
            console.error('  - エラーメッセージ:', error.message);
            console.error('  - スタック:', error.stack);
            
            // 具体的なエラー情報を提供
            if (error.name === 'NotAllowedError') {
                console.error('  → ユーザーがマイクアクセスを拒否しました');
            } else if (error.name === 'NotFoundError') {
                console.error('  → マイクデバイスが見つかりません');
            } else if (error.name === 'NotReadableError') {
                console.error('  → マイクデバイスが他のアプリケーションで使用中です');
            } else if (error.name === 'OverconstrainedError') {
                console.error('  → 指定された制約を満たすデバイスがありません');
            } else if (error.name === 'TypeError') {
                console.error('  → 制約の形式が間違っています');
            } else if (error.name === 'SecurityError') {
                console.error('  → セキュリティエラー（HTTPS必須など）');
            }
            
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
    
    // Web Audio API録音（iOS対応 - AudioWorkletNode使用）
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
            
            // AudioWorkletNode対応チェック
            if (!this.audioContext.audioWorklet) {
                console.warn('⚠️ AudioWorklet未対応 - ScriptProcessorNodeフォールバック');
                return await this.startWebAudioRecordingLegacy();
            }
            
            try {
                // AudioWorkletProcessor読み込み
                await this.audioContext.audioWorklet.addModule('./audio-processor.js');
                console.log('✅ AudioWorkletProcessor読み込み完了');
                
                // AudioWorkletNode作成
                this.audioWorkletNode = new AudioWorkletNode(this.audioContext, 'audio-recorder-processor');
                
                this.audioChunks = [];
                this.recordingStartTime = Date.now();
                
                // AudioWorkletからの音声データ受信
                this.audioWorkletNode.port.onmessage = (event) => {
                    const { type, data } = event.data;
                    
                    if (type === 'audiodata' && this.isRecording) {
                        this.audioChunks.push(data);
                    }
                };
                
                // 音声処理チェーン接続
                source.connect(this.audioWorkletNode);
                this.audioWorkletNode.connect(this.audioContext.destination);
                
                // 録音開始コマンド送信
                this.audioWorkletNode.port.postMessage({ command: 'start' });
                
                this.isRecording = true;
                console.log('🎤 AudioWorkletNode録音開始成功');
                
                // Flutter側に通知
                if (window.onRecordingStarted) {
                    console.log('🔗 [AudioRecorder] Flutter側に録音開始通知送信');
                    window.onRecordingStarted();
                }
                
                // 音声レベル監視開始
                this.startAudioLevelMonitoring();
                
                return true;
                
            } catch (workletError) {
                console.warn('⚠️ AudioWorklet初期化失敗:', workletError);
                console.log('🔄 ScriptProcessorNodeフォールバックに切り替え');
                return await this.startWebAudioRecordingLegacy();
            }
            
        } catch (error) {
            console.error('❌ Web Audio API録音エラー:', error);
            return false;
        }
    }
    
    // ScriptProcessorNode フォールバック（旧iOS対応）
    async startWebAudioRecordingLegacy() {
        try {
            console.log('📱 ScriptProcessorNode使用（レガシーモード）');
            
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
            const source = this.audioContext.createMediaStreamSource(this.stream);
            source.connect(this.scriptProcessor);
            this.scriptProcessor.connect(this.audioContext.destination);
            
            this.isRecording = true;
            console.log('🎤 ScriptProcessorNode録音開始成功（フォールバック）');
            
            // Flutter側に通知
            if (window.onRecordingStarted) {
                console.log('🔗 [AudioRecorder] Flutter側に録音開始通知送信');
                window.onRecordingStarted();
            }
            
            // 音声レベル監視開始
            this.startAudioLevelMonitoring();
            
            return true;
        } catch (error) {
            console.error('❌ ScriptProcessorNode録音エラー:', error);
            return false;
        }
    }

    // 音声レベル監視開始
    startAudioLevelMonitoring() {
        if (!this.stream) return;
        
        // 前回のモニタリングをクリーンアップ
        if (this.levelMonitoringContext) {
            this.levelMonitoringContext.close();
        }
        
        // オーディオコンテキスト作成
        this.levelMonitoringContext = new (window.AudioContext || window.webkitAudioContext)();
        const source = this.levelMonitoringContext.createMediaStreamSource(this.stream);
        const analyser = this.levelMonitoringContext.createAnalyser();
        
        analyser.fftSize = 512;  // より高精度に
        const bufferLength = analyser.frequencyBinCount;
        const dataArray = new Uint8Array(bufferLength);
        
        source.connect(analyser);
        
        console.log('🎙️ 音声レベル監視開始（Flutter通知版）');
        
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
            
            // 正規化された音声レベル（0.0 - 1.0）
            const normalizedLevel = Math.min(1.0, average / 128.0);
            
            // Flutter側に音声レベルを通知
            if (window.onAudioLevelChanged) {
                window.onAudioLevelChanged(normalizedLevel);
            }
            
            // 音声レベルをコンソールに表示（感度を大幅アップ）
            if (average > 1) {  // 閾値を20→1に下げて超敏感に
                const level = Math.min(5, Math.floor(average / 10));  // 30→10に変更
                const bars = '█'.repeat(level) + '░'.repeat(5 - level);
                console.log(`🎙️ 音声レベル: ${bars} (${Math.round(average)}) ${average > 15 ? '🔊' : average > 5 ? '🔉' : '🔈'}`);
            } else if (average > 0.1) {
                console.log(`🎙️ 微弱音声検出: ${Math.round(average * 10)/10} (マイクはアクティブ)`);
            }
            
            setTimeout(monitorLevel, 100); // 0.1秒間隔でよりリアルタイムに
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
        
        // AudioWorkletNode使用時
        if (this.audioWorkletNode) {
            console.log('⏹️ AudioWorkletNode停止開始');
            this.audioWorkletNode.port.postMessage({ command: 'stop' });
            this.stopWebAudioRecording();
        }
        // ScriptProcessorNode使用時（フォールバック）
        else if (this.scriptProcessor && this.audioContext) {
            console.log('⏹️ ScriptProcessorNode停止開始');
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
    
    // Web Audio API録音停止（AudioWorkletNode & ScriptProcessorNode対応）
    stopWebAudioRecording() {
        try {
            // AudioWorkletNode切断
            if (this.audioWorkletNode) {
                this.audioWorkletNode.disconnect();
                this.audioWorkletNode = null;
                console.log('⏹️ AudioWorkletNode切断完了');
            }
            
            // ScriptProcessor切断（フォールバック）
            if (this.scriptProcessor) {
                this.scriptProcessor.disconnect();
                this.scriptProcessor = null;
                console.log('⏹️ ScriptProcessorNode切断完了');
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
        
        // AudioWorkletNode解放
        if (this.audioWorkletNode) {
            this.audioWorkletNode.disconnect();
            this.audioWorkletNode = null;
        }
        
        // ScriptProcessorNode解放（フォールバック）
        if (this.scriptProcessor) {
            this.scriptProcessor.disconnect();
            this.scriptProcessor = null;
        }
        
        // AudioContext解放
        if (this.audioContext) {
            this.audioContext.close();
            this.audioContext = null;
        }
        
        // レベル監視用AudioContext解放
        if (this.levelMonitoringContext) {
            this.levelMonitoringContext.close();
            this.levelMonitoringContext = null;
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
        hasAudioWorkletNode: !!window.audioRecorder.audioWorkletNode,
        hasScriptProcessor: !!window.audioRecorder.scriptProcessor,
        hasAudioContext: !!window.audioRecorder.audioContext,
        audioChunksLength: window.audioRecorder.audioChunks.length,
        isIOS: window.audioRecorder.isIOS,
        audioWorkletSupported: !!(window.AudioContext && window.AudioContext.prototype.audioWorklet)
    };
    console.log('📊 AudioRecorder状態:', status);
    return status;
};

console.log('🎤 Audio Recorder初期化完了 (Phase R2 - Enhanced Debug)'); 