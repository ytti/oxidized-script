module Oxidized
  class Script
    module Command
      class ListModels < Base
        Name        = 'list-models'
        Description = 'list supported models'

        def self.run opts={}
          puts new(opts).models
        end

        def models
          out = ''
          models = Dir.glob File.join Config::MODEL_DIR, '*.rb'
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
