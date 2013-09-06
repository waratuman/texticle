module Texticle

  def searchable_columns(*names)
    columns.select { |c| [:string, :text].include?(c.type) }.map(&:name)
  end

  def ts_language
    'english'
  end

  def ts_column_sets
    column_sets = if searchable_columns[0].is_a?(Array)
      searchable_columns.map do |array|
        Texticle.ts_arel_columns(self, array)
      end
    else
      searchable_columns.map { |c| Texticle.ts_arel_columns(self, c) }.map { |x| [x] }
    end
  end

  def ts_vectors
    ts_column_sets.map do |columns|
      coalesce = columns[1..-1].inject(columns[0]) { |memo, column| Arel::Nodes::InfixOperation.new('||', memo, column) }
      coalesce = Arel::Nodes::InfixOperation.new('::', Arel::Nodes::NamedFunction.new('COALESCE', [coalesce, '']), Arel::Nodes::SqlLiteral.new('text'))
      Arel::Nodes::NamedFunction.new('to_tsvector', [ts_language, coalesce])
    end
  end

  def ts_query(query)
    querytext = query.is_a?(Array) ? query.map(&:to_s).map(&:strip) : query.to_s.strip.split(" ")
    querytext = querytext[1..-1].inject(querytext[0]) { |memo, c| memo +  ' & ' + c }
    querytext << ':*'
    querytext = Arel::Nodes::InfixOperation.new('::', querytext.to_s, Arel::Nodes::SqlLiteral.new('text'))
    # Arel::Nodes::NamedFunction.new('to_tsquery', [ts_language, querytext])
    Arel::Nodes::NamedFunction.new('to_tsquery', [Arel::Nodes::SqlLiteral.new("'#{ts_language}'"), Arel::Nodes::SqlLiteral.new(querytext.to_sql)])
  end

  def ts_order(query)
    query = query.join(' ') if query.is_a?(Array)
    orders = ts_column_sets.map do |columns|
      coalesce = columns[1..-1].inject(columns[0]) { |memo, column| Arel::Nodes::InfixOperation.new('||', memo, column) }
      coalesce = Arel::Nodes::InfixOperation.new('::', Arel::Nodes::NamedFunction.new('COALESCE', [coalesce, '']), Arel::Nodes::SqlLiteral.new('text'))
      Arel::Nodes::InfixOperation.new('<->', coalesce, Arel::Nodes::InfixOperation.new('::', query, Arel::Nodes::SqlLiteral.new('text')))
    end

    orders.size > 1 ? Arel::Nodes::NamedFunction.new('LEAST', orders) : orders[0]
  end

  def search(query)
    return where(nil) if query.to_s.empty?

    conditions = ts_vectors.map do |v|
      Arel::Nodes::InfixOperation.new('@@', v, ts_query(query))
    end
    conditions = conditions[1..-1].inject(conditions[0]) { |memo, c| Arel::Nodes::Or.new(memo, c) }

    where(conditions).order(ts_order(query)).joins(Texticle.ts_relations(self).map(&:name).map(&:to_sym))
  end

  def self.ts_relations(model_class)
    relations = []
    model_class.searchable_columns.each do |value|
      if value.is_a?(Hash)
        relations << model_class.reflect_on_all_associations.find { |r| value.keys.map(&:to_s).include?(r.name.to_s) }
      end
    end
    relations.uniq
  end

  def self.ts_arel_columns(model_class, value)
    if value.is_a?(Array)
      value.map { |v| ts_arel_columns(model_class, v) }
    elsif value.is_a?(Hash)
      if value.size > 1
        value.map do |k, v|
          relation = model_class.reflect_on_all_associations.find { |r| r.name == k }
          ts_arel_columns(relation.klass, v)
        end
      else
        relation = model_class.reflect_on_all_associations.find { |r| r.name == value.first[0] }
        ts_arel_columns(relation.klass, value.first[1])
      end
    else
      model_class.arel_table[value]
    end
  end

end
