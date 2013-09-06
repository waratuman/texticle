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
    assert_equal ["to_tsvector('english', COALESCE(\"books\".\"title\", ''))", "to_tsvector('english', COALESCE(\"books\".\"author\", ''))", "to_tsvector('english', COALESCE(\"books\".\"slug\", ''))"], Book.ts_vectors.map(&:to_sql)
  end

  test 'Texicle::ts_vectors with joining text fields' do
    assert_equal ["to_tsvector('english', COALESCE(\"books\".\"title\" || \"books\".\"author\", ''))"], Novel.ts_vectors.map(&:to_sql)
  end

  test 'Texicle::ts_query returns query' do
    assert_equal "to_tsquery('english', 'dorian & gray:*')", Book.ts_query('dorian gray').to_sql
  end

  test 'Texicle::ts_query with array returns query' do
    assert_equal "to_tsquery('english', 'dorian & gray:*')", Book.ts_query(['dorian', 'gray']).to_sql
  end

  test 'Texicle::ts_order returns ordering' do
    assert_equal "LEAST(COALESCE(\"books\".\"title\", '') <-> 'dorian gray', COALESCE(\"books\".\"author\", '') <-> 'dorian gray', COALESCE(\"books\".\"slug\", '') <-> 'dorian gray')", Book.ts_order('dorian gray').to_sql
  end

  test 'Texicle::ts_order returns ordering with custom searchable_columns' do
    assert_equal "COALESCE(\"books\".\"title\" || \"books\".\"author\", '') <-> 'dorian gray'", Novel.ts_order('dorian gray').to_sql
  end

  test 'Texicle::search' do
    assert_equal (<<-SQL).strip.gsub(/\s+/, ' '), Book.search('dorian gray').to_sql.gsub(/\s+/, ' ')
      SELECT "books".*
      FROM "books"
      WHERE (to_tsvector('english', COALESCE("books"."title", '')) @@ to_tsquery('english', 'dorian & gray:*')
        OR to_tsvector('english', COALESCE("books"."author", '')) @@ to_tsquery('english', 'dorian & gray:*')
        OR to_tsvector('english', COALESCE("books"."slug", '')) @@ to_tsquery('english', 'dorian & gray:*'))
      ORDER BY LEAST(COALESCE("books"."title", '') <-> 'dorian gray',
        COALESCE("books"."author", '') <-> 'dorian gray',
        COALESCE("books"."slug", '') <-> 'dorian gray')
    SQL
  end

  test 'Texicle::search with custom searhable_columns' do
    assert_equal (<<-SQL).strip.gsub(/\s+/, ' '), Novel.search('dorian gray').to_sql.gsub(/\s+/, ' ')
      SELECT "books".*
      FROM "books"
      WHERE (to_tsvector('english', COALESCE("books"."title" || "books"."author", '')) @@ to_tsquery('english', 'dorian & gray:*'))
      ORDER BY COALESCE("books"."title" || "books"."author", '') <-> 'dorian gray'
    SQL
  end

end