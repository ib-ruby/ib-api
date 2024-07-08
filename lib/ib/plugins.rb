module IB
  module Plugins
    def activate_plugin *names
      root= Pathname.new( File.expand_path("../../../", __FILE__ ))

      names.map{|y| y.to_s.gsub("_","-")}.each do |n|
        unless  @plugins.include? n
          # root=  base directory of the ib-api source
          # plugins are defined in ib-api/plugins/ib
          filename=  root + "plugins/ib/#{n}.rb"
          if filename.exist?
            if require  filename
              @plugins << n
              true # return value
            else
              error "Could not load Plugin `#{n}` --> #{filename} "
            end
          else
            error "Plugin `#{n}` not found in `plugins/ib/`"
            nil
          end
        else
          IB::Connection.logger.debug "Already activated plugin #{n}"
        end
      end
    end
  end
end
