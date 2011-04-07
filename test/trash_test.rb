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
end

##
# Factories
#

Factory.define :entry do |f|
  f.sequence(:title) { |n| "Entry##{n}" }
end

##
# And finally the test itself.
#

class TrashTest < Test::Unit::TestCase

  def setup
    setup_db
    @entry = Factory(:entry)
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

end
