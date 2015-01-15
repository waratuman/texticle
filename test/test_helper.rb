require 'rubygems'
require 'bundler/setup'
require 'sqlite3'
require 'active_record'
require 'minitest/autorun'
require 'texticle'
require 'byebug'

class ActiveSupport::TestCase

  # Simple Search
  class Book < ActiveRecord::Base
    extend Texticle
    belongs_to :author

    after_save :update_fulltext_index

    self.fulltext_fields = %W[title subtitle]
  end

  # Search with joined fields
  class Novel < ActiveRecord::Base
    extend Texticle
    self.table_name = :books

    after_save :update_fulltext_index

    self.fulltext_fields = %W[title subtitle]
  end

  # Search with integer field
  class Biography < ActiveRecord::Base
    extend Texticle
    self.table_name = :books

    after_save :update_fulltext_index

    self.fulltext_fields = %W[id]
  end

  # Search on relations
  class Cookbook < ActiveRecord::Base
    extend Texticle
    self.table_name = :books
    belongs_to :author

    after_save :update_fulltext_index

    self.fulltext_fields = %W[title]

    def update_fulltext_index
      text = fulltext_fields.map { |x| read_attribute(x) } + [author.id, author.name]
      text = text.join("\n").gsub(/\s+/, ' ')
      update_column(:ts, text)
    end

  end

  # Search on relations
  class Author < ActiveRecord::Base
    extend Texticle
    has_many :books

    after_save :update_fulltext_index

    self.fulltext_fields = %W[name]

    def update_fulltext_index
      text = fulltext_fields.map { |x| read_attribute(x) } + books.map(&:ts)
      text = text.join("\n").gsub(/\s+/, ' ')
      update_column(:ts, text)
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
          t.string  :subtitle
          t.integer :author_id
          t.string  :slug, :unique => true
          t.text    :ts
        end

        create_table :authors do |t|
          t.string :name
          t.text    :ts
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
