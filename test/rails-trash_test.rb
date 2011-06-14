module Rails
  module VERSION
    MAJOR = 3
    MINOR = 1
    TINY  = 0
    PRE   = "rc1"

    STRING = [MAJOR, MINOR, TINY, PRE].compact.join('.')
  end
end

require 'test/unit'
require 'rubygems'
require 'active_record'
require 'rails-trash'
require 'factory_girl'

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

def setup_db
  silence_stream(STDOUT) do
    ActiveRecord::Schema.define(:version => 1) do
      create_table :entries do |t|
        t.string :title
        t.datetime :deleted_at
      end

      create_table :comments do |t|
        t.string :email
        t.text :body
        t.datetime :deleted_at
        t.integer :entry_id
      end
    end
  end
end

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end

##
# Model definitions
#

class Entry < ActiveRecord::Base
  default_scope where(:deleted_at => nil)
  has_trash
  has_many :comments, :dependent => :destroy
end

class Comment < ActiveRecord::Base
  default_scope where(:deleted_at => nil)
  has_trash
  belongs_to :entry
end

##
# Factories
#

Factory.define :entry do |f|
  f.sequence(:title) { |n| "Entry##{n}" }
end

Factory.define :comment do |f|
  f.sequence(:email) { |n| "email+#{n}@example.com" }
  f.association :entry
end

##
# And finally the test itself.
#

class Rails::TrashTest < Test::Unit::TestCase

  def setup
    setup_db
    @entry = Factory(:entry)
    @comment = Factory(:comment, :entry => @entry)
  end

  def teardown
    teardown_db
  end

  def test_deleted
    @entry.destroy
    assert Entry.count.eql?(0)
    assert Entry.deleted.count.eql?(1)
  end

  def test_restore
    @entry.destroy
    Entry.deleted.first.restore
    assert Entry.deleted.count.eql?(0)
    assert Entry.count.eql?(1)
  end

  def test_restore_class_method
    @entry.destroy
    Entry.restore(@entry.id)
    assert Entry.deleted.count.eql?(0)
    assert Entry.count.eql?(1)
  end

  def test_find_in_trash
    @entry.destroy
    entry = Entry.find_in_trash(@entry.id)
    assert_equal entry.id, @entry.id
  end

  def test_wipe
    @entry.destroy
    assert Entry.deleted.count.eql?(1)
    entry = Entry.deleted.first
    entry.disable_trash { entry.destroy }
    assert Entry.deleted.count.eql?(0)
  end

  def test_destroy_in_cascade_still_works
    assert Comment.count.eql?(1)
    @entry.destroy
    assert Comment.count.eql?(0)
  end

  def test_trashed
    @entry.destroy
    assert @entry.trashed?
  end

end