require "autosaveable/version"
require "autosaveable/has_autosave"
require "autosaveable/active_admin"

require "autosaveable/serializers/yaml"

module AutoSaveable


end #/AutoSaveable

# inject our stuff on load so we can do "has_saveable" instead of Include AutoSaveable::Model

ActiveSupport.on_load(:active_record) do
  include AutoSaveable::Model
end
