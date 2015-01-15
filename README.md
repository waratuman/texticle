

ActiveRecord extension for full text search in PostgreSQL.

## Installation

Add this line to your application's Gemfile:

    gem 'texticle', :github => 'waratuman/texticle'

And then execute:

    $ bundle

## Usage

Every model making use of Texticle needs to define the following function as in
the example below. In addition a field in the database called `ts` is required
as well.

    class Book < ActiveRecord::Base
      extend Texticle
      belongs_to :author

      after_save :update_fulltext_index

      self.fulltext_fields = %W[title subtitle]

    end

The `title` and `subtitle` fields of this model will then be added to the
fulltext index when `update_fulltext_index` index is called. This can be called
as a callback or put on a job queue so that creating an index does not happen
inside a web request (if you are using Rails).

    class Book < ActiveRecord::Base
      extend Texticle
      belongs_to :author

      after_save do |r|
        if r.changes.any? { |x| r.fulltext_fields.include?(x[0]) } }
          FulltextIndexJob.enqueue(r.class.base_class, r.id) 
         end
      end

      self.fulltext_fields = %W[title subtitle]

    end

Custom `#update_fulltext_index` methods can be used instead of the default:

    class Book < ActiveRecord::Base
      extend Texticle
      belongs_to :author

      after_save do |r|
        if r.changes.any? { |x| r.fulltext_fields.include?(x[0]) } }
          FulltextIndexJob.enqueue(r.class.base_class, r.id) 
         end
      end

      self.fulltext_fields = %W[title subtitle]

      def update_fulltext_index
        text = fulltext_fields.map { |x| read_attribute(x) } + [author.name]
        text = text.join("\n").gsub(/\s+/, ' ')
        update_column(:ts, text)
      end

    end

After the index is built `Book.search('dorian gray')` will search the `books`
table `ts` field.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Attribution

This is a simplification of the [Texticle gem](https://github.com/tenderlove/texticle), which has since been renamed to [Textacular](https://github.com/textacular/textacular)
