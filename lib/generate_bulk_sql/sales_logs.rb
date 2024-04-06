require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'faker'
end

# sales_logs テーブル用の Bulk Insert SQLクエリを生成し出力する関数
def generate_and_print_sales_logs_sql(count)
  batch_size = 1000 # 一度に挿入する最大のレコード数

  (1..count).each_slice(batch_size) do |slice|
    values = slice.map do
      employee_roster_id = rand(1..100) # 例示のため、employee_roster_idは1から100の範囲でランダムに設定
      sales_quantity = rand(1..100) # sales_quantityを1から100の範囲でランダムに設定
      sales_date = Faker::Date.between(from: '2020-01-01', to: '2024-01-01').to_s # sales_dateを過去4年間でランダムに設定
      "(#{employee_roster_id}, #{sales_quantity}, '#{sales_date}')"
    end.join(", ")

    sql = "INSERT INTO sales_logs (employee_roster_id, sales_quantity, sales_date) VALUES #{values};"
    puts sql
  end
end

generate_and_print_sales_logs_sql(1000000)
