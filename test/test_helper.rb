require 'rubygems'
require 'bundler/setup'
require 'sqlite3'
require 'active_record'
require 'minitest/unit'
require 'minitest/autorun'
require 'texticle'

class ActiveSupport::TestCase

  # Simple Search
  class Book < ActiveRecord::Base
    extend Texticle
    belongs_to :author
  end

  # Search with joined fields
  class Novel < ActiveRecord::Base
    extend Texticle
    self.table_name = :books

    searchable [:title, :subtitle]
  end

  # Search with integer field
  class Biography < ActiveRecord::Base
    extend Texticle
    self.table_name = :books

    searchable :id
  end

  # Search on relations
  class Cookbook < ActiveRecord::Base
    extend Texticle
    self.table_name = :books
    belongs_to :author

    searchable :title, {:author => :id}, {:author => :name}
  end

  # Search on relations
  class Author < ActiveRecord::Base
    extend Texticle
    has_many :books

    searchable :name, :books => :title
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
          t.string  :subtitle
          t.integer :author_id
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
