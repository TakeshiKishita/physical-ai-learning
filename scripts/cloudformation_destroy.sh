#!/bin/bash
# CloudFormationスタックの削除スクリプト

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_NAME="isaac-sim-stack"

# AWS CLIの確認
if ! command -v aws &> /dev/null; then
    echo "❌ エラー: AWS CLIがインストールされていません"
    exit 1
fi

# リージョンの取得
AWS_REGION=$(aws configure get region || echo "ap-northeast-1")

echo "⚠️  CloudFormationスタックを削除します..."
echo "   スタック名: ${STACK_NAME}"
echo "   リージョン: ${AWS_REGION}"
echo ""

# スタックの存在確認
if ! aws cloudformation describe-stacks --stack-name "${STACK_NAME}" --region "${AWS_REGION}" &> /dev/null; then
    echo "⚠️  スタックが見つかりません"
    exit 0
fi

# 確認
echo "⚠️  警告: スタックとすべてのリソースが削除されます"
read -p "本当に削除しますか？ (yes と入力): " -r
if [[ ! $REPLY == "yes" ]]; then
    echo "キャンセルしました"
    exit 0
fi

# スタックの削除
echo "⏳ スタックを削除中..."
aws cloudformation delete-stack \
    --stack-name "${STACK_NAME}" \
    --region "${AWS_REGION}"

echo "⏳ スタックの削除を待機中..."
aws cloudformation wait stack-delete-complete \
    --stack-name "${STACK_NAME}" \
    --region "${AWS_REGION}"

echo "✅ スタックを削除しました"

