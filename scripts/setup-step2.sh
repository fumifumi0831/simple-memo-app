#!/bin/bash
# ステップ2：Azure Container Registry へのプッシュのセットアップ

echo "====== ステップ2: Azure Container Registry へのプッシュ ======"
echo "このスクリプトは、Azure CLIを使用してAzureリソースをセットアップし、"
echo "Docker イメージをAzure Container Registryにプッシュするためのセットアップを行います。"

# 必要なツールの確認
if ! command -v az &> /dev/null; then
  echo "Error: Azure CLIがインストールされていません。"
  echo "https://docs.microsoft.com/ja-jp/cli/azure/install-azure-cli からインストールしてください。"
  exit 1
fi

if ! command -v terraform &> /dev/null; then
  echo "Error: Terraformがインストールされていません。"
  echo "https://www.terraform.io/downloads.html からインストールしてください。"
  exit 1
fi

# Azureにログイン
echo "Azureにログインします..."
az login

# サブスクリプションの確認
echo "Azureサブスクリプション一覧:"
az account list --output table

read -p "使用するサブスクリプションIDを入力してください: " SUBSCRIPTION_ID
az account set --subscription $SUBSCRIPTION_ID

echo "選択されたサブスクリプション:"
az account show --output table

# Terraformの実行
echo "Terraformを初期化しています..."
cd terraform
terraform init

# terraform.tfvarsファイルの作成
read -p "デプロイするAzureリージョンを入力してください (default: japaneast): " LOCATION
LOCATION=${LOCATION:-japaneast}

read -p "シークレットキーを入力してください (JWT認証用): " SECRET_KEY
SECRET_KEY=${SECRET_KEY:-"$(openssl rand -base64 32)"}

read -p "環境を入力してください (development/staging/production) (default: development): " ENVIRONMENT
ENVIRONMENT=${ENVIRONMENT:-development}

echo "location = \"$LOCATION\"" > terraform.tfvars
echo "secret_key = \"$SECRET_KEY\"" >> terraform.tfvars
echo "environment = \"$ENVIRONMENT\"" >> terraform.tfvars

echo "Terraformの実行計画を作成しています..."
terraform plan -out=tfplan

echo "Terraformを実行してAzureリソースをデプロイします..."
terraform apply tfplan

# 出力の取得
echo "Terraformの出力を取得しています..."
ACR_LOGIN_SERVER=$(terraform output -raw acr_login_server)
ACR_USERNAME=$(terraform output -raw acr_admin_username)
ACR_PASSWORD=$(terraform output -raw acr_admin_password)
RESOURCE_GROUP=$(terraform output -raw resource_group_name)

echo "ACR_LOGIN_SERVER: $ACR_LOGIN_SERVER"
echo "ACR_USERNAME: $ACR_USERNAME"
echo "RESOURCE_GROUP: $RESOURCE_GROUP"

# サービスプリンシパルの作成
echo "GitHub Actions用のサービスプリンシパルを作成しています..."
AZURE_CREDENTIALS=$(az ad sp create-for-rbac --name "GitHubActions-SimpleMemoApp" \
  --role contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP \
  --sdk-auth)

echo "Azure Credentialsを出力しています..."
echo "$AZURE_CREDENTIALS"

# GitHub Secretsの設定手順
echo ""
echo "次のステップ: GitHub Secretsの設定"
echo "GitHubリポジトリの 'Settings' → 'Secrets and variables' → 'Actions' から、"
echo "以下のシークレットを追加してください:"
echo ""
echo "1. AZURE_CREDENTIALS: 上記で出力されたJSONをそのまま貼り付け"
echo "2. ACR_LOGIN_SERVER: $ACR_LOGIN_SERVER"
echo "3. ACR_USERNAME: $ACR_USERNAME"
echo "4. ACR_PASSWORD: Terraformの出力から取得したACRパスワード"
echo ""
echo "Secretsを設定したら、リポジトリのルートディレクトリに戻り、"
echo "scripts/setup-step3.sh を実行して次のステップに進んでください。"

# 元のディレクトリに戻る
cd ..
