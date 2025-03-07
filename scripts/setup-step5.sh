#!/bin/bash
# ステップ5：高度なCI/CDパイプラインとロールバック機能

echo "====== ステップ5: 高度なCI/CDパイプラインとロールバック機能 ======"
echo "このスクリプトは、ロールバック機能を含む高度なCI/CDパイプラインをセットアップします。"
echo "また、Application Insightsを利用したモニタリングも確認します。"

# Azure CLIがインストールされているか確認
if ! command -v az &> /dev/null; then
  echo "Error: Azure CLIがインストールされていません。"
  echo "https://docs.microsoft.com/ja-jp/cli/azure/install-azure-cli からインストールしてください。"
  exit 1
fi

# Azureにログイン
echo "Azureにログインします..."
az login

# リソースグループを取得
echo "Terraformが作成したリソースグループを確認します..."
RESOURCE_GROUP="simple-memo-app-rg"
echo "リソースグループ: $RESOURCE_GROUP"

# App Serviceの一覧を表示
echo "デプロイされているApp Serviceを確認します..."
az webapp list --resource-group $RESOURCE_GROUP --output table

# Application Insightsの確認
echo "Application Insightsリソースを確認します..."
az monitor app-insights component show --resource-group $RESOURCE_GROUP --query "[].{Name:name, InstrumentationKey:instrumentationKey}" --output table

# ロールバックワークフローの確認
echo "ロールバックワークフローファイルを確認しています..."
cat .github/workflows/05-rollback.yml

# ロールバックに使用できるイメージのタグを確認
echo "Azure Container Registryのイメージタグを確認しています..."
ACR_NAME=$(az acr list --resource-group $RESOURCE_GROUP --query "[0].name" -o tsv)

if [ -n "$ACR_NAME" ]; then
  echo "バックエンドのイメージタグ:"
  az acr repository show-tags --name $ACR_NAME --repository simple-memo-app-backend --output table

  echo "フロントエンドのイメージタグ:"
  az acr repository show-tags --name $ACR_NAME --repository simple-memo-app-frontend --output table
else
  echo "Azure Container Registryが見つかりません。"
fi

# 手動ロールバックの手順
echo ""
echo "【手動ロールバックの実行手順】"
echo "1. GitHubリポジトリの 'Actions' タブに移動"
echo "2. 左側のワークフローリストから '05-Rollback (Manual Trigger)' を選択"
echo "3. 'Run workflow' ボタンをクリック"
echo "4. 以下の情報を入力:"
echo "   - backend_tag: ロールバックするバックエンドイメージのタグ (例: 20250307-abcdef1)"
echo "   - frontend_tag: ロールバックするフロントエンドイメージのタグ (例: 20250307-abcdef1)"
echo "5. 'Run workflow' をクリックして実行"
echo ""

# モニタリングの設定
echo "【モニタリングの確認手順】"
echo "1. Azure Portalにログイン: https://portal.azure.com"
echo "2. Application Insightsリソースにアクセス"
echo "3. 'Live Metrics' でリアルタイムのパフォーマンスを確認"
echo "4. 'Failures' で発生したエラーを確認"
echo "5. 'Performance' でパフォーマンスの問題を確認"
echo ""

# 最終確認
echo "すべてのステップが完了しました！"
echo "これで、以下の機能を持つCI/CDパイプラインが構築されました："
echo "✅ ステップ1: 基本的なDockerイメージのビルドとテスト"
echo "✅ ステップ2: Azure Container Registryへのプッシュ"
echo "✅ ステップ3: 開発環境への自動デプロイ"
echo "✅ ステップ4: 本番環境への承認付きデプロイ"
echo "✅ ステップ5: 高度なCI/CDパイプラインとロールバック機能"
echo ""
echo "開発環境URL:"
echo "- フロントエンド: https://simple-memo-app-frontend-dev.azurewebsites.net"
echo "- バックエンドAPI: https://simple-memo-app-backend-dev.azurewebsites.net/docs"
echo ""
echo "本番環境URL:"
echo "- フロントエンド: https://simple-memo-app-frontend-prod.azurewebsites.net"
echo "- バックエンドAPI: https://simple-memo-app-backend-prod.azurewebsites.net/docs"
echo ""
echo "GitHub Actionsワークフロー:"
echo "URL: https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:\/]\(.*\)\.git/\1/')/actions"
echo ""
echo "お疲れ様でした！"
