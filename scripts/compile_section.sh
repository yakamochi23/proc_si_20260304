#!/bin/bash
set -e

# .envファイルの読み込み
if [ -f .env ]; then
    source .env
else
    echo ".env file not found. Exiting."
    exit 1
fi

# 引数からセクション名を取得
SECTION=${1}
if [ -z "$SECTION" ]; then
    echo "Usage: $0 <section>"
    exit 1
fi

# セクションファイルのパスを計算
SECTION_FILE="${WORKDIR}/${SECTION}.tex"

# セクションファイルが存在するか確認
if [ ! -f "$SECTION_FILE" ]; then
    echo "Section file not found: $SECTION_FILE"
    exit 1
fi

# 親ファイルを特定（awkを使用して親ファイルを抽出）
PARENT_FILE=$(awk -F'[][]' '/\\documentclass\[.*\]{subfiles}/ {print $2}' "$SECTION_FILE")
if [ -z "$PARENT_FILE" ]; then
    echo "No parent file specified in \\documentclass. Assuming standalone file."
    PARENT_FILE="$SECTION"
else
    # 相対パスを解決（コンテナ内では /workdir を基準とする）
    PARENT_FILE=$(cd "$(dirname "$SECTION_FILE")" && cd "$(dirname "$PARENT_FILE")" && pwd)/$(basename "$PARENT_FILE")
fi

# 親ファイルの存在確認
if [ ! -f "${PARENT_FILE}" ]; then
    echo "Parent file not found: ${PARENT_FILE}"
    exit 1
fi

# コンパイル用のパス（コンテナ内パス）を準備
SECTION_FILE_IN_CONTAINER="/workdir/${SECTION}.tex"
PARENT_FILE_IN_CONTAINER="/workdir/$(basename "${PARENT_FILE}")"

# コンパイル処理
echo "Compiling section: $SECTION_FILE_IN_CONTAINER with parent: $PARENT_FILE_IN_CONTAINER..."
docker container run --rm \
    -v "${PWD}/${WORKDIR}:/workdir" \
    -w /workdir \
    ${IMAGE} \
    bash -c "\
    set -e && \
    uplatex -kanji=utf8 ${SECTION_FILE_IN_CONTAINER} || { echo 'uplatex failed'; exit 1; } && \
    upbibtex -kanji=utf8 ${SECTION} || { echo 'BibTeX failed'; exit 1; } && \
    uplatex -kanji=utf8 ${SECTION_FILE_IN_CONTAINER} || { echo 'uplatex (2nd run) failed'; exit 1; } && \
    uplatex -kanji=utf8 ${SECTION_FILE_IN_CONTAINER} || { echo 'uplatex (3rd run) failed'; exit 1; } && \
    dvipdfmx -f ptex-ipaex.map ${SECTION}.dvi || { echo 'dvipdfmx failed'; exit 1; } \
    "

echo "Section compiled successfully: ${WORKDIR}/${SECTION}.pdf"

