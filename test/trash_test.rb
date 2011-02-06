require 'test/unit'
require 'rubygems'
require 'active_record'
require 'trash'

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

class Entry < ActiveRecord::Base
  default_scope where(:deleted_at => nil)
  has_trash
end

class SimplifiedPermalinkTest < Test::Unit::TestCase

  def setup
    setup_db
    @entry = Entry.create :title => "Hello World"
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

end
