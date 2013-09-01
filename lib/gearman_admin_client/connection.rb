require 'celluloid/io'
require 'forwardable'

class GearmanAdminClient
  class Connection
    include Celluloid::IO
    extend Forwardable

    def_delegators :io, :close, :closed?, :eof?

    finalizer :disconnect

    attr_reader :io

    def initialize(address)
      @address = address
    end

    def write(command)
      connect if disconnected?

      io.puts(command)
    end

    def read
      connect if disconnected?

      io.gets
    end

    def drain
      output = ''

      while line = read
        break if line.chop == '.'
        output << line
      end

      output
    end

    def connect
      host, port = @address.split(':')

      @io = TCPSocket.new(host, port)
    end

    def disconnect
      if @io
        @io.close unless @io.closed?
        @io = nil
      end
    end

    def disconnected?
      @io.nil?
    end

  end
end
