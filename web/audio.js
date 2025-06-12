// 学級通信AI - 音声録音機能
class AudioRecorder {
  constructor() {
    this.mediaRecorder = null;
    this.audioChunks = [];
    this.isRecording = false;
  }

  // 音声録音開始
  async startRecording() {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ 
        audio: {
          sampleRate: 16000,
          channelCount: 1,
          echoCancellation: true,
          noiseSuppression: true
        } 
      });
      
      this.mediaRecorder = new MediaRecorder(stream, {
        mimeType: 'audio/webm;codecs=opus'
      });
      
      this.audioChunks = [];
      
      this.mediaRecorder.ondataavailable = (event) => {
        this.audioChunks.push(event.data);
      };
      
      this.mediaRecorder.onstop = () => {
        const audioBlob = new Blob(this.audioChunks, { type: 'audio/wav' });
        this.onRecordingComplete(audioBlob);
        
        // Clean up stream
        stream.getTracks().forEach(track => track.stop());
      };
      
      this.mediaRecorder.start();
      this.isRecording = true;
      
      console.log('音声録音開始');
      return true;
      
    } catch (error) {
      console.error('音声録音エラー:', error);
      return false;
    }
  }

  // 音声録音停止
  stopRecording() {
    if (this.mediaRecorder && this.isRecording) {
      this.mediaRecorder.stop();
      this.isRecording = false;
      console.log('音声録音停止');
      return true;
    }
    return false;
  }

  // 録音完了時のコールバック（Dartから設定）
  onRecordingComplete(audioBlob) {
    // Convert to base64 for Dart
    const reader = new FileReader();
    reader.onload = () => {
      const base64Audio = reader.result.split(',')[1];
      window.flutterAudioCallback(base64Audio);
    };
    reader.readAsDataURL(audioBlob);
  }

  // 録音状態確認
  getRecordingState() {
    return this.isRecording;
  }
}

// グローバルインスタンス作成
window.audioRecorder = new AudioRecorder();

// Dart呼び出し用関数
window.startAudioRecording = () => window.audioRecorder.startRecording();
window.stopAudioRecording = () => window.audioRecorder.stopRecording();
window.getRecordingState = () => window.audioRecorder.getRecordingState();

console.log('音声録音機能 初期化完了'); 