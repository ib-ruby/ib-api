module IB
  module Plugins
    def activate_plugin name
      unless  @plugins.include? name
      # root=  base directory of the ib-api source
      root= Pathname.new( File.expand_path("../../../", __FILE__ ))
      # plugins are defined in ib-api/plugins/ib
      filename=  root + "plugins/ib/#{name}.rb"
      if filename.exist?
        if require  filename
          @plugins << name
          true # return value
        else
          error "Could not load Plugin `#{name}` --> #{filename} "
        end
      else
        error "Plugin `#{name}` not found in `plugins/ib/`"
        nil
      end
      else
        IB::Connection.logger.debug "Already activated plugin #{name}"
      end
    end
  end
end
