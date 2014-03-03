module Rails
  module Trash

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      
      def has_trash
        extend ClassMethodsMixin
        include InstanceMethods
        alias_method_chain :destroy, :trash
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
    
    end

    module InstanceMethods

      def destroy_with_trash
        return destroy_without_trash if @trash_is_disabled
        
        deleted_at = Time.now.utc
        self.update_attribute(:deleted_at, deleted_at)
        
        trash_associations(deleted_at)
      end

      def restore
        self.update_attribute(:deleted_at, nil)
        restore_associations
      end

      def disable_trash
        save_val = @trash_is_disabled
        begin
          @trash_is_disabled = true
          yield if block_given?
        ensure
          @trash_is_disabled = save_val
        end
      end

      def enable_trash
        save_val = @trash_is_disabled
        begin
          @trash_is_disabled = false
          yield if block_given?
        ensure
          @trash_is_disabled = save_val
        end
      end

      def trashed?
        deleted_at.present?
      end

      private

      def trash_associations(deleted_at)
        self.class.reflect_on_all_associations(:has_many).each do |reflection|
          if reflection.options[:dependent] == :destroy
            self.send(reflection.name).unscoped.update_all(:deleted_at => deleted_at)
          end
        end
      end

      def restore_associations
        self.class.reflect_on_all_associations(:has_many).each do |reflection|
          if reflection.options[:dependent] == :destroy
            self.send(reflection.name).unscoped.update_all(:deleted_at => nil)
          end
        end
      end

    end
  end
end

ActiveRecord::Base.send :include, Rails::Trash