# ロックについて
## メタデータロック
- テーブル構造に対してかけるロックのこと。
- ロックを取るまでにかかる時間は一瞬だが、そのロックしている間の処理が終わるわけではない。
  - 以下のSQL文で、メタデータロックを取る。ロックが解放されるのは、トランザクションの終了まで。
    - 排他メタデータロックが必要
      - ALTER TABLE
    - 共有書き込みメタデータロックが必要
      - SELECT
      - INSERT
      - UPDATE
      - DELETE

ちなみに、以下の記事がすごくわかりやすかった。
- https://gihyo.jp/article/2022/09/mysql-rcn0180

### 排他メタデータロック
`CREATE TABLE` / `DROP TABLE` / `ALTER TABLE` は排他メタデータロックが必要となる。
オンラインDDLは、最初の一瞬に排他メタデータロックをとる。
その次に共有メタデータロックにフォールバックされる。
最後にもう一度排他メタデータロックをとる。

（1GBのALTER TABLEに1分かかると考えるといいっぽい。indexだと3倍速い。）
```
ALTER TABLE開始！
=> 排他メタデータロックをとる
=> 共有メタデータロックにフォールバック!
=> ALTER TABLEの実際の処理を行う。（indexの追加や、カラム追加によるテーブルのrebuild）
=> 排他メタデータロックをとる
=> 排他メタデータロックを解放する
=> ALTER TABLE終了！
```

### 共有メタデータロック
以下のSQLは、共有書き込みメタデータロックが必要。
クエリの実行中だけではなく、トランザクションの間中、共有メタデータロックを取る。

- SELECT
- INSERT
- UPDATE
- DELETE

### メタデータロックで刺された時のデモンストレーション
```sql
-- session1
mysql> BEGIN; SELECT * FROM memos LIMIT 1;

-- session2
MySQL [app_development]> ALTER TABLE memos DROP COLUMN poster;
Query OK, 0 rows affected (0.040 sec)

-- session3
mysql> BEGIN; SELECT * FROM memos LIMIT 1;

-- session1
mysql> COMMIT; BEGIN;  SELECT * FROM memos LIMIT 1;
```

---

```bash
$ mysql -u root -h 127.0.0.1 --port 3306 -proot app_development
```

### オンラインDDL
- `ALGORITHM = INSTANT`だと、最初の排他メタデータロックを取った後に即時反映されるので、処理がすぐ終わっちゃう。
  - 内部的にはメタデータしか変更しない。（テーブルのrebuildもなし。）
  - ADD COLUMNとDROP COLUMNで許可されている。（カラム追加や削除だけならメタデータ変えるだけでよさそうだよね。ただ、DEFUALT制約があるとそうはいかなさそう。）

### 疑問
- フォールバックするのはオンラインDDLの時だけ？それとも他のDDLの時も？

## innoDBロック
- Draft

## 参考資料
- https://speakerdeck.com/yoku0825/mysqlnorotukunozhong-lei-tosonojing-he
- https://dev.mysql.com/doc/refman/8.0/ja/innodb-locking.html
- https://dev.mysql.com/doc/refman/8.0/ja/innodb-locks-set.html
- https://dev.mysql.com/doc/refman/8.0/ja/metadata-locking.html
