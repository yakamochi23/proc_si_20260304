#!/bin/bash
set -e

# .envファイルを読み込む
if [ -f .env ]; then
    source .env
else
    echo ".env file not found. Exiting."
    exit 1
fi

# 第一引数が指定されない場合、デフォルトのログファイルを使用
LOG_FILE=${1:-"${LOG_FILE}"}

# ログファイルの存在確認
if [ ! -f "$LOG_FILE" ]; then
    echo "Log file not found: $LOG_FILE" # 存在しなければエラーを表示
    exit 1
fi

echo "Analyzing errors in $LOG_FILE..."

# 1. ログファイルから "error"（大文字・小文字を区別しない） に関連する行（前後2行を含む）を抽出
echo -e "\n=== Errors (with context) ==="
grep -i -B 2 -A 2 "error" "$LOG_FILE" || echo "No errors found."

# 2. 警告の抽出
echo -e "\n=== Warnings ==="
grep -i "warning" "$LOG_FILE" || echo "No warnings found."

# 3. エラーと警告の統計情報
ERROR_COUNT=$(grep -i "error" "$LOG_FILE" | wc -l) # エラーの数をカウント
WARNING_COUNT=$(grep -i "warning" "$LOG_FILE" | wc -l) # 警告の数をカウント
echo -e "\n=== Summary ==="
echo "Total errors found: $ERROR_COUNT"
echo "Total warnings found: $WARNING_COUNT"

# 4. 特定のエラータイプ（例: Undefined control sequence）の検出
echo -e "\n=== Specific Error: Undefined control sequence ==="
grep -i "undefined control sequence" "$LOG_FILE" || echo "No 'Undefined control sequence' errors found."

# 5. ログ全体で該当箇所の周辺を表示（エラー前後10行を調査したい場合）
#echo -e "\n=== Errors with full context (10 lines before and after) ==="
#grep -i -B 10 -A 10 "error" "$LOG_FILE" || echo "No errors found with extended context."