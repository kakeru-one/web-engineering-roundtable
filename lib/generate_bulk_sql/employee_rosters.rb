require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'faker'
end

# Bulk Insert用のSQLクエリを生成し出力する関数
def generate_and_print_bulk_insert_sql(count)
  batch_size = 1000 # 一度に挿入する最大のレコード数
  
  # 全データを生成
  all_data = (1..count).map do
    name = Faker::Name.name.gsub("'", "''") # シングルクォートのエスケープ
    prefecture_id = rand(1..47)
    age = rand(10..70)
    "('#{name}', #{prefecture_id}, #{age})"
  end

  # 1000件ごとにデータをスライスして、各スライスに対してSQLクエリを生成・出力
  all_data.each_slice(batch_size) do |data_slice|
    sql = "INSERT INTO employee_rosters (name, prefecture_id, age) VALUES #{data_slice.join(", ")};"
    puts sql
  end
end

generate_and_print_bulk_insert_sql(10000)
