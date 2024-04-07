require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'faker'
end

module SalesLogs
  class QueryBuilder
    attr_reader :query

    def self.build(batch_size) = new(batch_size).build
    def initialize(batch_size) = @batch_size = batch_size
    def build = build_bulk_insert_query

    def build_bulk_insert_query
      "INSERT INTO sales_logs (employee_roster_id, sales_quantity, sales_date) VALUES #{build_values.join(", ")};"
    end

    private

    attr_reader :batch_size

    def build_values
      (1..batch_size).map do
        "(#{AttributeBuilder.build_employee_roster_id}, #{AttributeBuilder.build_sales_quantity}, '#{AttributeBuilder.build_sales_date}')"
      end
    end

    module AttributeBuilder
      class << self
        def build_employee_roster_id = rand(1..100) # 例示のため、employee_roster_idは1から100の範囲でランダムに設定

        def build_sales_quantity = rand(1..100) # sales_quantityを1から100の範囲でランダムに設定

        def build_sales_date = Faker::Date.between(from: '2020-01-01', to: '2024-01-01').to_s # sales_dateを過去4年間でランダムに設定
      end
    end
  end

  module QueryPrinter
    DEFAULT_BATCH_SIZE = 1000

    def self.print_queries(total_count, batch_size = DEFAULT_BATCH_SIZE)
      (1..total_count).step(batch_size) do |offset|
        count = [batch_size, total_count - offset + 1].min
        $stdout.puts QueryBuilder.build(count)
      end
    end
  end
end

if __FILE__ == $0
  # ARGV[0]にはINSERTしたいレコード数が入る
  SalesLogs::QueryPrinter.print_queries(ARGV[0].to_i)
end
