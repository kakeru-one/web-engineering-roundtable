# IN句とEXISTS句の使い分け
## 前提条件
以下のテーブルがあるとする。
- songsテーブル(主表)
  - 曲名
  - 発表年
  - 販売数
  - id
- attrテーブル(従属表)
  - s_id
    - songsとの外部キー
  - 季節
  - テーマ

### 選択性についての前提条件

| 条件 | 主表/従属表 | 選択性 | 比率 |
| ---- | ---- | ---- | ---- |
| 発表年 > 1990 | 主表 | 低い | 50% |
| 販売数 > 300000 | 主表 | 高い | 1%以下 |
| テーマ <> 失恋 | 従属表 | 低い | 80% |

### EXISTS句を使用する場合
```sql
SELECT * FROM songs s
WHERE s.発表年 > 1990
  AND s.販売数 > 300000
  AND EXISTS (
    SELECT 1 FROM atrr a
    WHERE
      s.id = a.s_id
      AND テーマ <> "失恋"
  );
```
### IN句を使用する場合
```sql
SELECT * FROm songs s
WHERE id IN (
    SELECT s_id FROM attr
    WHERE テーマ <> "失恋"
  )
  AND s.発表年 > 1990
  AND s.販売数 > 300000;
```

- IN句とExists句は実行タイミングが違う。
  - 主表と従属表があるとして、従属表側のフィルタで、それぞれの句を実行するとする。
  - IN句は引数となるサブクエリ内の処理が先に実行されて、その結果に基づいて主表が絞り込まれた上で、主表にたいするWhereが実行される。
  - Exists句内のサブクエリは、主表のWhere句が実行されたあとに、実行される。
- したがって、主表と従属表の絞り込みの度合いによって、使い分ける必要がある。

### Tips
以下のように、JOINを使って書くこともできる。
（後で書きたいが、ON句にWHERE句に書いた条件を書いた方が良かったかも？）
今回は主表しか使わないので、サブクエリの方が可読性が高いと言える。
```sql
SELECT * FROM songs s
JOIN attr
ON s.id = attr.s_id
WHERE s.発表年 > 1990
AND s.販売数 > 300000;
```

## 前提知識
### 相関サブクエリ
非上場企業に所属する従業員数を取得する為のクエリを考えるとする。

まずは普通のサブクエリを使おうとした例。
以下のようなクエリだと、サブクエリで複数行返すので、エラーになる。
```sql
SELECT count(*)
FROM employees  
WHERE (
  SELECT is_listed
  FROM companies 
) IS FALSE;
```

次に、相関サブクエリを使おうとした例。
そこで、以下のようなWHERE句の条件をつけると、1行だけ帰るようになり、クエリが正しく動く。
```sql
SELECT count(*)
FROM employees  
WHERE (
  SELECT is_listed
  FROM companies 
  WHERE id = employees.company_id 
) IS FALSE;
```
