#!/bin/bash
set -e

# 環境変数を.envファイルから読み込む
if [ -f .env ]; then
    source .env
else
    echo ".env file not found. Exiting."
    exit 1
fi

# WORKDIR 環境変数が定義されていない場合のデフォルト値
WORKDIR=${WORKDIR:-"workdir"}
INTERMEDIATE_DIR=${INTERMEDIATE_DIR:-"intermediate"}
BACKUP_DIR=${BACKUP_DIR:-"${WORKDIR}/backup"}

# バックアップディレクトリの作成
mkdir -p "$BACKUP_DIR"

echo "Backing up intermediate files from $WORKDIR/$INTERMEDIATE_DIR to $BACKUP_DIR..."

# 中間ファイルを検索してバックアップディレクトリにコピー
find "$WORKDIR/$INTERMEDIATE_DIR" -maxdepth 1 -type f \( \
    -name "*.aux" -o -name "*.log" -o -name "*.out" -o \
    -name "*.dvi" -o -name "*.bbl" -o -name "*.blg" -o \
    -name "*.fls" -o -name "*.fdb_latexmk" -o -name "*.toc" \
\) -exec cp {} "$BACKUP_DIR/" \;

echo "Backup completed."