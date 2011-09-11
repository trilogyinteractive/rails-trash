# Rails Trash

Simple trash for your models setting the `delete_at` to `Time.now.utc`.

## Installing

Add it to your `Gemfile`:

    gem 'rails-trash'
    # gem 'rails-trash', :git => 'https://github.com/fesplugas/rails-trash.git'

## Usage

Add to your entries the `deleted_at` attribute:

    add_column :entries, :deleted_at, :timestamp

And use it on your models.

    class Post < ActiveRecord::Base
      has_trash
    end

Get all deleted entries:

    Entry.deleted

Restore an element from trash:

    Entry.restore(1)

Find an element in the trash:

    Entry.find_in_trash(1)

Copyright (c) 2011 Francesc Esplugas Marti, released under the MIT license
