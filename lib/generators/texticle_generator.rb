require 'texticle/indexer'
require 'rails/generators'
require 'rails/generators/active_record'

class TexticleGenerator < ActiveRecord::Generators::Base

  source_root File.expand_path('../../texticle', __FILE__)

  def copy_files
    migration_template 'migration.rb', "db/migrate/create_texticle_indexes_for_#{name.downcase}.rb"
  end

end
