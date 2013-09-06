require 'rubygems'
require 'bundler/setup'
require 'sqlite3'
require 'active_record'
require 'minitest/unit'
require 'turn/autorun'
require 'texticle'

puts ActiveRecord::Base

class ActiveSupport::TestCase

  class Book < ActiveRecord::Base
    extend Texticle
  end

  class Novel < ActiveRecord::Base
    extend Texticle
    self.table_name = :books

    def self.searchable_columns
      [[:title, :author]]
    end
  end

  class Biography < ActiveRecord::Base
    extend Texticle
    self.table_name = :books

    def self.searchable_columns
      [:id]
    end
  end

  module Database
    extend self

    def connect
      ActiveRecord::Base.establish_connection(YAML::load(<<-CONFIG))
        adapter: sqlite3
        database: ":memory:"
        encoding: utf8
      CONFIG

      ActiveRecord::Migration.verbose = false
      Schema.migrate :up
    end

    class Schema < ActiveRecord::Migration

      def self.up
        create_table :books do |t|
          t.string  :title
          t.string  :author
          t.string  :slug, :unique => true
        end
      end

      def self.down
        drop_table :books
      end

    end
  end

end

ActiveSupport::TestCase::Database.connect