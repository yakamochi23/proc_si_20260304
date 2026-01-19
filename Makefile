# 環境変数のロード
ifneq (,$(wildcard .env))  # .envファイルが存在する場合
    include .env           # .envファイルを読み込む
    export                 # 読み込んだ値をエクスポート
endif

# デフォルト値（.env に未定義の場合に使われる）
SOURCE ?= Dockerfile
IMAGE ?= texlive2025:latest
WORKDIR ?= workdir
OUTPUT_DIR ?= output
INTERMEDIATE_DIR ?= intermediate
TARGET ?= main
SECTION_DIR ?= sections

# コンテナイメージのビルド
.PHONY: build
build: Dockerfile
	docker image build -f ${SOURCE} -t ${IMAGE} .

# コンテナにログインしてシェルを起動
.PHONY: shell
shell:
	docker container run -it --rm \
		-v ${PWD}/${WORKDIR}:/workdir \
		-w /workdir \
		${IMAGE} \
		bash

# コンテナ内でTeXLiveのバージョンを確認
.PHONY: version
version:
	docker container run -it --rm \
		-v ${PWD}/${WORKDIR}:/workdir \
		-w /workdir \
		${IMAGE} \
		bash -c "latex --version"

# .texファイルをPDFにコンパイル (BibTeX を含む)
.PHONY: compile
compile:
	docker container run --rm \
		-v ${PWD}/${WORKDIR}:/workdir \
		-w /workdir \
		${IMAGE} \
		bash -c "\
		set -e && \
		mkdir -p ${OUTPUT_DIR} ${INTERMEDIATE_DIR} && \
		sed -i 's/、/，/g' ${TARGET}.tex && \
		sed -i 's/。/．/g' ${TARGET}.tex && \
		find ${SECTION_DIR} -type f -name '*.tex' -exec sed -i 's/、/，/g' {} + && \
		find ${SECTION_DIR} -type f -name '*.tex' -exec sed -i 's/。/．/g' {} + && \
		uplatex -kanji=utf8 -output-directory=${INTERMEDIATE_DIR} ${TARGET}.tex || { echo 'uplatex failed'; exit 1; } && \
		if grep -q '\\citation' ${INTERMEDIATE_DIR}/${TARGET}.aux 2>/dev/null; then \
			upbibtex -kanji=utf8  ${INTERMEDIATE_DIR}/${TARGET} || { echo 'upbibtex failed'; exit 1; } && \
			uplatex -kanji=utf8 -output-directory=${INTERMEDIATE_DIR} ${TARGET}.tex || { echo 'uplatex (2nd run) failed'; exit 1; } && \
			uplatex -kanji=utf8 -output-directory=${INTERMEDIATE_DIR} ${TARGET}.tex || { echo 'uplatex (3rd run) failed'; exit 1; };\
		else \
			echo 'No citations found, skipping upbibtex and additional uplatex runs'; \
		fi && \
		dvipdfmx -f ptex-ipaex.map -o ${OUTPUT_DIR}/${TARGET}.pdf ${INTERMEDIATE_DIR}/${TARGET}.dvi || { echo 'dvipdfmx failed'; exit 1; } \
		"

# サブファイルをコンパイル
.PHONY: compile-section
compile-section:
	docker container run --rm \
		-v ${PWD}/${WORKDIR}:/workdir \
		-w /workdir \
		${IMAGE} \
		bash -c "\
		set -e && \
		mkdir -p ${OUTPUT_DIR} ${INTERMEDIATE_DIR} && \
		find ${SECTION_DIR} -type f -name '*.tex' -exec sed -i 's/、/，/g' {} + && \
		find ${SECTION_DIR} -type f -name '*.tex' -exec sed -i 's/。/．/g' {} + && \
		uplatex -kanji=utf8 -output-directory=${INTERMEDIATE_DIR} ${SECTION_DIR}/${TARGET}.tex || { echo 'uplatex failed'; exit 1; } && \
		if grep -q '\\citation' ${INTERMEDIATE_DIR}/${TARGET}.aux 2>/dev/null; then \
			upbibtex -kanji=utf8 ${INTERMEDIATE_DIR}/${TARGET} || { echo 'upbibtex failed'; exit 1; } && \
			uplatex -kanji=utf8 -output-directory=${INTERMEDIATE_DIR} ${SECTION_DIR}/${TARGET}.tex || { echo 'uplatex (2nd run) failed'; exit 1; } && \
			uplatex -kanji=utf8 -output-directory=${INTERMEDIATE_DIR} ${SECTION_DIR}/${TARGET}.tex || { echo 'uplatex (3rd run) failed'; exit 1; }; \
		else \
			echo 'No citations found, skipping upbibtex and additional uplatex runs'; \
		fi && \
		dvipdfmx -f ptex-ipaex.map -o ${OUTPUT_DIR}/${TARGET}.pdf ${INTERMEDIATE_DIR}/${TARGET}.dvi || { echo 'dvipdfmx failed'; exit 1; } \
		"

# 中間ファイルを削除
.PHONY: clean
clean:
	rm -f ${WORKDIR}/${INTERMEDIATE_DIR}/*

# サブファイルの中間ファイルを削除
.PHONY: clean-section
clean-section:
	rm -f ${WORKDIR}/${INTERMEDIATE_DIR}/${SECTION}.*


# すべての生成物を削除
.PHONY: clean-all
clean-all: clean
	rm -f ${WORKDIR}/${OUTPUT_DIR}/${TARGET}.pdf

# ログファイルの表示
.PHONY: logs
logs:
	@cat ${WORKDIR}/${INTERMEDIATE_DIR}/${TARGET}.log

# ログファイルから重要なエラーメッセージを抽出
.PHONY: analyze
analyze:
	bash scripts/analyze_errors.sh ${WORKDIR}/${INTERMEDIATE_DIR}/${TARGET}.log


# 中間ファイルをバックアップ
.PHONY: backup
backup:
	bash scripts/backup.sh ${WORKDIR}/${INTERMEDIATE_DIR}

# 停止済みコンテナを削除
.PHONY: docker-clean
docker-clean:
	docker container prune -f

# .texファイルを.htmlファイルに変換する
.PHONY: html
html:
	docker container run --rm \
		-v ${PWD}/${WORKDIR}:/workdir \
		-w /workdir \
		${IMAGE} \
		bash -c "\
		latexml ${TARGET}.tex > ${INTERMEDIATE_DIR}/${TARGET}.xml && \
		latexmlpost ${INTERMEDIATE_DIR}/${TARGET}.xml > ${OUTPUT_DIR}/${TARGET}.html || { echo 'LaTeXML failed'; exit 1; }"

# デフォルトターゲット
.PHONY: all
all: compile