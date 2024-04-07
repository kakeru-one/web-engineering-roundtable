require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'faker'
  gem 'pry-byebug'
end

module EmployeeRosters
  class QueryBuilder
    attr_reader :query

    def self.build(batch_size) = new(batch_size).build
    def initialize(batch_size) = @batch_size = batch_size
    def build = build_bulk_insert_query

    def build_bulk_insert_query
      "INSERT INTO employee_rosters (name, prefecture_id, age) VALUES #{build_values.join(", ")};"
    end

    private

    attr_reader :batch_size

    def build_values
      (1..batch_size).map do
        "('#{AttributeBuilder.build_name}', #{AttributeBuilder.build_prefecture_id}, #{AttributeBuilder.build_age})"
      end
    end

    module AttributeBuilder
      class << self
        def build_name = Faker::Name.name.gsub("'", "''")

        def build_prefecture_id = rand(1..47)

        def build_age = rand(10..70)
      end
    end
  end

  module QueryPrinter
    DEFAULT_BATCH_SIZE = 1000

    def self.print_queries(total_count, batch_size = DEFAULT_BATCH_SIZE)
      (1..total_count).step(batch_size) do |offset|
        count = [batch_size, total_count - offset + 1].min
        $stdout.puts EmployeeRosterQueryBuilder.build(count)
      end
    end
  end
end

if __FILE__ == $0
  # ARGV[0]にはINSERTしたいレコード数が入る
  EmployeeRosters::QueryPrinter.print_queries(ARGV[0])
end
