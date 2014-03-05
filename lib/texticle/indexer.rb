module Texticle
  module Indexer
    extend self

    def up_migration(model_name)
      model = Kernel.const_get(model_name.capitalize)

      index_columns = model.ts_vectors.map(&:to_sql)
      
      index_columns.reject! { |x| !(x.include?(model.table_name)) }
      <<-SQL
        CREATE index #{index_name(model)} ON #{model.table_name}
        USING GIN(#{index_columns.join(', ')});
      SQL
    end

    def down_migration(model_name)
      model = Kernel.const_get(model_name.capitalize)

      <<-SQL
        DROP INDEX IF EXISTS #{index_name(model)};
      SQL
    end

    def index_name(model)
      "#{model.table_name}_fulltext_idx"
    end

  end
end
