// Page Object Model for HomePage
class HomePage {
  constructor(page) {
    this.page = page;
    
    // セレクタの定義
    this.selectors = {
      mainContainer: '[data-testid="main-container"]',
      adkChatWidget: '[data-testid="adk-chat-widget"]',
      chatInput: '[data-testid="chat-input"]',
      sendButton: '[data-testid="send-button"]',
      recordButton: '[data-testid="record-button"]',
      voiceInputButton: '[data-testid="voice-input-button"]',
      htmlPreview: '[data-testid="html-preview"]',
      desktopLayout: '[data-testid="desktop-layout"]',
      mobileLayout: '[data-testid="mobile-layout"]',
      recordingIndicator: '[data-testid="recording-indicator"]',
      userMessage: '[data-testid="user-message"]',
      assistantMessage: '[data-testid="assistant-message"]'
    };
  }

  // ページアクション
  async navigate() {
    await this.page.goto('/');
    await this.page.waitForLoadState('networkidle');
  }

  async sendChatMessage(message) {
    await this.page.fill(this.selectors.chatInput, message);
    await this.page.click(this.selectors.sendButton);
  }

  async startRecording() {
    await this.page.click(this.selectors.recordButton);
  }

  async startVoiceInput() {
    await this.page.click(this.selectors.voiceInputButton);
  }

  async setViewportSize(width, height) {
    await this.page.setViewportSize({ width, height });
  }

  // 要素の取得
  getMainContainer() {
    return this.page.locator(this.selectors.mainContainer);
  }

  getChatWidget() {
    return this.page.locator(this.selectors.adkChatWidget);
  }

  getChatInput() {
    return this.page.locator(this.selectors.chatInput);
  }

  getHtmlPreview() {
    return this.page.locator(this.selectors.htmlPreview);
  }

  getLastUserMessage() {
    return this.page.locator(this.selectors.userMessage).last();
  }

  getLastAssistantMessage() {
    return this.page.locator(this.selectors.assistantMessage).last();
  }

  // 待機処理
  async waitForChatWidget() {
    await this.page.waitForSelector(this.selectors.adkChatWidget);
  }

  async waitForHtmlPreview() {
    await this.page.waitForSelector(this.selectors.htmlPreview);
  }

  async waitForRecordingIndicator() {
    await this.page.waitForSelector(this.selectors.recordingIndicator);
  }
}

module.exports = { HomePage };