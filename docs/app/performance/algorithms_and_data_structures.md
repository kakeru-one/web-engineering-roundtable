# アルゴリズムとデータ構造を理解しておくことの重要性
プログラムの実行時間・メモリ使用量が入力に応じてどのように変化するかを見積もったものを、それぞれ時間計算量・空間計算量という。
本勉強会では、時間計算量を扱う。

> 一般的な家庭用PCでは、1秒間で処理できる for 文ループの回数は、10^8 = 100,000,000 回程度

- [AtCoder Programming Guide for beginners (APG4b) 計算量](https://atcoder.jp/contests/apg4b/tasks/APG4b_w?lang=ja)
- [計算量オーダーの求め方](https://qiita.com/drken/items/872ebc3a2b5caaa4a0d0)
- [How to Write Fast Code in Ruby on Rails | shopify](https://shopify.engineering/write-fast-code-ruby-rails)

## オーダー記法を理解しておく

### O(N)
findメソッドを使っているため、`@tags`の各要素に対して、毎回`==`メソッドを実行してしまっている。
仮にfindの返り値として求める要素が最後の要素だったとすると、`@tags`の要素の数だけ計算回数が発生してしまう。
これを最悪計算量といい、要素の数をNとすると、**最悪計算量がO(N)である**という。
```ruby
class TagFinder
  def initialize(tags)
    @tags = tags
  end

  def find_tag_by_name(name)
    @tags.find { |tag| tag.name == name }
  end
end

tags = [Tag.new('Ruby'), Tag.new('Rails'), Tag.new('JavaScript')]
finder = TagFinder.new(tags)
finder.find_tag_by_name('Rails')  # O(N)
```

### O(1)
Hashのデータ構造だと、要素にダイレクトにアクセスできる。
（Hashは、一般的なデータ構造としてはハッシュテーブルと言われたりする。）
```ruby
class TagFinder
  def initialize(tags)
    @tags_hash = tags.index_by(&:name)
  end

  def find_tag_by_name(name)
    @tags_hash[name]
  end
end

tags = [Tag.new('Ruby'), Tag.new('Rails'), Tag.new('JavaScript')]
finder = TagFinder.new(tags)
finder.find_tag_by_name('Rails')  # O(1)
```

### O(N^2)
ネストされたループがある場合、例えばアプリケーションで「あるアイテムと他の全てのアイテムを比較する」ような処理を行うと、O(N^2) の計算量になる。
たとえば、重複チェックや同一性確認を行う場合にこのパターンが見られる。

コードの解説をすると、itemsの要素がN個あるとすると、
`@items.each_with_index`でN回、`(i+1...@items.size)`で最悪N回繰り返し処理が発生するので、合計O(N^2)になる。

（厳密にはNの2次式となるが、Nがとても大きい時、小さい次数は無視できる程度なので、計算量は`O(N^2)`としている。）

```ruby
class DuplicateChecker
  def initialize(items)
    @items = items
  end

  def find_duplicates
    duplicates = []
    @items.each_with_index do |item, i|
      (i+1...@items.size).each do |j|
        if item == @items[j]
          duplicates << item
        end
      end
    end
    duplicates
  end
end

items = ['apple', 'banana', 'orange', 'apple', 'banana']
checker = DuplicateChecker.new(items)
checker.find_duplicates  # O(N^2)
```

---

ここから先の計算量は応用例かつ、あまり実務で出てこないので、理解しなくとも良いです。


### O(log N)
ソートされたデータに対して、二分探索を行うケースである。たとえば、ユーザーが投稿した記事をIDで検索するとき、IDが昇順にソートされていれば、二分探索で効率的に検索できる。
```ruby
class ArticleFinder
  def initialize(articles)
    @articles = articles.sort_by(&:id)
  end

  def find_article_by_id(id)
    low = 0
    high = @articles.size - 1

    while low <= high
      mid = (low + high) / 2
      if @articles[mid].id == id
        return @articles[mid]
      elsif @articles[mid].id < id
        low = mid + 1
      else
        high = mid - 1
      end
    end
    nil
  end
end

articles = [Article.new(1), Article.new(3), Article.new(5), Article.new(7)]
finder = ArticleFinder.new(articles)
finder.find_article_by_id(5)  # O(log N)
```

## 計算量を減らす工夫
### index_byメソッドを使ってHashを構築する
```ruby
users = User.all.index_by(&:name)
users['occhi'] # O(1)になる
```

### メモ化
N回users_indexed_by_nameの処理が走っても、中の処理をキャッシュしておくことで処理を高速化する。

```ruby
def users_indexed_by_name
  @users_indexed_by_name ||= User.all.index_by(&:name)
end
```
