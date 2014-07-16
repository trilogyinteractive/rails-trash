module Rails
  module Trash

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      
      def has_trash
        attr_accessor :trash_disabled
        define_model_callbacks :restore, :only => [:before, :after]


        default_scope { where(deleted_at: nil) }
        scope :deleted, -> { unscoped.where("`deleted_at` IS NOT NULL") }
        scope :active, -> { where(:deleted_at => nil) }

        extend ClassMethodsMixin
        include InstanceMethodsMixin
      end

      module ClassMethodsMixin

        def find_in_trash(id)
          deleted.find(id)
        end

        def find_perhaps_in_the_trash(id)
          unscoped.find(id)
        end

        def restore(id)
          deleted.find(id).restore
        end

      end

      module InstanceMethodsMixin

        def destroy
          run_callbacks :destroy do
            unless @trash_disabled
              self.update_attribute(:deleted_at, Time.now.utc) if self.deleted_at.nil?
              trash_associations
            else
              super
            end

            self
          end
        end

        def restore
          run_callbacks :restore do
            self.update_attribute(:deleted_at, nil) unless self.deleted_at.nil?
            restore_associations
            self
          end
        end

        def trashed?
          deleted_at.present?
        end

        def disable_trash
          @trash_disabled = true
          disable_trash_for_associations
        end

        def disable_trash_for_associations
          (dependent_destroy_associations(:has_many) + dependent_destroy_associations(:has_one)).each do |reflection|
            [self.send(reflection.name)].flatten.each do |association|
              association.disable_trash
            end
          end
        end

        def enable_trash
          @trash_disabled = false
          enable_trash_for_associations
        end

        def enable_trash_for_associations
          (dependent_destroy_associations(:has_many) + dependent_destroy_associations(:has_one)).each do |reflection|
            [self.send(reflection.name)].flatten.each do |association|
              association.enable_trash
            end
          end
        end

        private

        def trash_associations
          (dependent_destroy_associations(:has_many) + dependent_destroy_associations(:has_one)).each do |reflection|
            begin
              [self.send(reflection.name)].flatten.each do |association|
                association.destroy
              end
            rescue
              # There are no associations to delete
            end
          end
        end

        def restore_associations
          (dependent_destroy_associations(:has_many) + dependent_destroy_associations(:has_one)).each do |reflection|
            begin
              [self.send(reflection.name).deleted].flatten.each do |association|
                association.restore if association.trashed?
              end
            rescue
              # There are no associations to restore
            end
          end
        end

        def dependent_destroy_associations(type)
          self.class.reflect_on_all_associations(type).select do |reflection|
            reflection.options[:dependent] == :destroy
          end
        end

        def belongs_to_associations
          self.class.reflect_on_all_associations(:belongs_to)
        end

      end
    end
  end
end

ActiveRecord::Base.send :include, Rails::Trash
