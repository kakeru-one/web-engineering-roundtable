# メモリ効率の話
アプリケーションのメモリ効率に限って話す。
ちなみに、DBサーバーのメモリのことを考慮するのもかなり重要である。
（ビューの生成でメモリを使ったり、バッファプールにページを載せたり。）
- https://dev.mysql.com/doc/refman/8.0/ja/memory-use.html

全ての基礎として、以下の記事を読んでおくことをお勧めする。
OS上でどのようにメモリが使われるかを知っておくことはかなり重要なので。
- https://qiita.com/kunihirotanaka/items/70d43d48757aea79de2d

## ActiveRecordのオブジェクトはメモリをかなり消費する

以下の記事でも説明されていますが、Active Recordのオブジェクトはメモリをかなり消費する。

> 10万のかんたんなARオブジェクトを作ると140MBほど消費するようです。
> https://tech.smarthr.jp/entry/2021/11/11/151444#:~:text=10%E4%B8%87%E3%81%AE%E3%81%8B%E3%82%93%E3%81%9F%E3%82%93%E3%81%AAAR%E3%82%AA%E3%83%96%E3%82%B8%E3%82%A7%E3%82%AF%E3%83%88%E3%82%92%E4%BD%9C%E3%82%8B%E3%81%A8140MB%E3%81%BB%E3%81%A9%E6%B6%88%E8%B2%BB%E3%81%99%E3%82%8B%E3%82%88%E3%81%86%E3%81%A7%E3%81%99%E3%80%82

仮にレコードの件数が100万件程度になると、1.5GB程度のメモリを使用することが予想される。

サーバーのスペックによっては、このメモリ使用量は無視できない問題になってくる可能性が高い。

### 参考
- https://tech.smarthr.jp/entry/2021/11/11/151444
- https://qiita.com/rh_taro/items/eaec3e16248d88e2ccf9
- https://nishinatoshiharu.com/rails-roop-methods-difference/

