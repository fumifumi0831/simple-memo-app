# Azure Container Registry と Azure App Service へのステップバイステップ・デプロイガイド

このガイドでは、simple-memo-appをAzure Container RegistryとAzure App Serviceに段階的にデプロイする手順を詳細に説明します。各ステップを順番に進めることで、継続的インテグレーション/継続的デリバリー（CI/CD）パイプラインを完成させることができます。

## 目次

- [前提条件](#前提条件)
- [ステップ1: 基本的なDockerイメージのビルドとテスト](#ステップ1-基本的なdockerイメージのビルドとテスト)
- [ステップ2: Azure Container Registryへのプッシュ](#ステップ2-azure-container-registryへのプッシュ)
- [ステップ3: 開発環境への自動デプロイ](#ステップ3-開発環境への自動デプロイ)
- [ステップ4: 本番環境への承認付きデプロイ](#ステップ4-本番環境への承認付きデプロイ)
- [ステップ5: 高度なCI/CDパイプラインとロールバック機能](#ステップ5-高度なcicdパイプラインとロールバック機能)

## 前提条件

- Azureアカウント
- GitHubリポジトリのアクセス権
- ローカル開発環境：
  - Docker と Docker Compose
  - Azure CLI
  - Terraform（ステップ2以降で使用）
  - Git

## ステップ1: 基本的なDockerイメージのビルドとテスト

このステップでは、アプリケーションをコンテナ化し、ローカルでビルドとテストを行います。

### 1.1 Dockerfileの作成と確認

バックエンドとフロントエンドのDockerfileは既に作成済みです。内容を確認してください：

```bash
# バックエンドのDockerfileを確認
cat backend/Dockerfile

# フロントエンドのDockerfileを確認
cat frontend/Dockerfile
```

### 1.2 docker-compose.ymlの確認

ローカル開発用のdocker-composeファイルも作成済みです：

```bash
# docker-composeファイルを確認
cat docker-compose.yml
```

### 1.3 ローカルでのビルドとテスト

```bash
# Dockerイメージのビルドと起動
docker-compose up --build

# 別のターミナルでフロントエンドのテスト（必要に応じて）
cd frontend
npm test

# 別のターミナルでバックエンドのテスト（必要に応じて）
cd backend
pytest
```

### 1.4 GitHub Actionsワークフローの確認

`.github/workflows/01-docker-build-test.yml` ファイルが既に作成されています。内容を確認してください：

```bash
cat .github/workflows/01-docker-build-test.yml
```

### 1.5 GitHub Actionsワークフローの実行

1. コードをコミットしてプッシュします：

```bash
git add .
git commit -m "Add Docker configuration and CI workflow"
git push origin main
```

2. GitHubリポジトリの「Actions」タブで、ワークフローの実行状況を確認します。
3. ビルドとテストが成功することを確認します。

## ステップ2: Azure Container Registryへのプッシュ

このステップでは、Terraformを使用してAzureリソースをセットアップし、Docker イメージをAzure Container Registryにプッシュします。

### 2.1 Terraformを使用したAzureリソースのセットアップ

1. Terraformの初期化と実行：

```bash
cd terraform

# Terraformの初期化
terraform init

# terraform.tfvarsファイルの作成
cat > terraform.tfvars << EOF
location = "japaneast"
secret_key = "your-secure-secret-key"
environment = "development"
EOF

# 実行計画の確認
terraform plan -out=tfplan

# リソースのデプロイ
terraform apply tfplan
```

2. デプロイ後、以下の出力値を確認し記録します：
   - ACR_LOGIN_SERVER
   - ACR_USERNAME
   - ACR_PASSWORD

### 2.2 Azure CLIを使用したサービスプリンシパルの作成

```bash
# サブスクリプションIDの取得
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# リソースグループ名（Terraformで作成したもの）
RESOURCE_GROUP="simple-memo-app-rg"

# サービスプリンシパルの作成
az ad sp create-for-rbac --name "GitHubActions" \
  --role contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP \
  --sdk-auth
```

表示されたJSONを保存します。これが `AZURE_CREDENTIALS` の値になります。

### 2.3 GitHub Secretsの設定

GitHubリポジトリの「Settings」→「Secrets and variables」→「Actions」から、以下のシークレットを追加します：

1. `AZURE_CREDENTIALS`: 上記で取得したJSONをそのまま貼り付け
2. `ACR_LOGIN_SERVER`: Terraformの出力から取得したACRログインサーバー
3. `ACR_USERNAME`: Terraformの出力から取得したACRユーザー名
4. `ACR_PASSWORD`: Terraformの出力から取得したACRパスワード

### 2.4 GitHub Actionsワークフローの確認と実行

1. ワークフロー設定を確認：

```bash
cat .github/workflows/02-build-push-acr.yml
```

2. 変更をコミットしてプッシュ：

```bash
git add .
git commit -m "Add ACR push workflow and setup Terraform"
git push origin main
```

3. GitHubリポジトリの「Actions」タブでワークフローの実行を確認
4. Azure Portalにログインし、Azure Container Registryにイメージがプッシュされていることを確認

## ステップ3: 開発環境への自動デプロイ

このステップでは、開発用のブランチを作成し、そのブランチへのプッシュで開発環境に自動デプロイするよう設定します。

### 3.1 develop ブランチの作成とプッシュ

```bash
# developブランチの作成
git checkout -b develop

# ブランチをプッシュ
git push -u origin develop
```

### 3.2 GitHub Actionsワークフローの確認

```bash
cat .github/workflows/03-deploy-dev.yml
```

内容を確認し、必要に応じて以下の値を修正します：
- アプリ名（app-name）が正しいか確認（Terraformの出力と一致するか）
- 必要なSlack通知設定（オプション）

### 3.3 Slack通知のセットアップ（オプション）

Slack通知を使用する場合は、以下の手順を実行します：

1. Slackワークスペースで新しいWebhook URLを作成
2. GitHubリポジトリのSecretsに `SLACK_WEBHOOK` として追加

### 3.4 変更のプッシュと自動デプロイの確認

```bash
# ファイルを編集してコミット（例えば、フロントエンドの変更）
echo "// Test change" >> frontend/pages/index.tsx
git add frontend/pages/index.tsx
git commit -m "Test automatic deployment to dev environment"

# 変更をプッシュ
git push origin develop
```

GitHubリポジトリの「Actions」タブでワークフローの実行を確認し、開発環境へのデプロイが成功することを確認します。

### 3.5 デプロイされたアプリの確認

Azure Portalにログインし、App Serviceの開発環境（simple-memo-app-frontend-dev および simple-memo-app-backend-dev）にアクセスしてアプリが正常に動作していることを確認します。

## ステップ4: 本番環境への承認付きデプロイ

このステップでは、mainブランチへのプッシュで本番環境へのデプロイが行われるよう設定しますが、デプロイ前に承認が必要になります。

### 4.1 GitHub環境の設定

1. GitHubリポジトリの「Settings」→「Environments」→「New environment」から、`production`環境を作成します。
2. 「Required reviewers」にチェックを入れ、承認者を追加します。
3. 必要に応じて他の保護設定を有効にします。

### 4.2 GitHub Actionsワークフローの確認

```bash
cat .github/workflows/04-deploy-prod.yml
```

内容を確認し、必要に応じて以下の値を修正します：
- アプリ名（app-name）が正しいか
- リソースグループ名が正しいか
- スロット名が正しいか

### 4.3 コードの変更とmainブランチへのマージ

```bash
# mainブランチに戻る
git checkout main

# developブランチの変更をマージ
git merge develop

# プッシュ
git push origin main
```

### 4.4 承認プロセスとデプロイの確認

1. GitHubリポジトリの「Actions」タブでワークフローの実行を確認
2. ワークフローが承認待ちになっていることを確認
3. 「Review deployments」ボタンをクリックし、承認を行う
4. デプロイが完了するまで待機
5. Azure Portalで本番環境にアクセスし、アプリが正常に動作していることを確認

## ステップ5: 高度なCI/CDパイプラインとロールバック機能

最後のステップでは、ロールバック機能を含む高度なCI/CDパイプラインを設定します。

### 5.1 ロールバックワークフローの確認

```bash
cat .github/workflows/05-rollback.yml
```

### 5.2 Application Insightsの確認

Azure Portalで、Application Insightsリソースにアクセスし、次の項目を確認します：
- リソースが正しく作成されているか
- モニタリングデータが取得できているか
- アプリからのテレメトリが記録されているか

### 5.3 ロールバック機能のテスト（オプション）

1. GitHubリポジトリの「Actions」タブに移動
2. 左側のワークフローリストから「05-Rollback (Manual Trigger)」を選択
3. 「Run workflow」ボタンをクリック
4. 以前のイメージタグを指定（例：YYYYMMDD-commit）
5. ワークフローを実行し、ロールバックが正常に行われることを確認

### 5.4 CI/CDパイプラインの完成確認

これで5段階の全てのステップが完了し、以下の機能を持つCI/CDパイプラインが完成しました：

1. 基本的なDockerイメージのビルドとテスト
2. Azure Container Registryへのプッシュ
3. 開発環境への自動デプロイ
4. 本番環境への承認付きデプロイ
5. 手動ロールバック機能

## トラブルシューティング

各ステップで問題が発生した場合は、以下を確認してください：

- GitHub Actionsのログを詳細に確認
- Azure Portalでリソースの状態を確認
- テラフォームのログや出力を確認
- Azure CLIを使用してリソースの詳細を確認：

```bash
# App Serviceのログを確認
az webapp log tail --name simple-memo-app-backend-dev --resource-group simple-memo-app-rg

# ACRのイメージを一覧表示
az acr repository list --name simplememoappacr --output table

# 特定のイメージのタグを確認
az acr repository show-tags --name simplememoappacr --repository simple-memo-app-backend --output table
```

以上で、Azure Container Registry と Azure App Service を使った段階的なデプロイの導入は完了です。これにより、継続的インテグレーションと継続的デリバリーのパイプラインが構築され、効率的なアプリケーション開発とデプロイが可能になりました。
