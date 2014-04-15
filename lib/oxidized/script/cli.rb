module Oxidized
  require_relative 'script'
  require 'slop'
  class Script
    class CLI
      class CLIError < ScriptError; end
      class NothingToDo < ScriptError; end

      def run
        connect
        if @opts[:commands]
          run_file @opts[:commands]
        elsif @cmd
          @oxs.cmd @cmd
        end
      end

      private

      def initialize
        @args, @opts = opts_parse load_dynamic
        CFG.debug = true if @opts[:debug]
        @host = @args.shift
        @cmd  = @args.shift if @args
        @oxs  = nil
        raise NothingToDo, 'no host given' if not @host
        raise NothingToDo, 'nothing to do, give command or -x' if not @cmd and not @opts[:commands]
      end

      def opts_parse cmds
        slop = Slop.new(:help=>true)
        slop.banner 'Usage: oxs [options] hostname [command]'
        slop.on 'm=', '--model',    'host model (ios, junos, etc), otherwise discovered from Oxidized source'
        slop.on 'x=', '--commands', 'commands file to be sent'
        slop.on 'u=', '--username', 'username to use'
        slop.on 'p=', '--password', 'password to use'
        slop.on 't=', '--timeout',  'timeout value to use'
        slop.on 'e=', '--enable',   'enable password to use'
        slop.on 'v',  '--verbose',  'verbose output, e.g. show commands sent'
        slop.on 'd',  '--debug',    'turn on debugging'
        cmds.each do |cmd|
          slop.on cmd[:name], cmd[:description] do
            cmd[:class].run(:args=>@args, :opts=>@opts, :host=>@host, :cmd=>@cmd)
          end
        end
        slop.parse
        [slop.parse!, slop]
      end

      def connect
        opts = {}
        opts[:host]     = @host
        [:model, :username, :password, :timeout, :enable, :verbose].each do |key|
          opts[key] = @opts[key] if @opts[key]
        end
        @oxs = Script.new opts
      end

      def run_file file
        out = ''
        file = file == '-' ? $stdin : File.read(file)
        file.each_line do |line|
          line.chomp!
          line.sub!(/\\n/, "\n") # tread escaped newline as newline
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
          cmd = Script::Command.const_get cmd
          name = cmd.const_get :Name
          desc = cmd.const_get :Description
          cmds << {:class=>cmd, :name=>name, :description=>desc}
        end
        cmds
      end

    end
  end
end
