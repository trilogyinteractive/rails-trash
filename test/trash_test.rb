require 'test/unit'
require 'rubygems'
require 'active_record'
require 'trash'
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

class TrashTest < Test::Unit::TestCase

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
    assert_equal 0, Entry.count
    assert_equal 1, Entry.deleted.count
  end

  def test_restore
    @entry.destroy
    Entry.deleted.first.restore
    assert_equal 0, Entry.deleted.count
    assert_equal 1, Entry.count
  end

  def test_wipe
    @entry.destroy
    assert_equal 1, Entry.deleted.count
    entry = Entry.deleted.first
    entry.disable_trash { entry.destroy }
    assert_equal 0, Entry.deleted.count
  end

  def test_destroy_in_cascade_still_works
    assert Comment.count.eql?(1)
    @entry.destroy
    assert Comment.count.eql?(0)
  end

end