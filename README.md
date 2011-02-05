# Trash

Simple trash for your models setting the `delete_at` to `Time.now.utc`.

## Installing

Add it to your `Gemfile`:

    gem 'trash', :git => 'https://github.com/fesplugas/rails-trash.git'

## Usage

Add to your posts the `deleted_at` attribute:

    add_column :entries, :deleted_at, :timestamp

And use it on your controllers.

    class Post < ActiveRecord::Base
      enable_trash

      default_scope where(:deleted_at => nil)
    end

If you want to get the deleted entries:

    Entry.deleted

Copyright (c) 2011 Francesc Esplugas Marti, released under the MIT license
