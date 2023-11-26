# apt-get出来る様にdebian版を使う。
FROM mysql:8.0.30-debian
# コンテナ内で日本語が打てるようにlocalesを変更と、いらないファイル削除する
RUN apt-get update \
    && apt-get install -y locales \
    && sed -i -E 's/# (ja_JP.UTF-8)/\1/' /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=ja_JP.UTF-8 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
ENV LC_ALL ja_JP.UTF-8
