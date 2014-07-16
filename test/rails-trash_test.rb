require 'rails'
require 'minitest/autorun'
require 'rubygems'
require 'active_record'
require 'rails-trash'
require 'factory_girl'

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

def setup_db
  silence_stream(STDOUT) do
    ActiveRecord::Schema.define(:version => 1) do
      create_table :sites do |t|
        t.string :name
      end

      create_table :entries do |t|
        t.string :title
        t.datetime :deleted_at
        t.integer :site_id
      end

      create_table :authors do |t|
        t.string :title
        t.datetime :deleted_at
        t.integer :entry_id
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

class Site < ActiveRecord::Base
  has_many :entries
end

class Entry < ActiveRecord::Base
  has_trash

  belongs_to :site
  has_many :comments, :dependent => :destroy
  has_one :author, :dependent => :destroy

  # Restore Callbacks
  before_restore :run_before_restore
  after_restore :run_after_restore

  attr_accessor :before_restore, :after_restore
  
  def run_before_restore
    @before_restore = true
  end

  def run_after_restore
    @after_restore = true
  end

  # Destroy Callbacks
  before_destroy :run_before_destroy
  after_destroy :run_after_destroy

  attr_accessor :before_destroy, :after_destroy
  def run_before_destroy
    @before_destroy = true
  end

  def run_after_destroy
    @after_destroy = true
  end
end

class Author < ActiveRecord::Base
  has_trash

  belongs_to :entry
end

class Comment < ActiveRecord::Base
  has_trash
  belongs_to :entry
end

##
# Factories
#

FactoryGirl.define do
  factory :site do
    sequence(:name) { |n| "Site##{n}" }
  end

  factory :entry do
    sequence(:title) { |n| "Entry##{n}" }
    association :site
  end

  factory :author do
    sequence(:title) { |n| "Author##{n}" }
    association :entry
  end

  factory :comment do
    sequence(:email) { |n| "email+#{n}@example.com" }
    association :entry
  end
end

##
# And finally the test itself.
#

class Rails::TrashTest < Minitest::Test

  def setup
    setup_db
    @entry = FactoryGirl.create(:entry)
    @author = FactoryGirl.create(:author, :entry => @entry)
    @comment = FactoryGirl.create(:comment, :entry => @entry)
  end

  def teardown
    teardown_db
  end

  def test_site_is_not_cluttered_with_has_trash_methods
    assert !Site.respond_to?(:deleted)
  end

  def test_deleted
    @entry.destroy
    assert Entry.count.eql?(0), "Expected 0 entries found #{Entry.count}."
    assert Entry.deleted.count.eql?(1), "Expected 1 entry found #{Entry.count}."
  end

  def test_delete_multiple
    @entry2 = FactoryGirl.create(:entry)
    Entry.destroy([@entry.id, @entry2.id])
    assert Entry.deleted.count.eql?(2), "Expected 2 entries found #{Entry.deleted.count}."
  end

  def test_deleted_associations
    @entry.destroy
    assert Comment.count.eql?(0), "Expected 0 comments found #{Comment.count}."
    assert Comment.deleted.count.eql?(1), "Expected 1 comment found #{Comment.count}."
    assert Author.count.eql?(0), "Expected 0 authors found #{Author.count}."
    assert Author.deleted.count.eql?(1), "Expected 1 author found #{Author.count}."
  end

  def test_restore
    @entry.destroy
    Entry.deleted.first.restore
    assert Entry.deleted.count.eql?(0), "Expected 0 entries found #{Entry.count}"
    assert Entry.count.eql?(1), "Expected 1 entry found #{Entry.count}"
  end

  def test_restore_associations
    @entry.destroy
    Entry.deleted.first.restore
    assert Comment.count.eql?(1), "Expected 1 comment found #{Comment.count}."
    assert Comment.deleted.count.eql?(0), "Expected 0 comments found #{Comment.count}."
    assert Author.count.eql?(0), "Expected 0 authors found #{Author.count}."
    assert Author.deleted.count.eql?(1), "Expected 1 author found #{Author.count}."
  end

  def test_restore_without_associations
    @entry2 = FactoryGirl.create(:entry)
    @entry2.destroy
    Entry.deleted.first.restore
    assert @entry2.comments.count.eql?(0), "Expected 0 found comments #{@entry2.comments.count}."
    assert @entry2.author.eql?(nil), "Expected nil author found #{@entry2.author}."
  end

  def test_restore_class_method
    @entry.destroy
    Entry.restore(@entry.id)
    assert Entry.deleted.count.eql?(0), "Expected 0 entries found #{Entry.count}"
    assert Entry.count.eql?(1), "Expected 1 entry found #{Entry.count}"
  end

  def test_find_in_trash
    @entry.destroy
    entry = Entry.find_in_trash(@entry.id)
    assert_equal entry.id, @entry.id, "Expected entry #{entry.id} found #{@entry.id}"
  end

  def test_find_perhaps_in_the_trash
    @entry.destroy
    entry = Entry.find_perhaps_in_the_trash(@entry.id)
    assert_equal entry.id, @entry.id, "Expected entry #{entry.id} found #{@entry.id}"
  end

  def test_destroy_in_cascade_still_works
    assert Comment.count.eql?(1), "Expected 1 comment found #{Comment.count}."
    assert Author.count.eql?(1), "Expected 1 author found #{Author.count}."
    @entry.destroy
    assert Comment.count.eql?(0), "Expected 0 comments found #{Comment.count}."
    assert Author.count.eql?(0), "Expected 0 authors found #{Author.count}."
  end

  def test_trashed
    @entry.destroy
    assert @entry.trashed? == true, "Expected true found #{@entry.trashed?}"
  end

  def test_disable_trash
    @entry.disable_trash
    assert @entry.trash_disabled == true, "Expected true found #{@entry.trash_disabled}"

    @entry.destroy
    assert Entry.count.eql?(0), "Expected 0 found #{Entry.count}."
    assert Entry.deleted.count.eql?(0), "Expected 0 found #{Entry.deleted.count}."
  end

  def test_disable_trash_associations
    @entry.disable_trash
    @entry.destroy
    assert Comment.count.eql?(0), "Expected 0 comments found #{Comment.count}."
    assert Comment.deleted.count.eql?(0), "Expected 0 comments found #{Comment.deleted.count}."
    assert Author.count.eql?(0), "Expected 0 authors found #{Comment.count}."
    assert Author.deleted.count.eql?(0), "Expected 0 authors found #{Comment.deleted.count}."
  end

  def test_enable_trash
    @entry.disable_trash
    @entry.enable_trash
    @entry.destroy
    assert Entry.count.eql?(0), "Expected 0 found #{Entry.count}."
    assert Entry.deleted.count.eql?(1), "Expected 1 found #{Entry.deleted.count}."
  end

  def test_enable_trash_associations
    @entry.disable_trash
    @entry.enable_trash
    @entry.destroy
    assert Comment.count.eql?(0), "Expected 0 comments found #{Comment.count}."
    assert Comment.deleted.count.eql?(1), "Expected 1 comment found #{Comment.deleted.count}."
    assert Author.count.eql?(0), "Expected 0 authors found #{Author.count}."
    assert Author.deleted.count.eql?(1), "Expected 1 author found #{Author.deleted.count}."
  end

  def test_delete_associations
    @entry.disable_trash
    @entry.destroy
    assert Comment.count.eql?(0), "Expected 0 found #{Comment.count}."
    assert Comment.deleted.count.eql?(0), "Expected 0 found #{Comment.deleted.count}."
    assert Author.count.eql?(0), "Expected 0 authors found #{Author.count}."
    assert Author.deleted.count.eql?(0), "Expected 0 authors found #{Author.deleted.count}."
  end

  def test_restore_callbacks
    @entry.destroy
    @entry.restore
    assert @entry.before_restore == true, "Expected before_restore to run"
    assert @entry.after_restore == true, "Expected after_restore to run"
  end

  def test_destroy_callbacks
    @entry.destroy
    assert @entry.before_destroy == true, "Expected before_destroy to run"
    assert @entry.after_destroy == true, "Expected after_destroy to run"
  end

end
