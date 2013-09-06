require 'test_helper'

class TexticleTest < ActiveSupport::TestCase

  test 'Texicle::searchable_columns returns string and text columns' do
    assert_equal ['title', 'author', 'slug'], Book.searchable_columns
  end

  test 'Texicle::searchable_columns returns overridden columns' do
    assert_equal [[:title, :author]], Novel.searchable_columns
  end

  test 'Texicle::ts_language returns english by default' do
    assert_equal 'english', Book.ts_language
  end

  test 'Texicle::ts_column_sets returns string and text columns' do
    assert_equal [[Book.arel_table['title']], [Book.arel_table['author']], [Book.arel_table['slug']]], Book.ts_column_sets
  end

  test 'Texicle::ts_vectors returns ts_vectors' do
    assert_equal ["to_tsvector('english', COALESCE(\"books\".\"title\", '') :: text)", "to_tsvector('english', COALESCE(\"books\".\"author\", '') :: text)", "to_tsvector('english', COALESCE(\"books\".\"slug\", '') :: text)"], Book.ts_vectors.map(&:to_sql)
  end

  test 'Texicle::ts_vectors with joining text fields' do
    assert_equal ["to_tsvector('english', COALESCE(\"books\".\"title\" || \"books\".\"author\", '') :: text)"], Novel.ts_vectors.map(&:to_sql)
  end

  test 'Texicle::ts_query returns query' do
    assert_equal "to_tsquery('english', 'dorian & gray:*' :: text)", Book.ts_query('dorian gray').to_sql
  end

  test 'Texicle::ts_query with array returns query' do
    assert_equal "to_tsquery('english', 'dorian & gray:*' :: text)", Book.ts_query(['dorian', 'gray']).to_sql
  end

  test 'Texicle::ts_order returns ordering' do
    assert_equal "LEAST(COALESCE(\"books\".\"title\", '') :: text <-> 'dorian gray', COALESCE(\"books\".\"author\", '') :: text <-> 'dorian gray', COALESCE(\"books\".\"slug\", '') :: text <-> 'dorian gray')", Book.ts_order('dorian gray').to_sql
  end

  test 'Texicle::ts_order returns ordering with custom searchable_columns' do
    assert_equal "COALESCE(\"books\".\"title\" || \"books\".\"author\", '') :: text <-> 'dorian gray'", Novel.ts_order('dorian gray').to_sql
  end

  test 'Texicle::search' do
    assert_equal (<<-SQL).strip.gsub(/\s+/, ' '), Book.search('dorian gray').to_sql.gsub(/\s+/, ' ')
      SELECT "books".*
      FROM "books"
      WHERE (to_tsvector('english', COALESCE("books"."title", '') :: text) @@ to_tsquery('english', 'dorian & gray:*' :: text)
        OR to_tsvector('english', COALESCE("books"."author", '') :: text) @@ to_tsquery('english', 'dorian & gray:*' :: text)
        OR to_tsvector('english', COALESCE("books"."slug", '') :: text) @@ to_tsquery('english', 'dorian & gray:*' :: text))
      ORDER BY LEAST(COALESCE("books"."title", '') :: text <-> 'dorian gray',
        COALESCE("books"."author", '') :: text <-> 'dorian gray',
        COALESCE("books"."slug", '') :: text <-> 'dorian gray')
    SQL
  end

  test 'Texicle::search with custom searhable_columns' do
    assert_equal (<<-SQL).strip.gsub(/\s+/, ' '), Novel.search('dorian gray').to_sql.gsub(/\s+/, ' ')
      SELECT "books".*
      FROM "books"
      WHERE (to_tsvector('english', COALESCE("books"."title" || "books"."author", '') :: text) @@ to_tsquery('english', 'dorian & gray:*' :: text))
      ORDER BY COALESCE("books"."title" || "books"."author", '') :: text <-> 'dorian gray'
    SQL
  end

end