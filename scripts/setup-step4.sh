#!/bin/bash
# ステップ4：本番環境への承認付きデプロイのセットアップ

echo "====== ステップ4: 本番環境への承認付きデプロイ ======"
echo "このスクリプトは、本番環境への承認付きデプロイをセットアップします。"
echo "GitHub上で承認ワークフローを設定し、本番環境へのデプロイをトリガーします。"

# GitHub CLI（gh）があるか確認（オプション）
HAS_GH=false
if command -v gh &> /dev/null; then
  HAS_GH=true
  echo "GitHub CLIが見つかりました。環境設定を自動化できます。"
else
  echo "GitHub CLIが見つかりません。手動で環境設定を行う必要があります。"
  echo "インストールするには: https://cli.github.com/"
fi

# GitHub環境設定の手順
echo ""
echo "【重要】本番環境の承認ワークフローを設定するには："
echo "1. GitHubリポジトリの 'Settings' → 'Environments' に移動"
echo "2. 'New environment' をクリック"
echo "3. 環境名として 'production' を入力"
echo "4. 'Required reviewers' にチェックを入れる"
echo "5. 承認者として自分自身または必要な承認者を追加"
echo "6. 'Save protection rules' をクリック"
echo ""

# 承認ワークフロー確認
read -p "GitHub上で 'production' 環境の設定を行いましたか？(y/n): " ENVIRONMENT_CONFIRMED
if [ "$ENVIRONMENT_CONFIRMED" != "y" ]; then
  echo "GitHub上で環境設定を行ってから再実行してください。"
  exit 1
fi

# ワークフローファイルの確認
echo "本番デプロイワークフローファイルを確認しています..."
cat .github/workflows/04-deploy-prod.yml

# 現在のブランチを確認
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "現在のブランチ: $CURRENT_BRANCH"

# developブランチから最新の変更を取得
if [ "$CURRENT_BRANCH" != "develop" ]; then
  echo "developブランチに切り替えて最新の変更を取得します..."
  git checkout develop
  git pull origin develop
fi

# mainブランチにマージする準備
echo "mainブランチにマージする準備をしています..."
git checkout main
git pull origin main

# developからmainへマージ
echo "developブランチからmainブランチへマージします..."
git merge develop

# 本番環境用の微調整
read -p "本番環境用に追加の変更を加えますか？(y/n): " MAKE_PROD_CHANGES
if [ "$MAKE_PROD_CHANGES" = "y" ]; then
  # 本番環境用の変更を加える例
  echo "// Production environment configuration" >> frontend/pages/index.tsx
  echo "フロントエンドに本番環境用の変更を加えました。"
fi

# 変更をコミットしてプッシュ
read -p "変更をコミットしてmainブランチにプッシュしますか？(y/n): " PUSH_CHANGES
if [ "$PUSH_CHANGES" = "y" ]; then
  echo "変更をコミットしてプッシュしています..."
  git add .
  git commit -m "Prepare for production deployment with approval workflow"
  git push origin main

  echo "GitHubリポジトリのActionsタブでワークフローの実行を確認してください。"
  echo "URL: https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:\/]\(.*\)\.git/\1/')/actions"
  
  echo ""
  echo "【重要】承認プロセスを開始するには："
  echo "1. GitHubリポジトリのActionsタブで実行中のワークフローを見つける"
  echo "2. ワークフローをクリックして詳細を表示"
  echo "3. 'Review deployments'ボタンをクリック"
  echo "4. 'production'環境を選択し、コメントを入力（オプション）"
  echo "5. 'Approve and deploy'をクリック"
else
  echo "変更はコミットされませんでした。"
  echo "後で手動でコミットしてプッシュしてください："
  echo "git add ."
  echo "git commit -m \"Prepare for production deployment with approval workflow\""
  echo "git push origin main"
fi

# デプロイの確認手順
echo ""
echo "承認後、デプロイが完了したら、以下のURLで本番環境を確認してください："
echo "フロントエンド: https://simple-memo-app-frontend-prod.azurewebsites.net"
echo "バックエンドAPI: https://simple-memo-app-backend-prod.azurewebsites.net/docs"
echo ""
echo "次のステップに進むには:"
echo "scripts/setup-step5.sh を実行してください。"
