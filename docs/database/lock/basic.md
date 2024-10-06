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
- INDEXの追加だと、`ALGORITHM = INPLACE`を取らないといけないため、排他メタデータロックをはじめと終わりに取らないといけない。なので、indexを生やさずに`ALGORITHM = INSTANT`にできるADD COLUMNで対応しようとしたりすることもある。

### 疑問
- 排他MDLから共有MDLにフォールバックするのはオンラインDDLの時だけ？それとも他のDDLの時も？
  - 以下の記事に書いてあるけど、通常のDDLでも起きそう。
    - https://gihyo.jp/article/2022/09/mysql-rcn0180

## innoDBロック
- 行ロック。InnoDBの場合はクラスタインデックスで行データ本体もB+Treeインデックスの構造で保存されているので、インデックスロックと呼ばれたりする。

### ロックの強さ
排他（X）ロック・共有（S）ロックが存在する。
- UPDATE/INSERT/DELETEする行や、FOR UPDATEする行は排他ロックがかかる。
- 以下の条件下では共有ロックをとる。
  - `FOR SHARE`
  - `INSERT INTO .. SELECT ..`（のSELECT部分の行）
    ```sql
    INSERT INTO backup_employees (name, position)
    SELECT name, position FROM employees;
    ```
  - `CREATE TABLE .. AS SELECT ..`（のSELECT部分の行）
    ```sql
    CREATE TABLE employees (
      id INT AUTO_INCREMENT PRIMARY KEY,
      name VARCHAR(100),
      position VARCHAR(100)
    );

    INSERT INTO employees (name, position) VALUES
    ('Alice', 'Developer'),
    ('Bob', 'Designer'),
    ('Charlie', 'Manager');

    CREATE TABLE developer_employees AS
    SELECT name, position FROM employees
    WHERE position = 'Developer';
    ```
  - トランザクション分離レベルによる共有ロック
  - 子テーブルにINSERT/UPDATEする際には、親テーブルの関連を持っている行にも共有ロックがかかる。
- それ以外のSELECT文ではロックフリーとなる。

### ロックの範囲
ギャップなしロック・ギャップロック・レコードロックが存在する。
- ギャップなしロックは、インデックスレコードそのものだけをロックする。
  - `DELETE .. WHERE id = 1`と`UPDATE .. WHERE id = 1`は後に実行した方が待たされる。
    - この時、idがPRIMARY KEYとすると、ギャップなし排他ロックの競合が起こる。（ロックの期間はトランザクション終了まで）
- ギャップロックは、インデックスレコードの手前の隙間だけをロックする。
- レコードロックは、インデックスレコードとその手前のギャップを同時にロックする。
  - innoDBの文脈で「レコードロック」と言った場合、ギャップを含むロックということである。
- ネクストキーロックは「レコードロック」 + 「次のキーのギャップロック」
- インデックス上には常に2つの擬似レコードが存在する。（ちなみに、実レコードが一つでもあるとgapという領域ができる。）
  - infimum => 無限小
  - supremum => 無限大


では、**どのような時に、どのようなロックの範囲になる**のか？
- ほとんどはネクストキーロックまたはギャップなしロックになる。
- 同じクエリでもトランザクション分離レベルとそのインデックスがユニークかどうかによって、ロックの範囲が変わる。


| インデックスの種類          | ロックに使う演算子                              | READ-UNCOMMITTED / READ-COMMITTED   | REPEATABLE-READ / SERIALIZABLE      |
|-----------------------------|-----------------------------------------------|-------------------------------------|-------------------------------------|
| クラスタインデックス         | "=", IN                                      | ギャップなしロック                  | ギャップなしロック                  |
| クラスタインデックス         | ">", "<", "<=", ">=", BETWEEN                | ギャップなしロック                  | ネクストキーロック                  |
| ユニーク制約つきインデックス | "=", IN                                      | ギャップなしロックおよび※1          | ギャップなしロックおよび※1          |
| ユニーク制約つきインデックス | ">", "<", "<=", ">=", BETWEEN                | ギャップなしロックおよび※1          | ネクストキーロックおよび※1          |
| 非ユニークインデックス       | "=", IN                                      | ギャップなしロックおよび※1          | ネクストキーロックおよび※1          |
| 非ユニークインデックス       | ">", "<", "<=", ">=", BETWEEN                | ギャップなしロックおよび※1          | ネクストキーロックおよび※1          |

※1: セカンダリインデックスの他に、そのセカンダリインデックスに対応するクラスタインデックスのギャップなしロック

---

したがって、カーディナリティが低いカラムにインデックスを貼っちゃうと、 </br>
非ユニークインデックスになるため、ネクストキーロックができてしまい、  </br>
gapにハマってしまったレコードに関してはINSERT/UPDATEできなくなってしまう、というようなことが起きる。

#### トランザクション分離レベルで結構変わる
- `READ-COMMITED`の時にセカンダリインデックスのロックを取る範囲が変わる！
  - セカンダリインデックスのロックを取る時に、他のAND条件でFilter した上でロックを取ってくれる。
    - しかし、最初にだけセカンダリインデックスのロックをFilterしないでとる。

#### インデックスを貼っていないカラムでのinnoDBロックの範囲
- Draft


## 参考資料
- https://speakerdeck.com/yoku0825/mysqlnorotukunozhong-lei-tosonojing-he
- https://dev.mysql.com/doc/refman/8.0/ja/innodb-locking.html
- https://dev.mysql.com/doc/refman/8.0/ja/innodb-locks-set.html
- https://dev.mysql.com/doc/refman/8.0/ja/metadata-locking.html
