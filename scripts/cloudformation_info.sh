#!/bin/bash
# CloudFormationスタック情報表示スクリプト

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

# スタックの存在確認
if ! aws cloudformation describe-stacks --stack-name "${STACK_NAME}" --region "${AWS_REGION}" &> /dev/null; then
    echo "⚠️  スタックが見つかりません: ${STACK_NAME}"
    exit 0
fi

echo "📊 CloudFormationスタック情報"
echo "   スタック名: ${STACK_NAME}"
echo "   リージョン: ${AWS_REGION}"
echo ""

# スタックの状態
STACK_STATUS=$(aws cloudformation describe-stacks \
    --stack-name "${STACK_NAME}" \
    --query 'Stacks[0].StackStatus' \
    --output text \
    --region "${AWS_REGION}")

echo "   状態: ${STACK_STATUS}"
echo ""

# 出力の表示
echo "📋 スタック出力:"
aws cloudformation describe-stacks \
    --stack-name "${STACK_NAME}" \
    --query 'Stacks[0].Outputs' \
    --output table \
    --region "${AWS_REGION}"

echo ""
echo "📦 スタックリソース:"
aws cloudformation describe-stack-resources \
    --stack-name "${STACK_NAME}" \
    --query 'StackResources[*].[ResourceType,LogicalResourceId,PhysicalResourceId,ResourceStatus]' \
    --output table \
    --region "${AWS_REGION}"

