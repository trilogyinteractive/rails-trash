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
          where("`deleted_at` IS NOT NULL")
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
        self.class.reflect_on_all_associations(:has_many).each do |reflection|
          if reflection.options[:dependent].eql?(:destroy)
            self.send(reflection.name).update_all(:deleted_at => deleted_at)
          end
        end
      end

      def restore
        self.update_attribute(:deleted_at, nil)
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

      def trashed?
        deleted_at.present?
      end

    end
  end
end

ActiveRecord::Base.send :include, Rails::Trash