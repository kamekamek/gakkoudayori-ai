// 学級通信AI - AudioWorkletProcessor
// iOS 18.5 ScriptProcessorNode廃止対応

class AudioRecorderProcessor extends AudioWorkletProcessor {
    constructor() {
        super();
        this.isRecording = false;
        this.bufferSize = 4096;
        this.buffer = new Float32Array(this.bufferSize);
        this.bufferIndex = 0;
        
        // メインスレッドからのメッセージ処理
        this.port.onmessage = (event) => {
            const { command } = event.data;
            
            switch (command) {
                case 'start':
                    this.isRecording = true;
                    console.log('🎤 [AudioWorklet] 録音開始');
                    break;
                    
                case 'stop':
                    this.isRecording = false;
                    console.log('⏹️ [AudioWorklet] 録音停止');
                    break;
                    
                default:
                    console.warn('⚠️ [AudioWorklet] 不明なコマンド:', command);
            }
        };
        
        console.log('🔧 [AudioWorklet] AudioRecorderProcessor初期化完了');
    }
    
    process(inputs, outputs, parameters) {
        const input = inputs[0];
        
        // 入力チャンネルが存在し、録音中の場合のみ処理
        if (input && input.length > 0 && this.isRecording) {
            const inputChannel = input[0]; // モノラル（第1チャンネル）
            
            // 音声データをバッファに蓄積
            for (let i = 0; i < inputChannel.length; i++) {
                this.buffer[this.bufferIndex] = inputChannel[i];
                this.bufferIndex++;
                
                // バッファが満杯になったらメインスレッドに送信
                if (this.bufferIndex >= this.bufferSize) {
                    // バッファをコピーしてメインスレッドに送信
                    const audioData = new Float32Array(this.buffer);
                    this.port.postMessage({
                        type: 'audiodata',
                        data: audioData
                    });
                    
                    // バッファリセット
                    this.bufferIndex = 0;
                }
            }
        }
        
        // プロセッサーを継続実行
        return true;
    }
}

// AudioWorkletProcessorとして登録
registerProcessor('audio-recorder-processor', AudioRecorderProcessor); 