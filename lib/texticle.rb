module Texticle

  def self.arel_columns(klass, value)
    if value.is_a?(Array)
      value.map { |v| Texticle.arel_columns(klass, v) }
    elsif value.is_a?(Hash)
      value.map { |k, v|
        relation = klass.reflect_on_all_associations.find { |r| r.name.to_s == k.to_s }
        Texticle.arel_columns(relation.klass, v)
      }.flatten
    else
      klass.arel_table[value.to_s]
    end
  end

  def self.ts_relations(klass)
    relations = []
    klass.searchable_columns.each do |value|
      if value.is_a?(Hash)
        relations << klass.reflect_on_all_associations.find { |r| value.keys.map(&:to_s).include?(r.name.to_s) }
      end
    end
    relations.uniq
  end

  def searchable_columns
    columns.select { |c| [:string, :text].include?(c.type) }.map(&:name)
  end

  def ts_columns
    columns = []
    searchable_columns.each do |arg|
      if arg.is_a?(Hash) || arg.is_a?(Array)
        columns << Texticle.arel_columns(self, arg)
      else
        columns << [Texticle.arel_columns(self, arg)]
      end
    end
    columns
  end

  def ts_language
    'english'
  end

  def ts_vectors
    ts_columns.map do |columns|
      columns[0] = Arel::Nodes::InfixOperation.new('::', columns[0], Arel::Nodes::SqlLiteral.new('text'))
      document = columns[1..-1].inject(columns[0]) { |memo, column| Arel::Nodes::InfixOperation.new('||', memo, Arel::Nodes::InfixOperation.new('::', column, Arel::Nodes::SqlLiteral.new('text'))) }
      expressions = [Arel::Nodes::SqlLiteral.new(connection.quote(ts_language)), Arel::Nodes::SqlLiteral.new(document.to_sql)]
      Arel::Nodes::NamedFunction.new('to_tsvector', expressions)
    end
  end

  def ts_query(query)
    querytext = if query.is_a?(Array)
      query.map(&:to_s).map { |x| x.gsub(/\(\):\|!&\*'/, '') }
    else
      query.to_s.strip.gsub(/\(|\)|:|\||!|\&|\*|'/, '').split(/\s+/)
    end
    querytext = querytext.map { |q| q << ':*' }
    querytext = querytext[1..-1].inject(querytext[0]) { |memo, c| memo +  ' & ' + c }
    querytext = Arel::Nodes::InfixOperation.new('::', querytext, Arel::Nodes::SqlLiteral.new('text'))
    # This has to be a SqlLiteral due to the following issue: https://github.com/rails/arel/issues/153.
    expressions = [Arel::Nodes::SqlLiteral.new(connection.quote(ts_language)), Arel::Nodes::SqlLiteral.new(querytext.to_sql)]
    Arel::Nodes::NamedFunction.new('to_tsquery', expressions)
  end
  
  def ts_order(query)
    query = query.join(' ') if query.is_a?(Array)
    orders = ts_columns.map do |columns|
      columns[0] = Arel::Nodes::InfixOperation.new('::', columns[0], Arel::Nodes::SqlLiteral.new('text'))
      document = columns[1..-1].inject(columns[0]) { |memo, column| Arel::Nodes::InfixOperation.new('||', memo, Arel::Nodes::InfixOperation.new('::', column, Arel::Nodes::SqlLiteral.new('text'))) }
      Arel::Nodes::InfixOperation.new('<->', document, Arel::Nodes::InfixOperation.new('::', query, Arel::Nodes::SqlLiteral.new('text')))
    end
  
    orders.size > 1 ? Arel::Nodes::NamedFunction.new('LEAST', orders) : orders[0]
  end
  
  def search(query)
    return where(nil) if query.to_s.empty?
  
    conditions = ts_vectors.map do |v|
      Arel::Nodes::InfixOperation.new('@@', v, ts_query(query))
    end
    conditions = conditions[1..-1].inject(conditions[0]) { |memo, c| Arel::Nodes::Or.new(memo, c) }
    
    joins = Texticle.ts_relations(self).map(&:name).map(&:to_sym)
  
    where(conditions).order(ts_order(query)).joins(joins)
  end


end
