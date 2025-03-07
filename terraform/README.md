# Terraformを使用したAzureリソースのセットアップ

このディレクトリには、Simple Memo Appを展開するためのAzureインフラストラクチャをセットアップするTerraformファイルが含まれています。

## 前提条件

- [Terraform](https://www.terraform.io/downloads.html) (v1.0.0以上)
- [Azure CLI](https://docs.microsoft.com/ja-jp/cli/azure/install-azure-cli) (最新版)
- Azureアカウントと適切な権限

## セットアップ手順

### 1. Azureにログイン

```bash
az login
```

### 2. Terraformの初期化

```bash
cd terraform
terraform init
```

### 3. 環境変数ファイルの作成

`terraform.tfvars`ファイルを作成し、必要な変数を設定します:

```hcl
location   = "japaneast"
secret_key = "your-secure-secret-key"
```

必要に応じて`location`を変更してください。

### 4. Terraformプランの確認

```bash
terraform plan -out=tfplan
```

プランの出力を確認し、作成されるリソースを確認します。

### 5. インフラストラクチャのデプロイ

```bash
terraform apply tfplan
```

デプロイが完了したら、出力値を確認します。

### 6. GitHub Secretsの設定

Terraform実行後、以下の値をGitHubのリポジトリシークレットとして設定します:

1. `AZURE_CREDENTIALS`: Azure サービスプリンシパルの情報（以下のコマンドで取得）

```bash
az ad sp create-for-rbac --name "GitHubActions" --role contributor \
  --scopes /subscriptions/$(az account show --query id -o tsv)/resourceGroups/simple-memo-app-rg \
  --sdk-auth
```

2. `ACR_LOGIN_SERVER`: Terraformの出力から取得
3. `ACR_USERNAME`: Terraformの出力から取得
4. `ACR_PASSWORD`: Terraformの出力から取得

### 7. GitHubリポジトリの設定

1. GitHub リポジトリの Settings > Environments から、`production` 環境を作成します。
2. Required reviewers を設定して、必要な承認者を追加します。

## その他のコマンド

### リソースの更新

Terraformファイルを変更した後、再度デプロイするには:

```bash
terraform plan -out=tfplan
terraform apply tfplan
```

### リソースの削除

インフラストラクチャを削除するには:

```bash
terraform destroy
```

## 注意点

- 本番環境へのデプロイは、承認ワークフローを経由して行われます。
- ステージング環境から本番環境へのスワップは、GitHub Actionsワークフローにより自動化されています。
- リソース名は一意である必要があるため、ACR名などが既に使用されている場合は適宜変更してください。
