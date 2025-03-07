#!/bin/bash
# ステップ3：開発環境への自動デプロイのセットアップ

echo "====== ステップ3: 開発環境への自動デプロイ ======"
echo "このスクリプトは、開発環境への自動デプロイをセットアップします。"
echo "developブランチを作成し、自動デプロイをトリガーします。"

# Gitがインストールされているか確認
if ! command -v git &> /dev/null; then
  echo "Error: Gitがインストールされていません。"
  echo "https://git-scm.com/downloads からインストールしてください。"
  exit 1
fi

# カレントブランチの確認
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "現在のブランチ: $CURRENT_BRANCH"

# GitHub Secretsの確認
echo "GitHub Secretsの設定を確認してください："
echo "1. AZURE_CREDENTIALS"
echo "2. ACR_LOGIN_SERVER"
echo "3. ACR_USERNAME"
echo "4. ACR_PASSWORD"
read -p "上記のGitHub Secretsは設定しましたか？(y/n): " SECRETS_CONFIRMED
if [ "$SECRETS_CONFIRMED" != "y" ]; then
  echo "GitHub Secretsを設定してから再実行してください。"
  exit 1
fi

# Slackの通知設定（オプション）
read -p "Slack通知を設定しますか？(y/n): " SETUP_SLACK
if [ "$SETUP_SLACK" = "y" ]; then
  read -p "Slack Webhook URLを入力してください: " SLACK_WEBHOOK
  echo "GitHub Secretsに 'SLACK_WEBHOOK' を追加してください。"
fi

# developブランチの作成と切り替え
echo "developブランチを作成しています..."
git checkout -b develop 2>/dev/null || git checkout develop

# ワークフローファイルの確認
echo "デプロイワークフローファイルを確認しています..."
cat .github/workflows/03-deploy-dev.yml

# 開発環境用の変更をするか（オプション）
read -p "開発環境用の変更を加えますか？(y/n): " MAKE_CHANGES
if [ "$MAKE_CHANGES" = "y" ]; then
  # フロントエンドに変更を加える例
  echo "// Development environment test change" >> frontend/pages/index.tsx
  echo "フロントエンドに変更を加えました。"
fi

# 変更をコミットしてプッシュ
read -p "変更をコミットしてプッシュしますか？(y/n): " PUSH_CHANGES
if [ "$PUSH_CHANGES" = "y" ]; then
  echo "変更をコミットしてプッシュしています..."
  git add .
  git commit -m "Setup development environment for automatic deployment"
  git push -u origin develop

  echo "GitHubリポジトリのActionsタブでワークフローの実行を確認してください。"
  echo "URL: https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:\/]\(.*\)\.git/\1/')/actions"
else
  echo "変更はコミットされませんでした。"
  echo "後で手動でコミットしてプッシュしてください："
  echo "git add ."
  echo "git commit -m \"Setup development environment for automatic deployment\""
  echo "git push -u origin develop"
fi

# デプロイの確認手順
echo ""
echo "デプロイが完了したら、以下のURLで開発環境を確認してください："
echo "フロントエンド: https://simple-memo-app-frontend-dev.azurewebsites.net"
echo "バックエンドAPI: https://simple-memo-app-backend-dev.azurewebsites.net/docs"
echo ""
echo "次のステップに進むには:"
echo "scripts/setup-step4.sh を実行してください。"
