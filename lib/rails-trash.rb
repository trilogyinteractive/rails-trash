module Rails
  module Trash

    def self.included(base)
      base.send :extend, Extension
    end

    module Extension
      ##
      #   class Entry < ActiveRecord::Base
      #     has_trash
      #   end
      #
      def has_trash
        extend ClassMethods
        include InstanceMethods
        alias_method_chain :destroy, :trash
      end
    end

    module ClassMethods

      def deleted(field = nil, value = nil)
        deleted_at = Arel::Table.new(self.table_name)[:deleted_at]
        data = unscoped
        data = data.where(field => value) if field && value
        data.where(deleted_at.not_eq(nil))
      end

      def find_in_trash(id)
        deleted.find(id)
      end

      def restore(id)
        find_in_trash(id).restore
      end

    end

    module InstanceMethods

      def self.included(base)
        base.class_eval do
          default_scope where(arel_table[:deleted_at].eq(nil)) if arel_table[:deleted_at]
        end
      end

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
