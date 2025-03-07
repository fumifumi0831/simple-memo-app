#!/bin/bash
# スクリプトを実行可能にする

echo "セットアップスクリプトを実行可能にしています..."
chmod +x scripts/setup-step1.sh
chmod +x scripts/setup-step2.sh
chmod +x scripts/setup-step3.sh
chmod +x scripts/setup-step4.sh
chmod +x scripts/setup-step5.sh

echo "実行権限を付与しました。"
echo "以下のコマンドでステップ1から開始できます："
echo "./scripts/setup-step1.sh"
