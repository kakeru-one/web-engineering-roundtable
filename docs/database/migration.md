## これは何？

マイグレーションのうち、サービス影響に注意したい操作をまとめたものです。
出典: https://github.com/ankane/strong_migrations

Postgresの記述は省略、括弧でドキュメントの補足やコメントを追加しています。

## カラムの削除

ActiveRecordはランタイム中でデータベースのカラム情報をキャッシュしているので、（実行中のアプリケーションが存在するとき）カラムを削除するとアプリケーションプロセスが再起動するまで（実行中のアプリケーションで）例外が発生する可能性があります。

### Bad

```ruby
class RemoveSomeColumnFromUsers < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :some_column
  end
end
```

### Good

１. ActiveRecordに無視するカラムを指定します

```ruby
class User < ApplicationRecord
  self.ignored_columns = ["some_column"]
end
```

２. デプロイします
３. カラムを削除するマイグレーションを行います（カラムを削除）
４. １のステップで追加した `ignored_columns` の記述を削除します

## DEFAULT指定有りのカラムの追加

### Bad

古いバージョンのPostgres, MySQL, MariaDBでは既存のテーブルに対するデフォルト値指定ありのカラムの追加するとテーブル全体（全レコード）の上書きが発生します。
この間、PostgresではR/Wのロックがかかります。MySQLとMariaDBではWriteのロックがかかります。

```ruby
class AddSomeColumnToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :some_column, :text, default: "default_value"
  end
end
```

Postgre 11+, MySQL 8.0.12+, MariaDB 10.3.2+ では値が関数によって解決されない限りロックされません。

### Good

デフォルト値の指定なしでカラムを追加したのち、デフォルト指定する

```ruby
class AddSomeColumnToUsers < ActiveRecord::Migration[7.0]
  def up
    add_column :users, :some_column, :text
    change_column_default :users, :some_column, "default_value"
  end

  def down
    remove_column :users, :some_column
  end
end
```

データの埋め戻しは次の項目を参照してください。

## データの埋め戻し（Backfilling Data）

（整合性をとるための既存レコードのデータ更新）

### Bad

ActiveRecordはマイグレーションごとにトランザクションを張ります。
そしてデータの埋め戻しもまた同一のトランザクションで実行されるので、ALTER TABLE文はデータの埋め戻しが完了するまで対象テーブルがロックされます。（なので、多くのレコードがあるテーブルに対してテーブルの埋め戻しは長い時間、ロックがとられることが予測できます）

```ruby
class AddSomeColumnToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :some_column, :text
    User.update_all some_column: "default_value"
  end
end
```

### Good

データの埋め戻しを安全に行うために重要なことが三つあります。

- Batching
- Throttling
- Running it outside a transaction

Railsコンソールを使うか `disable_ddl_transaction!` を指定して（各ステップを）別々のマイグレーション（= トランザクション）として行うことです。

<details>
    <summary>disable_ddl_transaction!</summary>

> トランザクション内でスキーマを変更するステートメントがデータベースでサポートされていれば、マイグレーションはトランザクションでラップされます。この機能がデータベースでサポートされていない場合は、マイグレーションの一部が失敗した場合にロールバックされません。その場合は、変更の逆進を手動で記述する必要があります。

> ある種のクエリは、トランザクション内で実行できないことがあります。アダプタがDDLトランザクションをサポートしている場合は、disable_ddl_transaction!を使えば単一のマイグレーションでこれらを無効にできます。

https://railsguides.jp/active_record_migrations.htm

</details>

```ruby
class BackfillSomeColumn < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    User.unscoped.in_batches do |relation|
      relation.update_all some_column: "default_value"
      sleep(0.01) # throttle
    end
  end
end
```

## カラムのデータ型の変更

### Bad

カラムのデータ型の変更はテーブル全体（全レコード）の上書きを発生させます。この間、PostgresではR/Wのロックがかかります。MySQLとMariaDBではWriteのロックがかかります。（なので、レコード数が多いと、ロックを長時間とることになりサービス断が懸念されます）

```ruby
class ChangeSomeColumnType < ActiveRecord::Migration[7.0]
  def change
    change_column :users, :some_column, :new_type
  end
end
```

ただしいくつかの種類の操作はテーブルの上書きが発生しません。
MySQL/MariaDBでは下記の操作が該当します。

- `LIMIT`  指定が255以下に設定されている`String`型のカラムの `LIMIT` 指定を255まで増やすこと
- `LIMIT`  指定が255以上に設定されている`String`型のカラムの `LIMIT` 指定を増やすこと（上限なし）

### Good

安全に行うには以下の手順を検討する良いでしょう。（６ステップもあるのでコストが高いです。データ型の変更は設計段階でなるべく起きないようにすべきですね。）

1.  新しいカラムを追加する
2.  （アプリケーションは）両方（新旧）のカラムに対して値を書き込むようにする
3.  古いカラムから新しいカラムにデータの埋め戻しを行う
4.  （アプリケーションは）新しいカラムから値を読み出すようにする
5.  （アプリケーションは）古いカラムへのデータの書き込みをやめる
6.  古いカラムを削除する

## カラム名の変更

### Bad

カラム名の変更は（アプリケーションコードも合わせて変更されないと）アプリケーションのエラーにつながる可能性があります。（当たり前ですね）

```ruby
class RenameSomeColumn < ActiveRecord::Migration[7.0]
  def change
    rename_column :users, :some_column, :new_name
  end
end
```

### Good

安全に行うには以下の手順を検討する良いでしょう。（データ型の変更と同じです。）

1.  新しいカラムを追加する
2.  （アプリケーションは）両方（新旧）のカラムに対して値を書き込むようにする
3.  古いカラムから新しいカラムにデータの埋め戻しを行う
4.  （アプリケーションは）新しいカラムから値を読み出すようにする
5.  （アプリケーションは）古いカラムへのデータの書き込みをやめる
6.  古いカラムを削除する

（外部キーに使用ていない場合は `alias_attribute` を利用した方が手軽です）

## テーブル名の変更

### Bad

テーブル名の変更は（アプリケーションコードも合わせて変更されないと）アプリケーションのエラーにつながる可能性があります。（当たり前ですね）

```ruby
class RenameUsersToCustomers < ActiveRecord::Migration[7.0]
  def change
    rename_table :users, :customers
  end
end
```

### Good

安全に行うには以下の手順を検討する良いでしょう。

1.  新しいテーブルを追加する
2.  （アプリケーションは）両方（新旧）のテーブルに対して値を書き込むようにする
3.  古いテーブルから新しいテーブルにデータの埋め戻しを行う
4.  （アプリケーションは）新しいテーブルから値を読み出すようにする
5.  （アプリケーションは）古いテーブルへのデータの書き込みをやめる
6.  テーブルカラムを削除する

## チェック制約の追加

チェック制約の追加はPostgresではR/Wのロックがかかります。MySQLとMariaDBではWriteのロックがかかります。（なので、レコード数が多いと、ロックを長時間とることになりサービス断が懸念されます）

```ruby
class AddCheckConstraint < ActiveRecord::Migration[7.0]
  def change
    add_check_constraint :users, "price > 0", name: "price_check"
  end
end
```

MySQL/MariaDBでは2022-10-25段階でこの問題を避ける方法は紹介されていません。（なので、レコード数が多いテーブルに対してチェック制約を新たに追加するのは避けた方が良いのでしょう。）



