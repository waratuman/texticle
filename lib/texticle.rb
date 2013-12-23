module Texticle

  def self.extended(klass)
    klass.send(:class_attribute, :ts_column_names, :instance_accessor => false)
    klass.ts_column_names = []
  end

  def self.arel_columns(klass, value)
    if value.is_a?(Array)
      value.map { |v| arel_columns(klass, v) }
    elsif value.is_a?(Hash)
      value = value.first
      relation = klass.reflect_on_association(value[0])
      arel_columns(relation.klass, value[1])
    else
      klass.arel_table[value.to_s]
    end
  end

  def searchable(*columns)
    self.ts_column_names += columns
  end

  def ts_columns
    if ts_column_names.empty?
      searchable(*columns.select { |c| [:string, :text].include?(c.type) }.map(&:name))
    else
      ts_column_names
    end
  end

  def search(query, options={})
    return where(nil) if query.to_s.strip.empty?

    conditions = ts_vectors.map do |v|
      Arel::Nodes::InfixOperation.new('@@', v, ts_query(query))
    end
    conditions = conditions[1..-1].inject(conditions[0]) { |memo, c| Arel::Nodes::Or.new(memo, c) }

    joins = ts_relations.map(&:name).map(&:to_sym)

    where(conditions).order(ts_order(query)).joins(joins)
  end

  def ts_language
    "english"
  end

  def ts_vectors
    Texticle.arel_columns(self, ts_columns).map do |columns|
      columns = [columns] if !columns.is_a?(Array)
      document = Arel::Nodes::SqlLiteral.new(Arel::Nodes::NamedFunction.new('concat_ws', [' '] + columns).to_sql)
      expressions = [Arel::Nodes::SqlLiteral.new(connection.quote(ts_language)), Arel::Nodes::SqlLiteral.new(document)]
      Arel::Nodes::NamedFunction.new('to_tsvector', expressions)
    end
  end

  def ts_relations
    relations = []
    ts_columns.each do |value|
      if reflect_on_association(value)
        relations << reflect_on_association(value)
      elsif value.is_a?(Hash)
        relations << reflect_on_all_associations.find { |r| value.keys.map(&:to_s).include?(r.name.to_s) }
      end
    end
    relations.uniq
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
    orders = Texticle.arel_columns(self, ts_columns).map do |columns|
      columns = [columns] if !columns.is_a?(Array)
      document = Arel::Nodes::SqlLiteral.new(Arel::Nodes::NamedFunction.new('concat_ws', [' '] + columns).to_sql)
      Arel::Nodes::InfixOperation.new('<->', document, Arel::Nodes::InfixOperation.new('::', Arel::Nodes::SqlLiteral.new(connection.quote(query)), Arel::Nodes::SqlLiteral.new('text')))
    end

    orders.size > 1 ? Arel::Nodes::NamedFunction.new('LEAST', orders) : orders[0]
  end

end
