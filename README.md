# Rails Trash

Simple trash for your models setting the `deleted_at` to `Time.now.utc`.

## Installing

Add it to your `Gemfile`:

    gem 'rails-trash', :github => 'trilogyinteractive/rails-trash'

## Usage

Create a migration to add a `deleted_at` column for all trashable models:

    add_column :post, :deleted_at, :timestamp
    add_column :comments, :deleted_at, :timestamp

Add the `has_trash` module and add a `default scope` to each trashable model:

    class Post < ActiveRecord::Base
      has_trash
      default_scope where(arel_table[:deleted_at].eq(nil)) if arel_table[:deleted_at]
    end

Trash a record. This will also trash all `:dependent => :destroy` associations.

    Post.find(1).destroy

Restore a record from trash. This will also restore all `:dependent => :destroy` associations.

    Post.restore(1)

Get all active records:

    Post.active

Get all deleted records:

    Post.deleted

Find a record in the trash:

    Post.find_in_trash(1)

Test if a record is trashed:

    Post.find(1).trashed?

Copyright (c) 2011-2013 Francesc Esplugas Marti, released under the MIT license