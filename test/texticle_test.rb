require 'test_helper'

class TexticleTest < ActiveSupport::TestCase

  test 'Texticle::arel_columns returns arel columns when given symbol' do
    assert_equal Book.arel_table['id'], Texticle.arel_columns(Book, :id)
  end
  
  test 'Texticle::arel_columns returns arel columns when given array' do
    assert_equal [Book.arel_table['id'], Book.arel_table['title']], Texticle.arel_columns(Book, [:id, :title])
  end
  
  test 'Texticle::arel_columns returns arel columns when given hash' do
    assert_equal [Book.arel_table['title']], Texticle.arel_columns(Author, {:books => :title})
    assert_equal [Book.arel_table['title'], Book.arel_table['id']], Texticle.arel_columns(Author, {:books => [:title, :id]})
  end
  
  test 'Texticle::arel_columns returns arel columns when given array with symbols and hash' do
    assert_equal [Author.arel_table['id'], [Book.arel_table['title']]], Texticle.arel_columns(Author, [:id, {:books => :title}])
    assert_equal [Author.arel_table['id'], [Book.arel_table['id']], [Book.arel_table['title']]], Texticle.arel_columns(Author, [:id, {:books => :id}, {:books => :title}])
    assert_equal [Author.arel_table['id'], [Book.arel_table['id'], Book.arel_table['title']]], Texticle.arel_columns(Author, [:id, {:books => [:id, :title]}])
  end
  
  test 'Texticle::searchable_columns returns string and text columns' do
    assert_equal ['title', 'author', 'slug'], Book.searchable_columns
  end
  
  test 'Texticle::searchable_columns returns overridden columns' do
    assert_equal [[:title, :author]], Novel.searchable_columns
  end
  
  test 'Texticle::ts_columns returns string and text columns' do
    assert_equal [[Book.arel_table['title']], [Book.arel_table['author']], [Book.arel_table['slug']]], Book.ts_columns
  end
  
  test 'Texticle::ts_columns returns overridden columns' do
    assert_equal [[Novel.arel_table['title'], Novel.arel_table['author']]], Novel.ts_columns
  end
  
  test 'Texticle::ts_language returns english by default' do
    assert_equal 'english', Book.ts_language
  end
  
  test 'Texticle::ts_vectors returns ts_vectors' do
    assert_equal ["to_tsvector('english', \"books\".\"title\" :: text)", "to_tsvector('english', \"books\".\"author\" :: text)", "to_tsvector('english', \"books\".\"slug\" :: text)"], Book.ts_vectors.map(&:to_sql)
  end

  test 'Texticle::ts_vectors with joining text fields' do
    assert_equal ["to_tsvector('english', \"books\".\"title\" :: text || \"books\".\"author\" :: text)"], Novel.ts_vectors.map(&:to_sql)
  end
  
  test 'Texticle::ts_query returns query' do
    assert_equal "to_tsquery('english', 'dorian & gray:*' :: text)", Book.ts_query('dorian gray').to_sql
  end
  
  test 'Texticle::ts_query returns query with special chars' do
    assert_equal "to_tsquery('english', 'dorian & gray:*' :: text)", Book.ts_query('dorian gray').to_sql
  end
  
  test 'Texticle::ts_query with array returns query' do
    assert_equal "to_tsquery('english', 'dorian & gray:*' :: text)", Book.ts_query(['dorian', 'gray']).to_sql
  end
  
  test 'Texticle::ts_query with integer returns query' do
    assert_equal "to_tsquery('english', '0:*' :: text)", Book.ts_query(0).to_sql
  end
  
  test 'Texticle::ts_order returns ordering' do
    assert_equal "LEAST(\"books\".\"title\" :: text <-> 'dorian gray' :: text, \"books\".\"author\" :: text <-> 'dorian gray' :: text, \"books\".\"slug\" :: text <-> 'dorian gray' :: text)", Book.ts_order('dorian gray').to_sql
  end
  
  test 'Texticle::ts_order returns ordering with custom searchable_columns' do
    assert_equal "\"books\".\"title\" :: text || \"books\".\"author\" :: text <-> 'dorian gray' :: text", Novel.ts_order('dorian gray').to_sql
  end
  
  test 'Texticle::search' do
    assert_equal (<<-SQL).strip.gsub(/\s+/, ' '), Book.search('dorian gray').to_sql.gsub(/\s+/, ' ')
      SELECT "books".*
      FROM "books"
      WHERE (to_tsvector('english', "books"."title" :: text) @@ to_tsquery('english', 'dorian & gray:*' :: text)
        OR to_tsvector('english', "books"."author" :: text) @@ to_tsquery('english', 'dorian & gray:*' :: text)
        OR to_tsvector('english', "books"."slug" :: text) @@ to_tsquery('english', 'dorian & gray:*' :: text))
      ORDER BY LEAST("books"."title" :: text <-> 'dorian gray' :: text,
        "books"."author" :: text <-> 'dorian gray' :: text,
        "books"."slug" :: text <-> 'dorian gray' :: text)
    SQL
  end
  
  test 'Texticle::search with custom searhable_columns' do
    assert_equal (<<-SQL).strip.gsub(/\s+/, ' '), Novel.search('dorian gray').to_sql.gsub(/\s+/, ' ')
      SELECT "books".*
      FROM "books"
      WHERE (to_tsvector('english', "books"."title" :: text || "books"."author" :: text) @@ to_tsquery('english', 'dorian & gray:*' :: text))
      ORDER BY "books"."title" :: text || "books"."author" :: text <-> 'dorian gray' :: text
    SQL
  end
  
  test 'Texticle::search with integer columns' do
    assert_equal (<<-SQL).strip.gsub(/\s+/, ' '), Biography.search(0).to_sql.gsub(/\s+/, ' ')
      SELECT "books".*
      FROM "books"
      WHERE (to_tsvector('english', "books"."id" :: text) @@ to_tsquery('english', '0:*' :: text))
      ORDER BY "books"."id" :: text <-> 0 :: text
    SQL
  end
  
  test 'Texticle::search with array' do
    assert_equal (<<-SQL).strip.gsub(/\s+/, ' '), Book.search(['dorian', 'gray']).to_sql.gsub(/\s+/, ' ')
      SELECT "books".*
      FROM "books"
      WHERE (to_tsvector('english', "books"."title" :: text) @@ to_tsquery('english', 'dorian & gray:*' :: text)
        OR to_tsvector('english', "books"."author" :: text) @@ to_tsquery('english', 'dorian & gray:*' :: text)
        OR to_tsvector('english', "books"."slug" :: text) @@ to_tsquery('english', 'dorian & gray:*' :: text))
      ORDER BY LEAST("books"."title" :: text <-> 'dorian gray' :: text,
        "books"."author" :: text <-> 'dorian gray' :: text,
        "books"."slug" :: text <-> 'dorian gray' :: text)
    SQL
  end
  
  test 'Texticle::search with join' do
    assert_equal (<<-SQL).strip.gsub(/\s+/, ' '), Author.search('dorian gray').to_sql.gsub(/\s+/, ' ')
      SELECT "authors".*
      FROM "authors"
      INNER JOIN "books" ON "books"."author_id" = "authors"."id"
      WHERE (to_tsvector('english', "authors"."name" :: text) @@ to_tsquery('english', 'dorian & gray:*' :: text)
        OR to_tsvector('english', "books"."title" :: text) @@ to_tsquery('english', 'dorian & gray:*' :: text))
      ORDER BY LEAST("authors"."name" :: text <-> 'dorian gray' :: text, "books"."title" :: text <-> 'dorian gray' :: text)
    SQL
    
    assert_equal (<<-SQL).strip.gsub(/\s+/, ' '), Cookbook.search('dorian gray').to_sql.gsub(/\s+/, ' ')
      SELECT "books".*
      FROM "books" INNER JOIN "authors" ON "authors"."id" = "books"."author_id"
      WHERE (to_tsvector('english', "books"."title" :: text) @@ to_tsquery('english', 'dorian & gray:*' :: text)
        OR to_tsvector('english', "authors"."id" :: text || "authors"."name" :: text) @@ to_tsquery('english', 'dorian & gray:*' :: text))
      ORDER BY LEAST("books"."title" :: text <-> 'dorian gray' :: text, "authors"."id" :: text || "authors"."name" :: text <-> 'dorian gray' :: text)
    SQL
  end
  
  test 'Texticle::ts_arel_columns returns arel columns when given symbol' do
    assert_equal Book.arel_table['id'], Texticle.arel_columns(Book, 'id')
  end
  
  test 'Texticle::ts_arel_columns returns arel columns when given array' do
    assert_equal [Book.arel_table['id'], Book.arel_table['title']], Texticle.arel_columns(Book, ['id', 'title'])
  end
  
  test 'Texticle::ts_arel_columns returns arel columns when given hash' do
    assert_equal [Book.arel_table['title']], Texticle.arel_columns(Author, {'books' => 'title'})
    assert_equal [Book.arel_table['title'], Book.arel_table['id']], Texticle.arel_columns(Author, {'books' => ['title', 'id']})
  end
  
  test 'Texticle::ts_arel_columns returns arel columns when given array with symbols and hash' do
    assert_equal [Author.arel_table['id'], [Book.arel_table['title']]], Texticle.arel_columns(Author, ['id', {'books' => 'title'}])
    assert_equal [Author.arel_table['id'], [Book.arel_table['id']], [Book.arel_table['title']]], Texticle.arel_columns(Author, ['id', {'books' => 'id'}, {'books' => 'title'}])
    assert_equal [Author.arel_table['id'], [Book.arel_table['id'], Book.arel_table['title']]], Texticle.arel_columns(Author, ['id', {'books' => ['id', 'title']}])
  end

end