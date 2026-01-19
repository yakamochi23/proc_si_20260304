# 論文執筆プロジェクト

## プロジェクト概要

このプロジェクトは、論文を執筆するための構成とファイル群を含んでいます。

## ディレクトリ構成

- `workdir/`: 論文の本文やスタイルファイルを格納
   - `backup/`: 中間ファイルを一時的に保存
   - `bibliography/`: 参考文献データを管理
   - `figures/`: 図表を管理
   - `sections/`: 各セクション（章）ごとの LaTeX ファイルを管理
   - `styles/`: スタイルファイルを格納

## セットアップ

1. Dockerをローカル環境にインストール
2. `Makefile` または `latexmk` を使用してコンパイルできます。
3. このリポジトリをクローンする
   ```bash
   git clone <url> 
   ```
4. Dockerfileをbuildして、コンテナイメージを作成。（`make`コマンドで行えます。）
   ```bash
   cd b4thesis
   make build
   ```

## コンパイル手順

1. `.env`ファイルでコンパイルtargetのコメントを解除
   ```bash
   #TARGET=main
   #TARGET=abst
   #TARGET=chapter1
   TARGET=chapter2
   #TARGET=chapter3
   #TARGET=chapter4
   #TARGET=chapter5
   #TARGET=acknowledgment
   ```

2. `make` コマンドでコンパイル。（ルートディレクトリで実行することに注意）
   ```bash
   cd b4thesis

   make compile # TARGET=main の場合
   
   make compile-section # それ以外のTARGETの場合
   ```
