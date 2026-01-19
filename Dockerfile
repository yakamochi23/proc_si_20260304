# ベースイメージとしてUbuntuを指定
FROM ubuntu:22.04

# 必要なパッケージをインストール
RUN apt-get update && apt-get install -y --no-install-recommends \
	curl \
	tar \
	perl \
	fontconfig \
	libfreetype6-dev \
	unzip \
	wget \
	xz-utils \
	ca-certificates \
	&& apt-get clean && rm -rf /var/lib/apt/lists/*

# TeXLive 2025のインストール
RUN mkdir /tmp/install-tl-unx && \
	curl -L ftp://tug.org/historic/systems/texlive/2025/install-tl-unx.tar.gz | \
	tar -xz -C /tmp/install-tl-unx --strip-components=1 && \
	printf "%s\n" \
	"selected_scheme scheme-basic" \
	"tlpdbopt_install_docfiles 0" \
	"tlpdbopt_install_srcfiles 0" \
	> /tmp/install-tl-unx/texlive.profile && \
	/tmp/install-tl-unx/install-tl --profile=/tmp/install-tl-unx/texlive.profile && \
	TEXLIVE_BIN=$(find /usr/local/texlive/2025/bin -type d -name "*linux*") && \
	export PATH="$TEXLIVE_BIN:$PATH" && \
	$TEXLIVE_BIN/tlmgr install \
	collection-latexextra \
	collection-fontsrecommended \
	collection-langjapanese \
	latexmk \
	type1cm \
	framed \
	moreverb \
	multirow && \
	rm -fr /tmp/install-tl-unx


# TeXLiveのインストール後の処理
RUN TEXLIVE_BIN=$(find /usr/local/texlive/2025/bin -type d -name "*linux*") && \
	echo "export PATH=${TEXLIVE_BIN}:\$PATH" >> /etc/profile.d/texlive.sh

# 環境変数を永続化
# x86_64用
ENV PATH="/usr/local/texlive/2025/bin/x86_64-linux:$PATH" 
# ARM64用
#ENV PATH="/usr/local/texlive/2025/bin/aarch64-linux:$PATH" 

# カスタムモジュールのインストール用ディレクトリ設定
ARG TEXMFLOCAL=/usr/local/texlive/texmf-local/tex/latex
WORKDIR /workspace

# jlistingモジュールのインストール
RUN wget http://captain.kanpaku.jp/LaTeX/jlisting.zip \
	&& unzip jlisting.zip \
	&& mkdir -p ${TEXMFLOCAL}/listings \
	&& cp jlisting/jlisting.sty ${TEXMFLOCAL}/listings

# algorithmsモジュールのインストール
RUN wget http://mirrors.ctan.org/macros/latex/contrib/algorithms.zip \
	&& unzip algorithms.zip \
	&& cd algorithms \
	&& TEXLIVE_BIN=$(find /usr/local/texlive/2025/bin -type d -name "*linux*") \
	&& export PATH="$TEXLIVE_BIN:$PATH" \
	&& latex algorithms.ins \
	&& mkdir -p ${TEXMFLOCAL}/algorithms \
	&& cp *.sty ${TEXMFLOCAL}/algorithms

# algorithmicxモジュールのインストール
RUN wget http://mirrors.ctan.org/macros/latex/contrib/algorithmicx.zip \
	&& unzip algorithmicx.zip \
	&& mkdir -p ${TEXMFLOCAL}/algorithmicx \
	&& cp algorithmicx/*.sty ${TEXMFLOCAL}/algorithmicx

# junsrt.bst を適切なディレクトリにコピーし、データベースを更新
RUN mkdir -p /usr/local/texlive/texmf-local/bibtex/bst/japanese && \
	cp /usr/local/texlive/2025/texmf-dist/pbibtex/bst/junsrt.bst /usr/local/texlive/texmf-local/bibtex/bst/japanese/

#RUN	mktexlsr /usr/local/texlive/texmf-local 

RUN TEXLIVE_BIN=$(find /usr/local/texlive/2025/bin -type d -name "*linux*") && \
    $TEXLIVE_BIN/mktexlsr /usr/local/texlive/texmf-local

# TeXLiveディレクトリの権限調整
RUN chmod -R 777 /usr/local/texlive

# 非rootユーザーを追加
ARG UID=1000
RUN useradd -m -u ${UID} latex
USER latex

# 作業ディレクトリを設定
WORKDIR /workdir

# デフォルトのシェルを起動
CMD ["bash"]