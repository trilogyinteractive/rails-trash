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
          self.update_attribute(:deleted_at, Time.now.utc) if self.deleted_at.nil?
          trash_associations
        end

        def restore
          self.update_attribute(:deleted_at, nil) unless self.deleted_at.nil?
          restore_associations
        end

        def trashed?
          deleted_at.present?
        end

        private

        def trash_associations
          self.class.reflect_on_all_associations(:has_many).each do |reflection|
            if reflection.options[:dependent] == :destroy
              self.send(reflection.name).each do |association|
                association.destroy
              end
            end
          end
        end

        def restore_associations
          self.class.reflect_on_all_associations(:has_many).each do |reflection|
            if reflection.options[:dependent] == :destroy
              begin
                self.send(reflection.name).deleted.each do |association|
                  association.restore if association.trashed?
                end
              rescue
                # There are no associations to delete
              end
            end
          end
        end

      end
    end
  end
end

ActiveRecord::Base.send :include, Rails::Trash