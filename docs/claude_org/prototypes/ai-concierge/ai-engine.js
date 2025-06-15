class AIEngine {
    constructor() {
        this.responses = {
            greeting: [
                "こんにちは！弊社の革新的なIT企業へようこそ。どのようなことについてお聞きになりたいですか？",
                "いらっしゃいませ！私たちの技術力や実績について、何でもお気軽にご質問ください。",
                "お疲れ様です！弊社のサービスや事業内容について詳しくご説明いたします。"
            ],
            services: [
                "弊社では、AIとWebXR技術を融合した次世代Webアプリケーション開発を専門としています。リアルタイム3D可視化、機械学習による予測分析、没入型VR/AR体験などが主なサービスです。",
                "クラウドネイティブなアーキテクチャによるスケーラブルなシステム開発、マイクロサービス設計、そしてDevOps自動化によって、お客様のDXを加速させています。",
                "データサイエンスとUI/UX設計を組み合わせた、ユーザー中心の革新的なソリューションを提供しています。特にリアルタイムデータ処理と可視化が得意分野です。"
            ],
            technology: [
                "最新のWeb技術スタックとして、React、Vue.js、Node.js、Python、Go言語を活用しています。また、Three.js、WebXR、WebRTC、Socket.io等の先端技術も積極的に導入しています。",
                "AI・ML分野では、TensorFlow、PyTorch、OpenAI GPTシリーズを活用し、自然言語処理、画像認識、予測分析システムを開発しています。",
                "インフラとしてはAWS、Azure、GCPを活用したマルチクラウド戦略で、Kubernetes、Docker、CI/CDパイプラインによる効率的な開発・運用を実現しています。"
            ],
            team: [
                "弊社には50名以上のエンジニアが在籍しており、フロントエンド、バックエンド、AI/ML、DevOps、UI/UXの各分野のスペシャリストが協力して開発に取り組んでいます。",
                "チームは平均経験年数8年以上のシニアエンジニアが中心で、アジャイル開発手法により迅速かつ高品質なソフトウェア開発を実現しています。",
                "継続的な技術学習とイノベーションを重視し、社内勉強会、OSS貢献、技術カンファレンス参加を積極的に支援しています。"
            ],
            contact: [
                "お問い合わせは、こちらのWebサイトから直接ご連絡いただけます。24時間以内に担当者からご回答いたします。また、オンライン相談会も随時開催しております。",
                "プロジェクトのご相談、技術的な質問、採用に関するお問い合わせなど、何でもお気軽にご連絡ください。初回コンサルテーションは無料です。",
                "リモート対応も可能ですので、全国どちらからでもご相談いただけます。Zoom、Google Meet、Microsoft Teamsでのオンライン会議に対応しています。"
            ]
        };
        
        this.context = [];
        this.isProcessing = false;
    }

    async processMessage(message) {
        if (this.isProcessing) return "少々お待ちください...";
        
        this.isProcessing = true;
        this.context.push({ role: 'user', content: message });
        
        // シミュレート処理時間
        await new Promise(resolve => setTimeout(resolve, 1000 + Math.random() * 2000));
        
        const response = this.generateResponse(message);
        this.context.push({ role: 'assistant', content: response });
        
        this.isProcessing = false;
        return response;
    }

    generateResponse(message) {
        const lowerMessage = message.toLowerCase();
        
        // キーワードマッチングによる応答生成
        if (lowerMessage.includes('こんにちは') || lowerMessage.includes('はじめまして') || lowerMessage.includes('hello')) {
            return this.getRandomResponse('greeting');
        }
        
        if (lowerMessage.includes('サービス') || lowerMessage.includes('事業') || lowerMessage.includes('何をしている')) {
            return this.getRandomResponse('services');
        }
        
        if (lowerMessage.includes('技術') || lowerMessage.includes('テクノロジー') || lowerMessage.includes('使っている言語')) {
            return this.getRandomResponse('technology');
        }
        
        if (lowerMessage.includes('チーム') || lowerMessage.includes('メンバー') || lowerMessage.includes('エンジニア')) {
            return this.getRandomResponse('team');
        }
        
        if (lowerMessage.includes('連絡') || lowerMessage.includes('問い合わせ') || lowerMessage.includes('相談') || lowerMessage.includes('contact')) {
            return this.getRandomResponse('contact');
        }
        
        if (lowerMessage.includes('価格') || lowerMessage.includes('料金') || lowerMessage.includes('費用')) {
            return "料金については、プロジェクトの規模や要件によって異なります。詳細なお見積りをご希望の場合は、お気軽にお問い合わせください。初回相談は無料で承っております。";
        }
        
        if (lowerMessage.includes('実績') || lowerMessage.includes('ポートフォリオ') || lowerMessage.includes('事例')) {
            return "これまで500以上のプロジェクトを手がけており、金融、ヘルスケア、エデュケーション、eコマースなど多様な業界でのシステム開発実績があります。詳細な事例については、NDAを締結の上でご紹介させていただきます。";
        }
        
        if (lowerMessage.includes('AI') || lowerMessage.includes('人工知能') || lowerMessage.includes('機械学習')) {
            return "AI分野では、自然言語処理、画像認識、予測分析、推薦システムなどの開発経験が豊富です。特に最新のTransformerモデルやGPTを活用したソリューション開発を得意としています。";
        }
        
        // デフォルト応答
        const defaultResponses = [
            "興味深いご質問ですね。より詳しくお聞かせいただけますか？私たちの技術力でお役に立てることがあるかもしれません。",
            "その件について詳しく調べてお答えいたします。具体的にはどのような点について知りたいでしょうか？",
            "ありがとうございます。弊社の専門分野と関連がありそうですね。どのような課題を解決されたいのでしょうか？",
            "申し訳ございませんが、もう少し詳しく教えていただけますか？より具体的なご提案ができると思います。"
        ];
        
        return defaultResponses[Math.floor(Math.random() * defaultResponses.length)];
    }
    
    getRandomResponse(category) {
        const responses = this.responses[category];
        return responses[Math.floor(Math.random() * responses.length)];
    }
    
    getPersonalizedGreeting() {
        const currentHour = new Date().getHours();
        if (currentHour < 12) {
            return "おはようございます！素晴らしい朝ですね。弊社についてご質問はありませんか？";
        } else if (currentHour < 18) {
            return "こんにちは！お忙しい中お時間をいただき、ありがとうございます。";
        } else {
            return "こんばんは！夜遅くまでお疲れ様です。何かお手伝いできることはありますか？";
        }
    }
}

// AI Engine のインスタンス作成
const aiEngine = new AIEngine();