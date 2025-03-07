#!/bin/bash
# ステップ1：基本的なDockerイメージのビルドとテストのセットアップ

echo "====== ステップ1: 基本的なDockerイメージのビルドとテスト ======"
echo "このスクリプトは、Dockerイメージをローカルでビルドしてテストします。"

# ディレクトリの確認
if [ ! -d "./backend" ] || [ ! -d "./frontend" ]; then
  echo "Error: backendまたはfrontendディレクトリが見つかりません。"
  echo "リポジトリのルートディレクトリで実行してください。"
  exit 1
fi

# Dockerがインストールされているか確認
if ! command -v docker &> /dev/null; then
  echo "Error: Dockerがインストールされていません。"
  echo "https://docs.docker.com/get-docker/ からインストールしてください。"
  exit 1
fi

# Docker Composeがインストールされているか確認
if command -v docker-compose &> /dev/null; then
  DOCKER_COMPOSE="docker-compose"
else
  DOCKER_COMPOSE="docker compose"
fi

echo "Docker環境を確認しています..."
docker --version
$DOCKER_COMPOSE --version

echo "Dockerイメージをビルドしています..."
$DOCKER_COMPOSE build

echo "ローカル環境でDockerコンテナを起動しています..."
echo "起動後、Ctrl+Cで停止できます。"
echo "別のターミナルで以下のURLにアクセスして動作確認してください："
echo "フロントエンド: http://localhost:3000"
echo "バックエンドAPI: http://localhost:8000/docs"

$DOCKER_COMPOSE up

echo "ステップ1が完了しました。"
echo "次に進む前に以下を確認してください："
echo "1. フロントエンドとバックエンドのDockerイメージが正常にビルドされたか"
echo "2. コンテナが正常に起動し、アプリケーションにアクセスできたか"
echo "3. GitHub Actionsワークフローファイル(.github/workflows/01-docker-build-test.yml)の内容を確認"
echo ""
echo "次のステップに進むには:"
echo "scripts/setup-step2.sh を実行してください。"
