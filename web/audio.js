// 学級通信AI - 音声録音システム
// シンプル・確実・動作重視

let mediaRecorder = null;
let audioChunks = [];
let audioStream = null;

// 音声録音開始
async function startRecording() {
    try {
        // マイクアクセス許可要求
        audioStream = await navigator.mediaDevices.getUserMedia({ 
            audio: {
                echoCancellation: true,
                noiseSuppression: true,
                sampleRate: 16000
            } 
        });
        
        // レコーダー初期化
        mediaRecorder = new MediaRecorder(audioStream, {
            mimeType: 'audio/webm;codecs=opus'
        });
        
        audioChunks = [];
        
        // データ取得イベント
        mediaRecorder.ondataavailable = (event) => {
            if (event.data.size > 0) {
                audioChunks.push(event.data);
            }
        };
        
        // 録音停止イベント  
        mediaRecorder.onstop = () => {
            const audioBlob = new Blob(audioChunks, { type: 'audio/webm' });
            sendAudioToFlutter(audioBlob);
        };
        
        // 録音開始
        mediaRecorder.start();
        
        console.log('🎤 録音開始');
        return true;
        
    } catch (error) {
        console.error('❌ 録音開始エラー:', error);
        return false;
    }
}

// 音声録音停止
function stopRecording() {
    if (mediaRecorder && mediaRecorder.state === 'recording') {
        mediaRecorder.stop();
        
        // マイクストリーム停止
        if (audioStream) {
            audioStream.getTracks().forEach(track => track.stop());
        }
        
        console.log('⏹️ 録音停止');
        return true;
    }
    return false;
}

// Flutter に音声データ送信
function sendAudioToFlutter(audioBlob) {
    const reader = new FileReader();
    reader.onload = function() {
        const arrayBuffer = reader.result;
        const uint8Array = new Uint8Array(arrayBuffer);
        
        // Flutter側のコールバック呼び出し
        if (window.flutter_audio_callback) {
            window.flutter_audio_callback(Array.from(uint8Array));
        }
        
        console.log('📤 音声データ送信完了:', uint8Array.length, 'bytes');
    };
    reader.readAsArrayBuffer(audioBlob);
}

// Flutter からの呼び出し用
window.audioRecorder = {
    start: startRecording,
    stop: stopRecording
};

console.log('音声録音機能 初期化完了'); 