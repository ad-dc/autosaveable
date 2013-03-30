require "autosaveable/version"
require 'yaml'

module AutoSaveable
  module Model
    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
      def has_autosave(options={})
        send :include, InstanceMethods

        class_attribute :autosave_association_name
        self.autosave_association_name = options[:autosave] || :autosave
        attr_accessor self.autosave_association_name

        class_attribute :autosave_class_name
        self.autosave_class_name = options[:class_name] || '::AutoSave'

        class_attribute :autosave_enabled_for_model
        self.autosave_enabled_for_model = true

        class_attribute :autosaves_association_name
        self.autosaves_association_name = options[:autosaves] || :autosaves

        has_many self.autosaves_association_name,
          :class_name => autosave_class_name,
          :as => :item,
          :order => "created_at ASC, id ASC"

        after_destroy :nuke_records
      end # /has_autosave


      def serialize_attributes_for_autosave(attributes)
        serialized_attributes.each do |key, coder|
          if attributes.key?(key)
            coder = AutoSaveable::Serializers::Yaml
            attributes[key] = coder.dump(attributes[key])
          end
        end
      end

      def unserialize_attributes_for_autosave(attributes)
        serialized_attributes.each do |key, coder|
          if attributes.key?(key)
            coder = AutoSaveable::Serializers::Yaml
            attributes[key] = coder.load(attributes[key])
          end
        end
      end

    end

    module InstanceMethods
      # useful note: you can figure out where a method is coming from with:
      # Release.method(:autosave)

      def record_autosave
        if changed_significantly?
          data = {
            :item_id => self.id,
            :event => 'autosave',
            :object => object_to_autosave_string(self),
            :whodunnit => 'system'
          }
          send(self.class.autosaves_association_name).create! data
        end
      end

      def record_manualsave
        data = {
          :item_id => self.id,
          :event => 'manualsave',
          :object => object_to_autosave_string(self),
          :whodunnit => 'system'
        }
        send(self.class.autosaves_association_name).create! data
      end

      private

      def changed_significantly?
        last_autosave = self.autosaves.last
        last_autosave.nil? ? true : object_to_autosave_string(self) != last_autosave.object
      end

      def nuke_records
        #this is untested and probably dangerous
        send(self.class.autosaves_association_name).delete_all
      end

      def object_to_autosave_string(object)
        _attrs = object.attributes.tap do |attributes|
          self.class.serialize_attributes_for_autosave attributes
        end
        coder = AutoSaveable::Serializers::Yaml
        coder.dump(_attrs)
      end
    end # /InstanceMethods
  end # /Model

  module Serializers
    module Yaml
      extend self # makes all instance methods become module methods as well

      def load(string)
        YAML.load string
      end

      def dump(object)
        YAML.dump object
      end
    end
  end

  module ActiveAdmin
    def self.included(base)

      def resource_class
        resource_string.camelize.constantize
      end

      base.action_item :only => :edit do
        resource_string = base.config.resource_name
        link_to "Versions of this post", send("versions_admin_#{resource_string.downcase}_path")
      end

      base.action_item :only => :versions do
        resource_string = base.config.resource_name
        link_to "Return to edit", send("edit_admin_#{resource_string.downcase}_path")
      end

      # this seems to work without the block... not really sure why.
      base.send :member_action, :versions

      base.sidebar :autosaves, :only => :edit do
        ul do
          li "Second List First Item"
          li "Second List Second Item"
        end
        p "we could put autosaves here"
      end

      base.controller do
        def rollback
          @resource = resource_class.find(params[:id])
          version = @resource.versions.find(params[:version].to_i)
          
          @version = version.event == "autosave" ? version : version.next
          
          @version.reify.save
          redirect_to :back, :notice => "Reverted."
        end

        def edit
          resource_string = resource_class.to_s.downcase
          current_resource = self.instance_variable_get "@#{resource_string}"
          last_version = current_resource.autosaves.last
          if last_version && (last_version.created_at > current_resource.updated_at)
            instance_variable_set "@#{resource_string}", last_version.reify
            flash.now[:notice] = "Auto-restored a more recent autosave. Live version of this #{resource_string} is unaffected."
          end
        end
      end
    end #/self.included:ActiveAdmin

  end #/activeadmin
end #/AutoSave

# inject our stuff on load so we can do "has_saveable" instead of Include AutoSaveable::Model

ActiveSupport.on_load(:active_record) do
  include AutoSaveable::Model
end
