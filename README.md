# mysql-sandbox
mysqlsandbox環境リポジトリ。
SQLに関する学びは docs/ 以下に配置します。

## 環境構築
以下のドキュメントを参照して環境構築して下さい。
- [SQLの砂場環境の構築](infra/README.md)

## 輪読会の目的
- 実際にクエリを実行してみて、どういう時に使えるかイメージする。
  - railsアプリケーション上でどのように使えるか？
  - ISUCONでどのように使えるか？
  - 直叩きSQLでどのようなシーンで使えそうか？（実務のちょっとした調査とか）

## seedデータについて
### seedデータを挿入するSQLを生成する方法
**※ ruby2.7以上まであげてください。**
```bash
# prefectureの場合
$ ruby lib/generate_bulk_sql/prefectures.rb > sql/seed/insert/prefectures.sql

# employee_rostersの場合
$ ruby lib/generate_bulk_sql/employee_rosters.rb 10001 > sql/seed/insert/employee_rosters.sql

# sales_logsの場合
$ ruby lib/generate_bulk_sql/sales_logs.rb 10001 > sql/seed/insert/sales_logs.sql
```

### seedデータ挿入方法
ホストマシンからmysql clientを利用して挿入する場合
```bash
$ mysql -u root -h 127.0.0.1 --port 3308 -proot demo < hoge.sql
```

コンテナのシェルに接続して挿入する場合
```bash
$ docker exec -it database bin/bash
$ mysql -u root -proot demo < usr/scripts/seed/insert/employee_rosters.sql
```
