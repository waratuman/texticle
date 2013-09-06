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
    belongs_to :author
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

  class Cookbook < ActiveRecord::Base
    extend Texticle
    self.table_name = :books
    belongs_to :author

    def self.searchable_columns
      [:title, {:author => :id}]
    end
  end

  class Author < ActiveRecord::Base
    extend Texticle
    has_many :books

    def self.searchable_columns
      [:name, :books => :title]
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
        
        create_table :authors do |t|
          t.string :name
        end
      end

      def self.down
        drop_table :books
        drop_table :authors
      end

    end
  end

end

ActiveSupport::TestCase::Database.connect