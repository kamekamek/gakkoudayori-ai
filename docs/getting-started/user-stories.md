| ID      | ユーザーストーリー                  | 詳細                                                                   | 優先度 | スプリント   |
| ------- | -------------------------- | -------------------------------------------------------------------- | --- | ------- |
| US-001  | チャット型で音声入力したい              | チャット画面にマイクアイコンを設置し、タップで録音→自動文字起こし（バブルに投稿）                            | 高   | PoC/MVP |
| US-002  | 録音中にリアルタイムで文字起こしを確認したい     | 録音中、逐次テキストをチャットにプレビュー表示。誤変換はその場でタップ編集可能                              | 高   | PoC/MVP |
| US-003  | 文字起こし結果を投稿前に修正したい          | 投稿前チャット入力欄で自由に編集できる機能                                                | 高   | PoC/MVP |
| US-004  | 入力した文章を AI でリライトしたい        | ユーザー辞書を反映したカスタムプロンプトで敬語・句読点調整・語調変更を実行                                | 高   | PoC/MVP |
| US-005  | 自動で見出しを生成したい               | 任意のタイミングで「見出し自動生成」ボタンを押し、Gemini API でトピック分割＆見出し候補取得                  | 高   | MVP     |
| US-006  | レイアウトを選択したい                | テーマカラー（7色）＋フォーマット4種（標準／画像多め／画像少なめ／画像なし）を選択                           | 高   | MVP     |
| US-007  | 選択したレイアウトで HTML を自動生成したい   | Layout Agent がテンプレートにパラメータを流し込み、HTML を返却                             | 高   | PoC/MVP |
| US-008  | 生成後の HTML を自由に編集したい        | Flutter Quill などの WYSIWYG エディタで、テキスト装飾・段落移動・リンク挿入などが可能               | 中   | MVP     |
| US-009  | 画像を挿入したい                   | ギャラリー／カメラで選択→Firebase Storage（GCS）へアップ→公開 URL を HTML `<img>` タグに埋め込む | 中   | MVP     |
| US-010  | A4 フォーマットで PDF を出力したい      | wkhtmltopdf などで HTML→PDF 変換を行い、ユーザーにダウンロードリンクを提示                     | 高   | PoC/MVP |
| US-011  | Google Classroom で配信したい    | Classroom API と連携し、クラス一覧取得→選択クラスへ PDF を一括配信                          | 低   | 後続      |
| US-012  | LINE で保護者に通知したい            | LINE Messaging API でトークン管理→メッセージ＋PDF URL を送信                         | 低   | 後続      |
| INF-001 | Firebase プロジェクト構成を整備したい    | Authentication／Firestore／Storage をセットアップし、必要なセキュリティルール＆アクセス権を設定      | 高   | PoC     |
| INF-002 | Vertex AI ＆ ADK 開発環境を構築したい | Vertex AI Agent Builder の準備、ADK SDK（Python/Java）のインストール・サンプル起動       | 高   | PoC     |
| INF-003 | CI/CD パイプラインを整えたい          | Cloud Build ＋ GitHub Actions でビルド・テスト・デプロイを自動化                       | 中   | MVP     |
| INF-004 | モニタリング＆ログ収集基盤を構築したい        | Cloud Logging / Error Reporting / Cloud Scheduler でジョブ監視・ログ集約        | 中   | MVP     |
