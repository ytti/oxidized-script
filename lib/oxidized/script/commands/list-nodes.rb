module Oxidized
  class Script
    module Command
      class ListNodes
        Name        = 'list-nodes'
        Description = 'list nodes in oxidized source'

        def self.run opts={}
          puts new(opts).nodes
          exit
        end

        def nodes
          out = ''
          Nodes.new.each do |node|
            out += "#{node.name}:\n"
            node.instance_variables.each do |var|
              name  = var.to_s[1..-1]
              next if name == 'name'
              value = node.instance_variable_get var
              value = value.class if name == 'model'
              out += "  %10s => %s\n" % [name, value.to_s]
            end
          end
          out
        end

        private

        def initialize opts={}
          Oxidized.mgr = Manager.new
        end

      end
    end
  end
end
