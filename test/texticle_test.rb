require 'test_helper'

class TexticleTest < ActiveSupport::TestCase

  test 'extract_text' do
    author = Author.create(:name => 'Oscar Wild')
    book = Book.create(title: 'The Picture of Dorian Gray', subtitle: 'A classic work of gothic fiction', author: author)
    assert_equal [book.title, book.subtitle].join(' '), book.ts
    author.reload
    author.update_fulltext_index
    assert_equal [book.author.name, book.title, book.subtitle].join(' '), author.ts
  end

  test 'custom update_fulltext_index' do
    author = Author.create(name: 'Julia Child')
    book = Cookbook.create(title: 'Mastering the Art of French Cooking', author: author)
    assert_equal 'Mastering the Art of French Cooking 1 Julia Child', book.ts
  end

  test 'fulltext_fields' do
    assert_equal ['title', 'subtitle'], Book.fulltext_fields
    assert_equal ['title', 'subtitle'], Novel.fulltext_fields
    assert_equal ['id'], Biography.fulltext_fields
    assert_equal ['name'], Author.fulltext_fields
    assert_equal ['title'], Cookbook.fulltext_fields
  end
  
  test 'ts_langauge' do
    assert_equal 'english', Book.ts_language
  end
  
  test 'ts_vectors returns ts_vectors' do
    assert_equal "to_tsvector('english', \"books\".\"ts\")", Book.ts_vector.to_sql
  end
  
  test 'ts_vectors with joining text fields' do
    assert_equal "to_tsvector('english', \"books\".\"ts\")", Novel.ts_vector.to_sql
  end
  
  test 'ts_query returns query' do
    assert_equal "to_tsquery('english', 'dorian:* & gray:*' :: text)", Book.ts_query('dorian gray').to_sql
  end
  
  test 'ts_query escapes invalide byte sequences' do
    assert_equal "to_tsquery('english', 'dorian:* & gray:*' :: text)", Book.ts_query(URI.decode('dorian%A0%A0gray')).to_sql
  end
  
  test "ts_query escapes ():|!&*'" do
    assert_equal "to_tsquery('english', 'dorian:* & gray:* & \'\':*' :: text)", Book.ts_query('dorian & gray ():|!&*\'').to_sql
  end

  test "ts_query escapes ():|!&*' with space" do
    assert_equal "to_tsquery('english', 'a:* & b:* & c:* & d:* & e:* & f:* & g:* & h\\i\'\'j:*' :: text)", Book.ts_query('a(b)c:d|e!f&g*h\i\'j').to_sql
  end

  test 'ts_query with array returns query' do
    assert_equal "to_tsquery('english', 'dorian:* & gray:*' :: text)", Book.ts_query(['dorian', 'gray']).to_sql
  end
  
  test 'ts_query with integer returns query' do
    assert_equal "to_tsquery('english', '0:*' :: text)", Book.ts_query(0).to_sql
  end
  
  test 'ts_order returns ordering' do
    assert_equal '\'dorian gray\' :: text <-> "books"."ts"', Book.ts_order('dorian gray').to_sql
  end
  
  test 'search' do
    assert_equal (<<-SQL).strip.gsub(/\s+/, ' '), Book.search('dorian gray').to_sql.gsub(/\s+/, ' ')
      SELECT "books".*
      FROM "books"
      WHERE (to_tsvector('english', "books"."ts") @@ to_tsquery('english', 'dorian:* & gray:*' :: text))
      ORDER BY 'dorian gray' :: text <-> "books"."ts"
    SQL
  end
  
  test 'search with custom searhable_columns' do
    assert_equal (<<-SQL).strip.gsub(/\s+/, ' '), Novel.search('dorian gray').to_sql.gsub(/\s+/, ' ')
      SELECT "books".*
      FROM "books"
      WHERE (to_tsvector('english', "books"."ts") @@ to_tsquery('english', 'dorian:* & gray:*' :: text))
      ORDER BY 'dorian gray' :: text <-> "books"."ts"
    SQL
  end
  
  test 'search with integer columns' do
    assert_equal (<<-SQL).strip.gsub(/\s+/, ' '), Biography.search(0).to_sql.gsub(/\s+/, ' ')
      SELECT "books".*
      FROM "books"
      WHERE (to_tsvector('english', "books"."ts") @@ to_tsquery('english', '0:*' :: text))
      ORDER BY 0 :: text <-> "books"."ts"
    SQL
  end
  
  test 'search with array' do
    assert_equal (<<-SQL).strip.gsub(/\s+/, ' '), Book.search(['dorian', 'gray']).to_sql.gsub(/\s+/, ' ')
      SELECT "books".*
      FROM "books"
      WHERE (to_tsvector('english', "books"."ts") @@ to_tsquery('english', 'dorian:* & gray:*' :: text))
      ORDER BY 'dorian gray' :: text <-> "books"."ts"
    SQL
  end
  
  test 'search with join' do
    assert_equal (<<-SQL).strip.gsub(/\s+/, ' '), Author.search('dorian gray').to_sql.gsub(/\s+/, ' ')
      SELECT "authors".*
      FROM "authors"
      WHERE (to_tsvector('english', "authors"."ts") @@ to_tsquery('english', 'dorian:* & gray:*' :: text))
      ORDER BY 'dorian gray' :: text <-> "authors"."ts"
    SQL
  
    assert_equal (<<-SQL).strip.gsub(/\s+/, ' '), Cookbook.search('dorian gray').to_sql.gsub(/\s+/, ' ')
      SELECT "books".*
      FROM "books"
      WHERE (to_tsvector('english', "books"."ts") @@ to_tsquery('english', 'dorian:* & gray:*' :: text))
      ORDER BY 'dorian gray' :: text <-> "books"."ts"
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

