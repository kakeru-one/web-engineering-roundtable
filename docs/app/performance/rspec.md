# Rspecにおけるテスト高速化

## 各ブロック内で処理が繰り返されることを認識する
どの例においても、ブロックのスコープを考慮するべきである。
### letブロック
以下の例では、全てのitブロックで`let!(:tags)`が実行されてしまう。
使用するスコープでのみ記述するようにしよう。
```ruby
RSpec.describe 'Tags' do
  let!(:tags) do
    (1..3).map do |index|
      create(:tag, priority: index)
    end.index_by(&:priority)
  end

  describe 'GET /tags' do
    it '全てのメモが取得でき昇順で並び変えられている' do
      aggregate_failures do
        get '/tags'
        expect(response).to have_http_status(:ok)
        assert_response_schema_confirm(200)
        expect(response.parsed_body.length).to eq(3)

        tag_ids = tags.values.map(&:id)
        response.parsed_body.each do |tag|
          expect(tag_ids).to include(tag['id'])
        end

        tag_names = tags.values.map(&:name)
        response.parsed_body.each do |tag|
          expect(tag_names).to include(tag['name'])
        end

        tag_priorities = tags.values.map(&:priority)
        expect(response.parsed_body.pluck('priority')).to eq(tag_priorities.sort)
      end
    end
  end

  describe 'DELETE /tags/:id' do
    context '存在するタグを削除しようとした場合' do
      it 'タグが削除される' do
        aggregate_failures do
          expect { delete "/tags/#{tags[1].id}" }.to change(Tag, :count).by(-1)
          assert_request_schema_confirm
          expect(response).to have_http_status(:no_content)
          assert_response_schema_confirm(204)
        end
      end
    end
  end
end
```
### beforeブロック
以下のコードでは、各beforeブロックごとにSQLのUPDATE文が発行されてしまう。
ちなみに、今回の例だと、`let(:user)`する時に`can_send_email: false`すればbeforeブロックは必要ない。
```ruby
RSpec.describe User, type: :model do
  describe "#test_method" do
    let(:user){ create(:user) }

    before do
      user.update!(can_send_email: false)
    end

    it 'メールが送信されないこと' do
    end

    it 'ログが生成されないこと' do
    end
  end
end
```

## e.g. expectを一個にまとめる
### Bad
毎回のitブロックごとにgetリクエストが走るので、NetWork I/OとDB I/Oが発生してしまう。
これによって、かなりテスト実行速度が遅くなる。
```ruby
RSpec.describe 'Tags', type: :request do
  describe 'GET /tags' do
    subject(:request) { get tags_path }

    context '正常な時' do
      it 'タグ一覧でタグIDを返す' do
        request
        tag_ids = tags.map(&:id)
        json.each do |tag|
          expect(tag_ids).to include(tag['id'])
        end
      end

      it 'タグ一覧でタグ名を返す' do
        request
        tag_names = tags.map(&:name)
        json.each do |tag|
          expect(tag_names).to include(tag['name'])
        end
      end

      it 'タグ一覧でタグを昇順で返す' do
        request
        tag_priorities = tags.map(&:priority)
        expect(json.pluck('priority')).to eq(tag_priorities.sort)
      end

      it 'タグ数が正しい' do
        request
        expect(json.size).to eq(3)
      end

      it 'ステータスコード200を返す' do
        request
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
```

### Good
一つのitブロックで検証しているので、一回しかgetリクエストが走らない。
また、aggregate_failuresメソッドを使うことで、各expectがfailした時の詳細も標準出力することができる。
```ruby
  describe 'GET /tags' do   #テストの対象
    context 'タグが存在する場合' do　#前提条件
      let!(:tags) { create_list(:tag, 3) }　#テストに使用するデータ

      it '全てのタグが取得でき、priorityの昇順で並び変えられている' do
        aggregate_failures do
          get '/tags'
          expect(response).to have_http_status(:ok)
          expect(response.parsed_body['tags'].length).to eq(3)

          result_tags = response.parsed_body['tags'].map { _1['priority'] }
          expected_tags = tags.map(&:priority).sort

          expect(result_tags).to eq(expected_tags)
        end
      end
    end
  end
```

## [補足] gemのコードを読む
基本的にはgemを使っていると、gemで定義されたクラス・モジュール・メソッドが使えるようになるので、これらを読みに行きます。
以下の方法で読むといいです。

- [EASY] リポジトリに読みにいく。
- [NORMAL] リポジトリをcloneしてきてテストを実行する。
- [NORMAL] step/next 等のコマンドを駆使して、gem内部のコードの実行場所まで辿り着く。
  - https://github.com/deivid-rodriguez/pry-byebug
  - https://qiita.com/AknYk416/items/6f0bec58712edaf4940e
  - https://tech.smarthr.jp/entry/2021/11/08/143649
- [HARD] /bundle/gems 以下のgemのコードにbinding.pry等のデバッガを仕込む。

### pry-byebugで使えるコマンド
| コマンド  | 説明                                   |
|-----------|----------------------------------------|
| `next`    | 次の行を実行                           |
| `step`    | 次の行かメソッド内に入る               |
| `continue`| プログラムの実行を続けてpryを終了      |
| `finish`  | 現在のフレームが終わるまで実行         |
| `@`       | 現在のbreakpointを表示する             |

## 遅いテストを可視化する
`–profile`オプションをつけてrspecコマンドを実行する。

また、`test-prof`というツールもある。これを使うとより詳細な情報が得られるそう。
- https://github.com/test-prof/test-prof


## テストを並列化する
CIを高速化したい場合は、テストを並列化することも有効です。
ただ、MiniOなどのミドルウェアを使用している場合は、その分バケットを作成しないといけなかったりするので注意が必要です。
（バケット間での競合が起こる。）
- https://github.com/grosser/parallel_tests
- https://zenn.dev/m_yamashii/articles/parallel-tests

## 余分なwarningの標準出力が出ないようにする
標準出力する際にも、出力するためのrubyのコードが実行されるので、遅くする原因になってしまう。

## ファイルに大きなサイズの書き込みをするのを防ぐ
31MB分のディスク I/Oを発生させた上で、ストレージのミドルウェア（MiniOとか）にuploadしているので、数十秒かかってしまう。
### Bad
```ruby
context 'ファイルサイズが30MB以上の時' do
  let(:memo_file) do
    file_path = Rails.root.join('tmp/mocked_test_file.pdf')
    # サイズを拡張する
    File.open(file_path, 'a') do |f|
      file_content = ' ' * 31.megabytes
      f.write(file_content)
    end
    build(:memo_file, file: Rack::Test::UploadedFile.new(file_path, 'application/pdf'))
  end

  it 'バリデーションエラーになる' do
    aggregate_failures do
      expect(memo_file.valid?).to be false
      expect(memo_file.errors.full_messages).to eq ['ファイル ファイルのサイズを30 MB以内にしてください']
    end
  end
end
```

### Good
```ruby
context 'ファイルサイズが30MB以上の時' do
  let(:memo_file) do
    build(:memo_file, file: Rack::Test::UploadedFile.new('/public/test.pdf'))
  end

  before do
    # 31 MB分の書き込み処理を行ってしまうとテスト実行時間が長くなってしまうので、以下のソースコードのnew_file.sizeをmockする。
    # Ref: https://github.com/carrierwaveuploader/carrierwave/blob/master/lib/carrierwave/uploader/file_size.rb#L30
    allow_any_instance_of(CarrierWave::SanitizedFile).to receive(:size).and_return(3_100_000_000)
  end

  it 'バリデーションエラーになる' do
    aggregate_failures do
      expect(memo_file.valid?).to be false
      expect(memo_file.errors.full_messages).to eq ['ファイル ファイルのサイズを30 MB以内にしてください']
    end
  end
end
```
