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
        args, @opts = opts_parse
        CFG.debug = true if @opts[:debug]
        @host = args.shift
        @cmd  = args.shift if args
        @oxs  = nil
        raise NothingToDo, 'no host given' if not @host
        raise NothingToDo, 'nothing to do, give command or -x' if not @cmd and not @opts[:commands]
      end

      def opts_parse
        slop = Slop.parse(:help=>true) do
          banner 'Usage: oxs [options] hostname [command]'
          on 'm=', '--model',    'host model (ios, junos, etc), otherwise discovered from Oxidized source'
          on 'x=', '--commands', 'commands file to be sent'
          on 'u=', '--username', 'username to use'
          on 'p=', '--password', 'password to use'
          on 't=', '--timeout',  'timeout value to use'
          on 'e=', '--enable',   'enable password to use'
          on 'v',  '--verbose',  'verbose output, e.g. show commands sent'
          on 'd',  '--debug',    'turn on debugging'
        end
        [slop.parse!, slop]
      end

      def connect
        opts = {}
        opts[:host]     = @host
        [:model, :username, :passsword, :timeout, :enable, :verbose].each do |key|
          opts[key] = @opts[key] if @opts[key]
        end
        @oxs = Script.new opts
      end

      def run_file file
        out = ''
        file = file == '-' ? $stdin : File.read(file)
        file.each_line do |line|
          line.sub!(/\\n/, "\n") # tread escaped newline as newline
          out += @oxs.cmd line
        end
        out
      end

    end
  end
end
