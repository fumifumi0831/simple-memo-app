# Azure Container Registry と Azure App Service デプロイのセットアップスクリプト

このディレクトリには、simple-memo-appをAzure Container RegistryとAzure App Serviceにデプロイするためのセットアップスクリプトが含まれています。

## スクリプトの実行

始める前に、スクリプトに実行権限を付与する必要があります。

```bash
# このディレクトリに移動
cd scripts

# 実行権限を付与
chmod +x make-executable.sh
./make-executable.sh
```

## 各ステップの説明

以下のスクリプトを順番に実行することで、段階的にデプロイを構築できます：

1. `setup-step1.sh` - 基本的なDockerイメージのビルドとテスト
   - Dockerイメージのローカルビルド
   - Docker Composeを使用したローカル実行
   - GitHub Actionsの初期設定

2. `setup-step2.sh` - Azure Container Registryへのプッシュ
   - Terraformを使用したAzureリソースのセットアップ
   - サービスプリンシパルの作成
   - GitHub Secretsの設定ガイド

3. `setup-step3.sh` - 開発環境への自動デプロイ
   - developブランチの作成
   - 開発環境への自動デプロイ設定
   - Slack通知設定（オプション）

4. `setup-step4.sh` - 本番環境への承認付きデプロイ
   - GitHub上での承認ワークフロー設定
   - mainブランチへのマージと本番環境デプロイ
   - 承認プロセスのガイド

5. `setup-step5.sh` - 高度なCI/CDパイプラインとロールバック機能
   - Application Insightsの確認
   - ロールバック機能の設定
   - 最終的なCI/CDパイプラインの確認

## 前提条件

- Docker と Docker Compose
- Azure CLI
- Terraform
- Git
- GitHub アカウントとリポジトリの権限

## トラブルシューティング

各スクリプトの実行中に問題が発生した場合：

1. エラーメッセージを確認する
2. 前提条件がすべて満たされているか確認する
3. Azure Portalでリソースのデプロイステータスを確認する
4. GitHub ActionsのログでCI/CDパイプラインの状態を確認する

詳細なトラブルシューティングについては、`docs/step-by-step-guide.md` を参照してください。
