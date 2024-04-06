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

### データが挿入されているか確認する
```bash
root@389dc4753296:/# mysql -u root -proot demo
mysql: [Warning] Using a password on the command line interface can be insecure.
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 22
Server version: 8.0.30 MySQL Community Server - GPL

Copyright (c) 2000, 2022, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> select COUNT(*) from sales_logs;
+----------+
| COUNT(*) |
+----------+
|  1000000 |
+----------+
1 row in set (0.31 sec)

mysql> 
```
