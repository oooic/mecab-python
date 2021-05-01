FROM python:3.8-buster

LABEL maintainer "kota oishi <1persongloria@gmail.com>"

# 作業ディレクトリを作り移動する
WORKDIR /work

# localesと日本語フォントのインストール
RUN apt update \
    && apt -y install --no-install-recommends \
    locales \
    fonts-takao \
    && sed -i -e 's/# ja_JP.UTF-8 UTF-8/ja_JP.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen \
    && apt clean \
    && fc-cache -fv

RUN wget -O mecab-0.996.tar.gz "https://drive.google.com/uc?export=download&id=0B4y35FiV1wh7cENtOXlicTFaRUE"
RUN wget -O mecab-ipadic-2.7.0-20070801.tar.gz "https://drive.google.com/uc?export=download&id=0B4y35FiV1wh7MWVlSDBCSXZMTXM"

# MeCabインストール
# ldconfigはライブラリパスのキャッシュ更新用
RUN tar zxvf mecab-0.996.tar.gz \
    && cd mecab-0.996 \
    && ./configure \
    && make \
    && make check \
    && make install \
    && ldconfig \
    && cd ../ \
    && rm -rf mecab-0.996

# IPA辞書インストール
# 半角記号が名詞・サ変接続になるのを記号・一般に変更
RUN tar zxvf mecab-ipadic-2.7.0-20070801.tar.gz \
    && cd mecab-ipadic-2.7.0-20070801 \
    && iconv -f eucjp -t utf8 unk.def > unk_utf8.def \
    && sed -i -e 's/SYMBOL,1283,1283,17585,名詞,サ変接続,\*,\*,\*,\*,\*/SYMBOL,1283,1283,17585,記号,一般,\*,\*,\*,\*,\*/' unk_utf8.def \
    && mv unk.def unk.def.original \
    && iconv -f utf8 -t eucjp unk_utf8.def > unk.def \
    && ./configure --with-charset=utf8 --enable-utf8-only \
    && make \
    && make install \
    && cp unk.def /usr/local/lib/mecab/dic/ipadic \
    && cd ../ \
    && rm -rf mecab-ipadic-2.7.0-20070801

# ロケールの設定
ENV    LANG="ja_JP.UTF-8" \
    LANGUAGE="ja_JP:ja" \
    LC_ALL="ja_JP.UTF-8"

# MeCabのPythonラッパーインストール
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# インストールに使用したファイルを削除
RUN rm -rf /work/*
