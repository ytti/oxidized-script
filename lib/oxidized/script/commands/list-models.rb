module Oxidized
  class Script
    module Command
      class ListModels
        Name        = 'list-models'
        Description = 'list supported models'

        def self.run opts={}
          puts new(opts).models
          exit
        end

        def models
          out = ''
          models = Dir.glob File.join Config::ModelDir, '*.rb'
          models.each do |model|
            out += "%15s - %s\n" % [File.basename(model, '.rb'), model]
          end
          out
        end

        private

        def initialize opts={}
        end

      end
    end
  end
end
