class CreateTexticleIndexesFor<%= name.capitalize %> < ActiveRecord::Migration
  def self.up
    execute(<<-SQL.strip)
      <%= Texticle::Indexer.up_migration(name) %>
    SQL
  end

  def self.down
    execute(<<-SQL.strip)
      <%= Texticle::Indexer.down_migration(name) %>
    SQL
  end
end
