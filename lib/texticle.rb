module Texticle

  class << self

    def extended(klass)
      klass.send(:class_attribute, :fulltext_fields)
      klass.fulltext_fields = []
    end

  end

  def ts_language
    "english"
  end

  def ts_vector
    document = self.arel_table[:ts]
    language = Arel::Nodes.build_quoted(ts_language)
    Arel::Nodes::NamedFunction.new('to_tsvector', [language, document])
  end

  def ts_query_quote(string)
    string.gsub(/\(|\)|:|\||!|\&|\*/, ' ')
  end

  def ts_query(query)
    querytext = if query.is_a?(Array)
      query.map { |x| ts_query_quote(x.to_s) }
    else
      ts_query_quote(query.to_s.strip).split(/\s+/)
    end

    querytext = querytext.map { |q| q << ':*' }
    querytext = querytext[1..-1].inject(querytext[0]) { |memo, c| memo +  ' & ' + c }
    querytext = Arel::Nodes::InfixOperation.new('::', Arel::Nodes.build_quoted(querytext), Arel::Nodes::SqlLiteral.new('text'))
    # This has to be a SqlLiteral due to the following issue: https://github.com/rails/arel/issues/153.
    # expressions = [Arel::Nodes::SqlLiteral.new(connection.quote(ts_language)), Arel::Nodes::SqlLiteral.new(querytext.to_sql)]
    expressions = [Arel::Nodes.build_quoted(ts_language), querytext]
    Arel::Nodes::NamedFunction.new('to_tsquery', expressions)
  end

  def ts_order(query)
    query = query.join(' ') if query.is_a?(Array)
    query = Arel::Nodes::InfixOperation.new('::', Arel::Nodes.build_quoted(query), Arel::Nodes::SqlLiteral.new('text'))
    document = self.arel_table[:ts]
    order = Arel::Nodes::InfixOperation.new('<->', query, document)
  end

  def search(query, options={})
    return where(nil) if query.to_s.strip.empty?

    condition = Arel::Nodes::InfixOperation.new('@@', ts_vector, ts_query(query))
    where(condition).order(ts_order(query))
  end

end
