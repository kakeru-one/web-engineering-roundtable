# SQLの砂場環境の構築
## 環境
MySQL 8.0.30
Docker(Debian)
## setup方法
```bash
# まずbuildする
$ docker compose -f infra/docker-compose.yml build

# dockerのDBコンテナの立ち上げ。
# （もしくは、`bin/compose-up`でも可能です。）
$ docker compose up -d
もしくは、

# コンテナに入る。
# （もしくは、`bin/exec-bash database`でも可能です。）
$ docker exec -it database bash

# コンテナ内でMySQLクライアントを使う。
$ mysql -u root -proot
```

## dumpの取り方
```bash
# user_nameはroot、passwordもrootとする。

# 全てのdumpを取りたい場合
$ mysqldump -u root -proot [データベース名] > dump.sql

# dumpを元に復元する場合
$ mysql -u root -proot [データベース名] < dump.sql
```

### 実行例
```bash
$ mysqldump -u root -proot isucon > dump.sql
```
