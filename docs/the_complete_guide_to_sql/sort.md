# Sortが発生する場合とその対策
## 発生する演算
- [GROUP BY](#group-by)
- ORDER BY
- [集約関数(SUM, COUNT, AVG, MAX, MIN)](#集約関数)
- [DISTINCT](#distinctを回避する)
- [集合演算子(UNION, UBTERSECT, EXCEPT)](#集合演算子)
- ウィンドウ関数(RANK, ROW_NUMBER等)

## GROUP BY
- WHERE句でかける条件は、HAVING句に書かない方が効率がいい。
  - GROUP BY句は、WHERE句の後に実行される。よって、WHERE句で実行すると絞り込んだ状態でGROUP BYによるソートが行われ、ソートの負荷が軽減される。
  - WHERE句ではindexが利用できる。対して、HAVING句で絞り込むと、GROUP BY句によって生成されたビューに対して絞り込みを行うのでindexが引き継がれず、使われない。

参考: https://speakerdeck.com/soudai/pgcon21j-tutorial?slide=72

## 集約関数
- MAX, MINでテーブルを指定するのではなく、インデックスが貼られたユニークなカラムを指定するようにする。

## DISTINCTを回避する
DISTINCTを使用して重複を排除するためにソートが発生する。
これを回避するには、重複が発生しないようなSQLに書き換える必要がある。

---

以下は例である。
items has_many sales_historiesとする。
商品マスタ(items)から売上履歴(sales_histories)に存在する商品を選択し、リストとして取得したい。
### Before
```sql
SELECT DISTINCT i.item_no
  FROM items i INNER JOIN sales_histories sh
    ON i.item_no = sh.item_no;
```

### After
EXISTSを使用することで、重複がないitem_noを取り出すことができる。
```sql
SELECT i.item_no
  FROM items i
WHERE EXISTS (SELECT *
                FROM sales_histories sh
              WHERE i.item_no = sh.item_no);
```

## 集合演算子
これらは必ず重複解除のためのソートを行うようになっている。
ソートを回避するためには、UNION ALLなどのソートが発生しない演算子を使うようにする。


