module Oxidized
  require_relative 'script'
  require 'slop'

  class Script
    class CLI
      attr_accessor :cmd_class
      class CLIError < ScriptError; end
      class NothingToDo < ScriptError; end

      def run
        if @group or @regex or @ostype
          $stdout.sync = true
          nodes = get_hosts
          counter = @threads.to_i
          Signal.trap("CLD")  { counter += 1 }
          nodes.each do |node| 
            Process.wait if counter <= 0
            puts "Forking " + node if @verbose
            counter -= 1
            fork {
              begin
                @host = node
                connect
                if @opts[:commands]
                  puts "Running commands on #{node}:\n#{run_file @opts[:commands]}"
                elsif @cmd
                  puts "Running commands on #{node}:\n#{@oxs.cmd @cmd}"
                end
              rescue => error
                puts "We had the following error on node #{node}:\n#{error}"
              end
            }
          end
          Process.waitall
        else
          connect
          if @opts[:commands]
            puts run_file @opts[:commands]
          elsif @cmd
            puts @oxs.cmd @cmd
          end
        end
      end

      private

      def initialize
        @args, @opts = opts_parse load_dynamic

        Config.load(@opts)
        Oxidized.setup_logger

        if @opts[:commands]
          Oxidized.config.vars.ssh_no_exec = true
        end

        if @cmd_class
          @cmd_class.run :args=>@args, :opts=>@opts, :host=>@host, :cmd=>@cmd
          exit 0
        else
          if @group or @regex or @ostype
            @cmd = @args.shift
          else
            @host = @args.shift
            @cmd  = @args.shift if @args
          end
          @oxs  = nil
          raise NothingToDo, 'no host given' if not @host and not @group and not @ostype and not @regex
          if @dryrun
            puts get_hosts
            exit
          end
          raise NothingToDo, 'nothing to do, give command or -x' if not @cmd and not @opts[:commands]
        end
      end

      def opts_parse cmds
        slop = Slop.new(:help=>true)
        slop.banner 'Usage: oxs [options] hostname [command]'
        slop.on 'm=', '--model',     'host model (ios, junos, etc), otherwise discovered from Oxidized source'
        slop.on 'o=', '--ostype',    'OS Type (ios, junos, etc)'
        slop.on 'x=', '--commands',  'commands file to be sent'
        slop.on 'u=', '--username',  'username to use'
        slop.on 'p=', '--password',  'password to use'
        slop.on 't=', '--timeout',   'timeout value to use'
        slop.on 'e=', '--enable',    'enable password to use'
        slop.on 'c=', '--community', 'snmp community to use for discovery'
        slop.on 'g=', '--group',     'group to run commands on (ios, junos, etc), specified in oxidized db'
        slop.on 'r=', '--threads',   'specify ammount of threads to use for running group', default: '1'
        slop.on       '--regex=',    'run on all hosts that match the regexp'
        slop.on       '--dryrun',    'do a dry run on either groups or regexp to find matching hosts'
        slop.on       '--protocols=','protocols to use, default "ssh, telnet"'
        slop.on 'v',  '--verbose',   'verbose output, e.g. show commands sent'
        slop.on 'd',  '--debug',     'turn on debugging'
        slop.on :terse, 'display clean output'
        cmds.each do |cmd|
          if cmd[:class].respond_to? :cmdline
            cmd[:class].cmdline slop, self
          else
            slop.on cmd[:name], cmd[:description] do
              @cmd_class = cmd[:class]
            end
          end
        end
        slop.parse
        @group = slop[:group]
        @ostype = slop[:ostype]
        @threads = slop[:threads]
        @verbose = slop[:verbose]
        @dryrun= slop[:dryrun]
        @regex = slop[:regex]
        [slop.parse!, slop]
      end

      def connect
        opts = {}
        opts[:host]     = @host
        [:model, :username, :password, :timeout, :enable, :verbose, :community, :protocols].each do |key|
          opts[key] = @opts[key] if @opts[key]
        end
        @oxs = Script.new opts
      end

      def run_file file
        out = ''
        file = file == '-' ? $stdin : File.read(file)
        file.each_line do |line|
          line.chomp!
          # line.sub!(/\\n/, "\n") # treat escaped newline as newline
          out += @oxs.cmd line
        end
        out
      end

      def load_dynamic
        cmds = []
        files = File.dirname __FILE__
        files = File.join files, 'commands', '*.rb'
        files = Dir.glob files
        files.each { |file| require_relative file }
        Script::Command.constants.each do |cmd|
          next if cmd == :Base
          cmd = Script::Command.const_get cmd
          name = cmd.const_get :Name
          desc = cmd.const_get :Description
          cmds << {:class=>cmd, :name=>name, :description=>desc}
        end
        cmds
      end

      def get_hosts
        if @ostype and @group and @regex
          puts "running list for hosts in group: #{@group} and matching ostype: #{@ostype} and matching: #{@regex}" if @verbose
          nodes_group = run_group @group
          nodes_ostype = run_ostype @ostype
          nodes_regex = run_regex @regex
          return nodes_group & nodes_regex & nodes_ostype
        elsif @group and @regex
          puts "running list for hosts in group: #{@group} and matching: #{@regex}" if @verbose
          nodes_group = run_group @group
          nodes_regex = run_regex @regex
          return nodes_group & nodes_regex
        elsif @regex and @ostype
          puts "running list for hosts matching ostype: #{@ostype} and matching: #{@regex}" if @verbose
          nodes_regex = run_regex @regex
          nodes_ostype = run_ostype @ostype
          return nodes_regex & nodes_ostype
        elsif @group and @ostype
          puts "running list for hosts in group: #{@group} and matching ostype: #{@ostype}" if @verbose
          nodes_group = run_group @group
          nodes_ostype = run_ostype @ostype
          return nodes_group & nodes_ostype
        elsif @regex
          puts 'running list for hosts matching: ' + @regex if @verbose
          return run_regex @regex
        elsif @ostype
          puts 'running list for hosts matching ostype: ' + @ostype if @verbose
          return run_ostype @ostype
        else
          puts 'running list for hosts in group: ' + @group if @verbose
          return run_group @group
        end
      end

      def run_group group
        Oxidized.mgr = Manager.new
        out = []
        Nodes.new.each do |node|
          next unless group == node.group
          out << node.name
        end
        out
      end

      def run_ostype ostype
        Oxidized.mgr = Manager.new
        out = []
        Nodes.new.each do |node|
          ostype.downcase # need to make sure they are both in lowercase
          nodemodel = node.model.to_s.downcase # need to make sure they are both in lowercase
          next unless nodemodel =~ /#{ostype}/ 
          out << node.name
        end
        out
      end

      def run_regex regex
        Oxidized.mgr = Manager.new
        out = []
        Nodes.new.each do |node|
          next unless node.name =~ /#{regex}/
          out << node.name
        end
        out
      end

    end
  end
end
