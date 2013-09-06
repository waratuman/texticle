# Texticle

ActiveRecord extension for full text search in PostgreSQL.

## Installation

Add this line to your application's Gemfile:

    gem 'texticle', :github => 'waratuman/texticle'

And then execute:

    $ bundle

## Usage

By default Texticle will search all text and string columns.

	# Attributes: [author, title, slug]
    class Book < ActiveRecord::Base
        extend Texticle

    end
 
`Book.search('dorian gray')` will search the author, title, and slug fields.

	# Attributes: [author, title, slug]
    class Book < ActiveRecord::Base
        extend Texticle

        def self.seachable_columns
            [:author, :title]
        end
    end

`Book.search('dorian gray')` will search the author, title fields.

    class Book < ActiveRecord::Base
        extend Texticle

        def self.seachable_columns
            [[:author, :title]]
        end
    end

`Book.search('dorian gray')` will search the author and title fields appended together.

To extend `Texticle` in every model add the following to either `config/application.rb` or create an initializer file (`config/initializers/texticle.rb`):

    ActiveSupport.on_load :active_record do
        extend Texticle
    end

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Attribution

This is a simplification of the [Texticle gem](https://github.com/tenderlove/texticle), which has since been renamed to [Textacular](https://github.com/textacular/textacular)
