require 'test_helper'
require 'texticle/indexer'

class TexticleTest < ActiveSupport::TestCase

  test 'up_migration' do
    assert_equal <<-SQL.strip.gsub(/\s+/, ' '), Texticle::Indexer.new.up_migration('ActiveSupport::TestCase::Book').strip.gsub(/\s+/, ' ')
      CREATE index books_fulltext_idx ON books
      USING GIN(to_tsvector('english', ("books"."title" :: text)), to_tsvector('english', ("books"."subtitle" :: text)), to_tsvector('english', ("books"."slug" :: text)));
    SQL
  end

end