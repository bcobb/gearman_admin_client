require 'forwardable'

class GearmanAdminClient
  class Connection
    extend Forwardable

    def_delegators :io, :close, :closed?, :eof?

    attr_reader :io

    def initialize(io)
      @io = io
    end

    def write(command)
      IO::select([], [io])
      io.puts(command)
    end

    def read
      IO::select([io])
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

  end
end
