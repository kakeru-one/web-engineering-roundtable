require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  git_source(:github) { |repo| "https://github.com/#{repo}.git" }

  gem "mysql2"
  gem 'pry-byebug'
end

module Mysql
  module ClientBuilder 
    def self.build
      # Ref: https://github.com/brianmario/mysql2#usage
      Mysql2::Client.new(
        # Docker Composeのコンテナ名をホストとして指定する（docker composeを用いると、コンテナ名がホスト名になる。）
        host: 'localhost',                  
        username: 'root',
        password: 'root',
        database: 'demo'
      )
    end
  end
end

# mysql2が正常にインストールできないのでコメントアウトしておく。
# client = Mysql::ClientBuilder.build
