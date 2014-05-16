#!/usr/bin/env ruby

module Oxidized
  require 'oxidized'
  class Script
    class ScriptError   < OxidizedError; end
    class NoNode        < ScriptError;   end
    class InvalidOption < ScriptError;   end
    class NoConnection  < ScriptError
      class << self
        attr_accessor :node_error
      end
    end


    # @param [String] command command to be sent
    # @return [String] output for command
    def cmd command
      out = ''
      out += "## OXS - #{command}\n" if @verbose
      out += @model.cmd command
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
      @verbose    = opts.delete :verbose
      raise InvalidOption, "#{opts} not recognized" unless opts.empty?
      Oxidized.mgr = Manager.new
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
      CFG.vars.enable = enable if enable
      CFG.timeout = timeout if timeout
      @model = @node.model
      @input = nil
      connect
      if block_given?
        yield self
        disconnect
      end
    end

    def connect
      @node.input.each do |input|
        begin
          @node.model.input = input.new
          @node.model.input.connect @node
          break
        rescue
        end
      end
      @input = @node.model.input
      NoConnection.node_error = @node.error
      raise NoConnection, 'unable to connect' unless @input.connected?
      @input.connect_cli
    end
  end
end
