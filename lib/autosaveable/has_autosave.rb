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
end #/module