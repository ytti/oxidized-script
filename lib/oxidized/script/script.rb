#!/usr/bin/env ruby

module Oxidized
  require 'oxidized'
  require_relative 'command'
  class Script
    attr_reader :model

    class ScriptError   < OxidizedError; end
    class NoNode        < ScriptError;   end
    class InvalidOption < ScriptError;   end
    class NoConnection  < ScriptError
      attr_accessor :node_error
    end


    # @param [String] command command to be sent
    # @return [String] output for command
    def cmd command
      out = ''
      out += "## OXS - #{command}\n" if @verbose
      cmd_out = @model.cmd command
      out += cmd_out if cmd_out
      out
    end

    # disconnects from ssh/telnet session
    # @return [void]
    def disconnect
      @input.disconnect_cli
    end
    alias_method :close, :disconnect

    private

    # @param [Hash] opts options for Oxidized::Script
    # @option opts [String]  :host      hostname or ip address for Oxidized::Node
    # @option opts [String]  :model     node model (ios, junos etc) if defined, nodes are not loaded from source
    # @option opts [Fixnum]  :timeout   oxidized timeout
    # @option opts [String]  :username  username for login
    # @option opts [String]  :passsword password for login
    # @option opts [String]  :enable    enable password to use
    # @option opts [String]  :community community to use for discovery
    # @option opts [String]  :protocols protocols to use to connect, default "ssh ,telnet"
    # @option opts [boolean] :verbose   extra output, e.g. show command given in output
    # @yieldreturn [self] if called in block, returns self and disconnnects session after exiting block
    # @return [void]
    def initialize opts, &block
      host        = opts.delete :host
      model       = opts.delete :model
      timeout     = opts.delete :timeout
      username    = opts.delete :username
      password    = opts.delete :password
      enable      = opts.delete :enable
      community   = opts.delete :community
      group       = opts.delete :group
      @verbose    = opts.delete :verbose
      Oxidized.config.input.default = opts.delete :protocols if opts[:protocols]
      raise InvalidOption, "#{opts} not recognized" unless opts.empty?

      @@oxi ||= false
      if not @@oxi
        Oxidized.mgr = Manager.new
        @@oxi = true
      end

      @node = if model
                Node.new(:name=>host, :model=>model)
              else
                Nodes.new(:node=>host).first
              end
      if not @node
        begin
          require 'corona'
          community ||= Corona::CFG.community
        rescue LoadError
          raise NoNode, 'node not found'
        end
        node = Corona.poll :host=>host, :community=>community
        raise NoNode, 'node not found' unless node
        @node = Node.new :name=>host, :model=>node[:model]
      end
      @node.auth[:username] = username if username
      @node.auth[:password] = password if password
      Oxidized.config.vars.enable = enable if enable
      Oxidized.config.timeout = timeout if timeout
      @model = @node.model
      @input = nil
      connect
      if block_given?
        yield self
        disconnect
      end
    end

    def connect
      node_error = {}
      @node.input.each do |input|
        begin
          @node.model.input = input.new
          @node.model.input.connect @node
          break
        rescue => error
          node_error[input] = error
        end
      end
      @input = @node.model.input
      err = NoConnection.new
      err.node_error = node_error
      raise err, 'unable to connect' unless @input.connected?
      @input.connect_cli
    end
  end
end
