#!/bin/bash
# CloudFormationスタックのデプロイスクリプト

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
STACK_NAME="isaac-sim-stack"
TEMPLATE_FILE="${PROJECT_ROOT}/cloudformation/isaac-sim-stack.yaml"
PARAMETERS_FILE="${PROJECT_ROOT}/cloudformation/parameters.json"

# AWS CLIの確認
if ! command -v aws &> /dev/null; then
    echo "❌ エラー: AWS CLIがインストールされていません"
    exit 1
fi

# AWS認証情報の確認
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ エラー: AWS認証情報が設定されていません"
    exit 1
fi

# リージョンの取得
AWS_REGION=$(aws configure get region || echo "ap-northeast-1")

echo "🚀 CloudFormationスタックをデプロイします..."
echo "   スタック名: ${STACK_NAME}"
echo "   リージョン: ${AWS_REGION}"
echo ""

# パラメータファイルの確認
if [ ! -f "${PARAMETERS_FILE}" ]; then
    echo "⚠️  警告: ${PARAMETERS_FILE} が見つかりません"
    echo "   パラメータをコマンドラインで指定しますか？ (y/N)"
    read -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "キャンセルしました"
        exit 0
    fi
    USE_PARAMETERS_FILE=""
else
    USE_PARAMETERS_FILE="--parameters file://${PARAMETERS_FILE}"
fi

# スタックの存在確認
if aws cloudformation describe-stacks --stack-name "${STACK_NAME}" --region "${AWS_REGION}" &> /dev/null; then
    echo "📝 既存のスタックを更新します..."
    aws cloudformation update-stack \
        --stack-name "${STACK_NAME}" \
        --template-body "file://${TEMPLATE_FILE}" \
        ${USE_PARAMETERS_FILE} \
        --capabilities CAPABILITY_NAMED_IAM \
        --region "${AWS_REGION}" \
        > /dev/null
    
    echo "⏳ スタックの更新を待機中..."
    aws cloudformation wait stack-update-complete \
        --stack-name "${STACK_NAME}" \
        --region "${AWS_REGION}"
else
    echo "📝 新しいスタックを作成します..."
    aws cloudformation create-stack \
        --stack-name "${STACK_NAME}" \
        --template-body "file://${TEMPLATE_FILE}" \
        ${USE_PARAMETERS_FILE} \
        --capabilities CAPABILITY_NAMED_IAM \
        --region "${AWS_REGION}" \
        > /dev/null
    
    echo "⏳ スタックの作成を待機中..."
    aws cloudformation wait stack-create-complete \
        --stack-name "${STACK_NAME}" \
        --region "${AWS_REGION}"
fi

# 出力の表示
echo ""
echo "✅ スタックのデプロイが完了しました！"
echo ""
echo "📋 スタック情報:"
aws cloudformation describe-stacks \
    --stack-name "${STACK_NAME}" \
    --query 'Stacks[0].Outputs' \
    --output table \
    --region "${AWS_REGION}"

echo ""
echo "🔗 次のステップ:"
echo "   - インスタンス情報: aws cloudformation describe-stacks --stack-name ${STACK_NAME}"
echo "   - スタック削除: aws cloudformation delete-stack --stack-name ${STACK_NAME}"

