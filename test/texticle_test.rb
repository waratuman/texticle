require 'test_helper'

class TexticleTest < ActiveSupport::TestCase

  test 'ts_columns' do
    assert_equal ['title', 'subtitle', 'slug'], Book.ts_columns
    assert_equal [[:title, :subtitle]], Novel.ts_columns
    assert_equal [:id], Biography.ts_columns
    assert_equal [:name, :books => :title], Author.ts_columns
    assert_equal [:title, {:author => :id}, {:author => :name}], Cookbook.ts_columns
  end

  test 'arel_columns' do
    assert_equal [Book.arel_table['title'], Book.arel_table['subtitle'], Book.arel_table['slug']], Texticle.arel_columns(Book, Book.ts_columns)
    assert_equal [[Novel.arel_table['title'], Novel.arel_table['subtitle']]], Texticle.arel_columns(Novel, Novel.ts_columns)
    assert_equal [Biography.arel_table['id']], Texticle.arel_columns(Biography, Biography.ts_columns)
    assert_equal [Author.arel_table['name'], Book.arel_table['title']], Texticle.arel_columns(Author, Author.ts_columns)
    assert_equal [Cookbook.arel_table['title'], Author.arel_table['id'], Author.arel_table['name']], Texticle.arel_columns(Cookbook, Cookbook.ts_columns)
  end

  test 'ts_langauge' do
    assert_equal 'english', Book.ts_language
  end

  test 'ts_vectors returns ts_vectors' do
    assert_equal ["to_tsvector('english', \"books\".\"title\" :: text)", "to_tsvector('english', \"books\".\"subtitle\" :: text)", "to_tsvector('english', \"books\".\"slug\" :: text)"], Book.ts_vectors.map(&:to_sql)
  end
  
  test 'ts_vectors with joining text fields' do
    assert_equal ["to_tsvector('english', \"books\".\"title\" :: text || \"books\".\"subtitle\" :: text)"], Novel.ts_vectors.map(&:to_sql)
  end

  test 'ts_relations' do
    assert_equal [:author], Cookbook.ts_relations.map(&:name)
  end

  test 'ts_query returns query' do
    assert_equal "to_tsquery('english', 'dorian:* & gray:*' :: text)", Book.ts_query('dorian gray').to_sql
  end
  
  test "ts_query escapes ():|!&*'" do
    assert_equal "to_tsquery('english', 'dorian:* & gray:*' :: text)", Book.ts_query('dorian & gray ():|!&*\'').to_sql
  end
  
  test 'ts_query with array returns query' do
    assert_equal "to_tsquery('english', 'dorian:* & gray:*' :: text)", Book.ts_query(['dorian', 'gray']).to_sql
  end
  
  test 'ts_query with integer returns query' do
    assert_equal "to_tsquery('english', '0:*' :: text)", Book.ts_query(0).to_sql
  end
  
  test 'ts_order returns ordering' do
    assert_equal "LEAST(\"books\".\"title\" :: text <-> 'dorian gray' :: text, \"books\".\"subtitle\" :: text <-> 'dorian gray' :: text, \"books\".\"slug\" :: text <-> 'dorian gray' :: text)", Book.ts_order('dorian gray').to_sql
  end
  
  test 'ts_order returns ordering with custom ts_columns' do
    assert_equal "\"books\".\"title\" :: text || \"books\".\"subtitle\" :: text <-> 'dorian gray' :: text", Novel.ts_order('dorian gray').to_sql
  end
  
  test 'search' do
    assert_equal (<<-SQL).strip.gsub(/\s+/, ' '), Book.search('dorian gray').to_sql.gsub(/\s+/, ' ')
      SELECT "books".*
      FROM "books"
      WHERE (to_tsvector('english', "books"."title" :: text) @@ to_tsquery('english', 'dorian:* & gray:*' :: text)
        OR to_tsvector('english', "books"."subtitle" :: text) @@ to_tsquery('english', 'dorian:* & gray:*' :: text)
        OR to_tsvector('english', "books"."slug" :: text) @@ to_tsquery('english', 'dorian:* & gray:*' :: text))
      ORDER BY LEAST("books"."title" :: text <-> 'dorian gray' :: text,
        "books"."subtitle" :: text <-> 'dorian gray' :: text,
        "books"."slug" :: text <-> 'dorian gray' :: text)
    SQL
  end
  
  test 'search with custom searhable_columns' do
    assert_equal (<<-SQL).strip.gsub(/\s+/, ' '), Novel.search('dorian gray').to_sql.gsub(/\s+/, ' ')
      SELECT "books".*
      FROM "books"
      WHERE (to_tsvector('english', "books"."title" :: text || "books"."subtitle" :: text) @@ to_tsquery('english', 'dorian:* & gray:*' :: text))
      ORDER BY "books"."title" :: text || "books"."subtitle" :: text <-> 'dorian gray' :: text
    SQL
  end
  
  test 'search with integer columns' do
    assert_equal (<<-SQL).strip.gsub(/\s+/, ' '), Biography.search(0).to_sql.gsub(/\s+/, ' ')
      SELECT "books".*
      FROM "books"
      WHERE (to_tsvector('english', "books"."id" :: text) @@ to_tsquery('english', '0:*' :: text))
      ORDER BY "books"."id" :: text <-> 0 :: text
    SQL
  end
  
  test 'search with array' do
    assert_equal (<<-SQL).strip.gsub(/\s+/, ' '), Book.search(['dorian', 'gray']).to_sql.gsub(/\s+/, ' ')
      SELECT "books".*
      FROM "books"
      WHERE (to_tsvector('english', "books"."title" :: text) @@ to_tsquery('english', 'dorian:* & gray:*' :: text)
        OR to_tsvector('english', "books"."subtitle" :: text) @@ to_tsquery('english', 'dorian:* & gray:*' :: text)
        OR to_tsvector('english', "books"."slug" :: text) @@ to_tsquery('english', 'dorian:* & gray:*' :: text))
      ORDER BY LEAST("books"."title" :: text <-> 'dorian gray' :: text,
        "books"."subtitle" :: text <-> 'dorian gray' :: text,
        "books"."slug" :: text <-> 'dorian gray' :: text)
    SQL
  end
  
  test 'search with join' do
    assert_equal (<<-SQL).strip.gsub(/\s+/, ' '), Author.search('dorian gray').to_sql.gsub(/\s+/, ' ')
      SELECT "authors".*
      FROM "authors"
      INNER JOIN "books" ON "books"."author_id" = "authors"."id"
      WHERE (to_tsvector('english', "authors"."name" :: text) @@ to_tsquery('english', 'dorian:* & gray:*' :: text)
        OR to_tsvector('english', "books"."title" :: text) @@ to_tsquery('english', 'dorian:* & gray:*' :: text))
      ORDER BY LEAST("authors"."name" :: text <-> 'dorian gray' :: text, "books"."title" :: text <-> 'dorian gray' :: text)
    SQL
    
    assert_equal (<<-SQL).strip.gsub(/\s+/, ' '), Cookbook.search('dorian gray').to_sql.gsub(/\s+/, ' ')
      SELECT "books".*
      FROM "books" INNER JOIN "authors" ON "authors"."id" = "books"."author_id"
      WHERE (to_tsvector('english', "books"."title" :: text) @@ to_tsquery('english', 'dorian:* & gray:*' :: text)
        OR to_tsvector('english', "authors"."id" :: text) @@ to_tsquery('english', 'dorian:* & gray:*' :: text)
        OR to_tsvector('english', "authors"."name" :: text) @@ to_tsquery('english', 'dorian:* & gray:*' :: text))
      ORDER BY LEAST("books"."title" :: text <-> 'dorian gray' :: text, "authors"."id" :: text <-> 'dorian gray' :: text, "authors"."name" :: text <-> 'dorian gray' :: text)
    SQL
  end
  
  test 'search with nil' do
    assert_equal 'SELECT "books".* FROM "books"', Book.search(nil).to_sql
  end
  
  test 'search with empty string' do
    assert_equal 'SELECT "books".* FROM "books"', Book.search('').to_sql
    assert_equal 'SELECT "books".* FROM "books"', Book.search(' ').to_sql
  end

end
