# Azure Container Registry と Azure App Service を使った段階的なデプロイ導入

このドキュメントでは、simple-memo-appをAzure Container RegistryとAzure App Serviceを使ってデプロイする手順を説明します。GitHub Actionsを使用して継続的インテグレーション/継続的デリバリー（CI/CD）パイプラインを構築し、自動デプロイを実現します。

## 目次

1. [前提条件](#前提条件)
2. [Dockerコンテナ化](#Dockerコンテナ化)
3. [Azureリソースのセットアップ](#Azureリソースのセットアップ)
4. [GitHub ActionsによるCI/CDパイプライン](#GitHub-ActionsによるCI/CDパイプライン)
5. [デプロイ戦略の詳細](#デプロイ戦略の詳細)
6. [環境の確認とモニタリング](#環境の確認とモニタリング)
7. [トラブルシューティング](#トラブルシューティング)

## 前提条件

- Azureアカウント
- GitHubアカウントとリポジトリ
- [Azure CLI](https://docs.microsoft.com/ja-jp/cli/azure/install-azure-cli)
- [Terraform](https://www.terraform.io/downloads.html)（インフラ構築用）

## Dockerコンテナ化

アプリケーションをデプロイするために、バックエンドとフロントエンドのDockerfileを作成しました。

### バックエンドDockerfile（`backend/Dockerfile`）

```dockerfile
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### フロントエンドDockerfile（`frontend/Dockerfile`）

```dockerfile
FROM node:18-alpine AS base

# Install dependencies only when needed
FROM base AS deps
WORKDIR /app

# Install dependencies
COPY package.json package-lock.json ./
RUN npm ci

# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Next.js collects anonymous telemetry data about general usage
ENV NEXT_TELEMETRY_DISABLED 1

# Build the application
RUN npm run build

# Production image, copy all the files and run next
FROM base AS runner
WORKDIR /app

ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1

# Create a non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Copy the build output and node_modules
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json

# Set correct permissions for nextjs user
USER nextjs

# Set the correct port
ENV PORT 3000
EXPOSE 3000

# Start the application
CMD ["npm", "start"]
```

### ローカル開発用docker-compose.yml

```yaml
version: '3.8'

services:
  backend:
    build: ./backend
    ports:
      - "8000:8000"
    volumes:
      - ./backend:/app
    environment:
      - SECRET_KEY=development_secret_key
      - ENVIRONMENT=development
    restart: unless-stopped

  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    volumes:
      - ./frontend:/app
      - /app/node_modules
      - /app/.next
    environment:
      - NEXT_PUBLIC_API_URL=http://localhost:8000
    depends_on:
      - backend
    restart: unless-stopped
```

## Azureリソースのセットアップ

Terraformを使用してAzureリソースをプロビジョニングします。設定ファイルは `terraform/` ディレクトリにあります。

### 主なリソース

- Azure Resource Group
- Azure Container Registry (ACR)
- Azure App Service Plan（開発環境とプロダクション環境）
- Azure Web App（バックエンドとフロントエンド、開発環境とプロダクション環境）
- Application Insights

### セットアップ手順

1. `terraform/` ディレクトリに移動
2. Terraformの初期化
   ```bash
   terraform init
   ```
3. 実行計画の確認
   ```bash
   terraform plan -out=tfplan
   ```
4. リソースのデプロイ
   ```bash
   terraform apply tfplan
   ```

詳細な手順は、`terraform/README.md` を参照してください。

## GitHub ActionsによるCI/CDパイプライン

GitHub Actionsワークフローを5つのステップで構築しました：

### 1. 基本的なDockerイメージのビルドとテスト

`.github/workflows/01-docker-build-test.yml`

- 全てのプッシュとプルリクエストでトリガー
- バックエンドとフロントエンドのDockerイメージをビルド
- 自動テストを実行（コメントアウトされた部分を必要に応じて有効化）

### 2. Azure Container Registry へのプッシュ

`.github/workflows/02-build-push-acr.yml`

- mainとdevelopブランチへのプッシュでトリガー
- ACRへのログイン
- ブランチに応じたタグ付け
- イメージのビルドとプッシュ

### 3. 開発環境への自動デプロイ

`.github/workflows/03-deploy-dev.yml`

- developブランチへのプッシュでトリガー
- イメージをビルドしてACRにプッシュ
- 開発環境のApp Serviceにデプロイ
- Slack通知（オプション）

### 4. 本番環境への承認付きデプロイ

`.github/workflows/04-deploy-prod.yml`

- mainブランチへのプッシュでトリガー
- ステージングスロットにまずデプロイ
- 環境変数の設定
- 承認プロセスを経て本番環境にスワップ

### 5. 手動ロールバック

`.github/workflows/05-rollback.yml`

- 手動トリガー
- 指定したイメージバージョンに戻す
- Application Insightsにロールバック操作を記録
- Slack通知

## デプロイ戦略の詳細

### ブランチ戦略

- `develop` ブランチ: 開発環境へ自動デプロイ
- `main` ブランチ: 本番環境へ承認後デプロイ

### 環境分離

- 開発環境: `simple-memo-app-*-dev`
- 本番環境: `simple-memo-app-*-prod`（ステージングスロット付き）

### イメージタグ戦略

- 開発環境: `latest` タグ
- 本番環境: `YYYYMMDD-commit` 形式の日付とコミットハッシュ

### デプロイフロー

1. コードをプッシュ
2. イメージをビルドしてACRにプッシュ
3. 環境に応じたデプロイプロセス：
   - 開発環境: 直接デプロイ
   - 本番環境: ステージングスロットにデプロイ → 承認 → 本番スワップ

## 環境の確認とモニタリング

- Azure Portalから各環境のアプリケーションにアクセス可能
- Application Insightsによるモニタリング
- デプロイログとスワップ履歴を追跡

## トラブルシューティング

- **デプロイ失敗**: GitHub Actionsのログを確認
- **イメージプッシュエラー**: ACRの認証情報を確認
- **アプリエラー**: App Serviceのログストリームを確認
- **ロールバックが必要**: GitHub Actionsの手動トリガーワークフローを使用

## GitHub Secretsの設定

以下のシークレットをGitHubリポジトリに設定する必要があります：

- `AZURE_CREDENTIALS`: Azureサービスプリンシパル情報（JSON形式）
- `ACR_LOGIN_SERVER`: ACRのログインサーバー
- `ACR_USERNAME`: ACRのユーザー名
- `ACR_PASSWORD`: ACRのパスワード
- `SLACK_WEBHOOK`: Slack通知用（オプション）

詳細なセットアップ手順は `terraform/README.md` を参照してください。
