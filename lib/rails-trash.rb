module Rails
  module Trash

    def self.included(base)
      base.attr_accessible :deleted_at
      base.extend ClassMethods
    end

    module ClassMethods
      
      def has_trash
        extend ClassMethodsMixin
        include InstanceMethodsMixin
      end

      module ClassMethodsMixin

        def active
          where(:deleted_at => nil)
        end

        def deleted
          unscoped.where("`deleted_at` IS NOT NULL")
        end

        def find_in_trash(id)
          deleted.find(id)
        end

        def restore(id)
          deleted.find(id).restore
        end

      end

      module InstanceMethodsMixin

        def destroy
          deleted_at = Time.now.utc
          self.update_attribute(:deleted_at, deleted_at)
          trash_associations(deleted_at)
        end

        def restore
          self.update_attribute(:deleted_at, nil)
          restore_associations
        end

        def trashed?
          deleted_at.present?
        end

        private

        def trash_associations(deleted_at)
          self.class.reflect_on_all_associations(:has_many).each do |reflection|
            if reflection.options[:dependent] == :destroy
              self.send(reflection.name).update_all(:deleted_at => deleted_at)
            end
          end
        end

        def restore_associations
          self.class.reflect_on_all_associations(:has_many).each do |reflection|
            if reflection.options[:dependent] == :destroy
              associations = self.send(reflection.name)
              associations.deleted.update_all(:deleted_at => nil) if associations.deleted.count > 0
            end
          end
        end

      end
    end
  end
end

ActiveRecord::Base.send :include, Rails::Trash