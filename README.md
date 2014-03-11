# Rails Trash

Simple trash for your models setting the `deleted_at` to `Time.now.utc`.

## Installing

Add it to your `Gemfile`:

    gem 'rails-trash', :github => 'trilogyinteractive/rails-trash'

## Setup

Create a migration to add a `deleted_at` column for all trashable models:

    add_column :post, :deleted_at, :timestamp
    add_column :comments, :deleted_at, :timestamp

Add the `has_trash` module, a `default scope`, and `attr_accessible` to each trashable model:

    class Post < ActiveRecord::Base
      has_trash
      default_scope where(arel_table[:deleted_at].eq(nil)) if arel_table[:deleted_at]
      attr_accessible :deleted_at
    end

## Usage

### Trashing and Restoring Records

Trash a record. This will also trash all `:dependent => :destroy` associations.

    Post.find(1).destroy

Restore a record from trash. This will also restore all `:dependent => :destroy` associations.

    Post.restore(1)


### Finding Records

Get all active records:

    Post.active

Get all deleted records:

    Post.deleted

Find a record in the trash:

    Post.find_in_trash(1)

Test if a record is trashed:

    Post.find(1).trashed?

### Disable / Enable Trash

The trash is enabled by default on all records. The trash can be disabled and re-enabled on any instance of a trashable model.

#### Usage

Disable the trash. This allows a record to be permanently deleted:

    Post.disable_trash

Enable the trash. This will prevent a record from being permanently deleted:

    Post.enable_trash

## Associations

Models that declare :dependent => :destroy associations will have the trash cascade down all of those associations. For example:

    class Post < ActiveRecord::Base
        has_many :comments, :dependent => :destroy
    end

    class Comment < ActiveRecord::Base
        belongs_to : post
    end

Calling #destroy on any post will trash that post's comments. Likewise, calling #restore on any post will restore that post's comments.

Similarly, calling #disable_trash on any post will disable the trash for that post's comments. And calling #enable_trash on any post will enable the trash for that post's comments.

## Tests

Run tests with:

    rake test

Copyright (c) 2011-2013 Francesc Esplugas Marti, released under the MIT license