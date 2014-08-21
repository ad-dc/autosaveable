module AutoSaveable
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
        resource_string = resource_class.to_s.downcase

        current_resource = resource_class.find(params[:id])
        div :class => "autosave_status" do
          span "Autosave idle...", :class => "text_status"

        end
        ul :id => "autosaves_list" do
          if !current_resource.autosaves.empty?
            current_resource.autosaves.reverse.each do |autosave|
              li link_to "Autosave #{autosave.created_at.to_s :long_ordinal}", send("edit_admin_#{resource_string.downcase}_path", :autosave_id => autosave.id)
            end
          else
            li "No autosaves yet."
          end
        end


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
          current_resource = resource_class.find(params[:id])
          #current_resource = self.instance_variable_get "@#{resource_string}"
          if params[:autosave_id]
            version_to_replace_with = current_resource.autosaves.find(params[:autosave_id])
            instance_variable_set "@#{resource_string}", version_to_replace_with.reify
            flash.now[:notice] = "Restored Autosave ##{params[:autosave_id]}"
          else
            last_version = current_resource.autosaves.last
            if last_version && (last_version.created_at > current_resource.updated_at)
              instance_variable_set "@#{resource_string}", last_version.reify
              flash.now[:notice] = "Auto-restored a more recent autosave. Live version of this #{resource_string} is unaffected."
            end
          end
        end
      end
    end #/self.included:ActiveAdmin

  end #/activeadmin
end
