# 4\. 機能: eCoino 止まらないサプライチェーン

私たちは、AIエージェントとの対話で計画を迅速に変更できるシステムeCoinoを提案します。

## [](https://zenn.dev/nayus/articles/45d29a213c4213#%E3%82%B5%E3%83%BC%E3%83%93%E3%82%B9%E6%A9%9F%E8%83%BD%E8%A6%81%E4%BB%B6-%26-%E5%AE%9F%E8%A3%85%E6%96%B9%E9%87%9D)サービス機能要件 & 実装方針

実装方針：機能要件と実装方法は以下の通りです。

ID

機能名

詳細

実装方法

1

シナリオ管理

通常時、イベント発生時など、複数のシナリオを管理でき、詳細について参照できる機能

BI

2

シナリオ比較

複数のシナリオがある場合に、双方のデータ比較と確認ができる機能

BI

3

シナリオ対策

イベント情報など特定のシナリオ向けに、対策方法を検討できる機能

ファシリテーションAgent

4

マスタ自動生成

決定したシナリオに従い、関連するマスタデータを自動提案、反映確認できる機能

マスタ生成LLM

今回はこのうち、1~3を実装することとしました。

## [](https://zenn.dev/nayus/articles/45d29a213c4213#%E3%82%B7%E3%82%B9%E3%83%86%E3%83%A0%E3%82%A2%E3%83%BC%E3%82%AD%E3%83%86%E3%82%AF%E3%83%81%E3%83%A3)システムアーキテクチャ

![](https://storage.googleapis.com/zenn-user-upload/e1152104c916-20250210.png)

システムは上記のアーキテクチャで構成しました。

-   ユーザは、あらかじめ計画を立てるのに必要な情報をGoogleDriveにアップロードしておきます。
-   格納された情報はCloudFunctionsやdbtをもちいて、Google Cloud Storage、BigQueryへと格納されます。
-   ApplicationはStreamlitとBQ上のデータをローカルでOLAP演算するためのDuckDBの二つで構成されています。
-   LLMなどのGenerativeModelへのアクセスは基本的にStreamlitを経由して実施されます。

BIのイメージ図

![](https://storage.googleapis.com/zenn-user-upload/6e61bce66c29-20250210.png)  
![](https://storage.googleapis.com/zenn-user-upload/c17cd9f51564-20250210.png)

ファシリテーションのイメージ図

![](https://storage.googleapis.com/zenn-user-upload/aeaa817e23e7-20250210.png)  
![](https://storage.googleapis.com/zenn-user-upload/00679f2b4138-20250210.png)  
![](https://storage.googleapis.com/zenn-user-upload/8436371a964b-20250210.png)  
![](https://storage.googleapis.com/zenn-user-upload/aef34c573fa1-20250210.png)

## [](https://zenn.dev/nayus/articles/45d29a213c4213#human-in-the-loop%E3%81%AE%E8%A8%AD%E8%A8%88)Human in the Loopの設計

今回最も難しかった部分は、LLMをもちいてMTGセッションを実施することでした。  
ハルシネーションはもちろんですが、どの程度まで人間がやるべきで、どの程度まではAIがやるべきであるかといった設計が難しかったのが大きな理由です。

そこで今回ヒントになったのが、Human in the Loopという考え方でした。  
サプライチェーンの業務を考えると今後しばらくはAIに任せるのが難しいだろうと思われる部分が、 人の意思決定(意思入れ)と呼ばれるものです。ただ一方で意思決定に必要な情報を集めて時短と余裕を目指したり、シミュレーションなどを通じて意思決定に理由や正当性を与えて心理的な負荷をさげる部分については計算機でも担当できる部分は多いはずです。

![](https://storage.googleapis.com/zenn-user-upload/ad24227a7049-20250210.png)

こうして、人の動きに気軽さと納得感を与えるために、AIやシミュレータを用いたシステムを作っていき、相補的なシステムを作ろうというのが今回目指そうとしていたものであり、そのためにファシリテーションAgentを作成しました。

## [](https://zenn.dev/nayus/articles/45d29a213c4213#%E3%83%95%E3%82%A1%E3%82%B7%E3%83%AA%E3%83%86%E3%83%BC%E3%82%B7%E3%83%A7%E3%83%B3agent%E3%81%AE%E6%A7%8B%E6%88%90)ファシリテーションAgentの構成

ファシリテーションAgentは、複数のLLMからできているLLMで、内部で決定論的なアルゴリズムと非決定論的なアルゴリズムをFunctionCallingで呼び分けるという構造になっています。

![](https://storage.googleapis.com/zenn-user-upload/f782fadbbd94-20250210.jpg)

こうした構成にすることで、一つのシステムに対して様々な役割を与えることができました。

[InsightAI](https://github.com/takesei/namapn-council/blob/master/webcli/genai/models/txt2sql.py#L6-L17)や、[LocalFunctions](https://github.com/takesei/namapn-council/blob/master/webcli/genai/models/organizer.py#L9-L13)はそれぞれのソースコードを見てもらうとして、Facilitationの方法についてここでは簡単に述べようかと思います。

Facilitationは、以下のように分解して最終的なプロンプトを作成しました。

-   最終的に作成したいレポートを想定する
-   レポート作成に必要な情報を取得するJinja2テンプレートを想定する
-   Jinja2テンプレートに投げるJSONを作成する

作成したテンプレートたち

[レポート例](https://github.com/takesei/namapn-council/blob/master/webcli/templates/sample_strategy.json), [jinja Template](https://github.com/takesei/namapn-council/blob/master/webcli/templates/strategy.md), [Json template](https://github.com/takesei/namapn-council/blob/master/webcli/templates/schema_strategy.json)

この時どの順番で入れるべきか、どの情報は自動で/手動で入るのか、といった情報を別途用意し、これも使用しました。

イベント支援情報

[workflow](https://github.com/takesei/namapn-council/blob/master/webcli/templates/workflow_strategy.md)

こうしたことで、ある程度の局所的な会話における自由度を持ちながら、大域的には対策の作成を行うという流れを作ることができました。

ゆくゆくは、グラウンディングなどをもちいて過去の対策シナリオ情報を参照しながら対策を組めるようになっていくと、知見を離散的にではなく連続的に補完ができるので、組織はより滑らかになっていくのではないかと考えています。