require 'socket'

require 'gearman_admin_client/worker'
require 'gearman_admin_client/registered_function'
require 'gearman_admin_client/connection'

class GearmanAdminClient

  DISCONNECTED = :DISCONNECTED unless defined? DISCONNECTED

  class BadAddress < RuntimeError ; end

  attr_reader :address

  def initialize(address)
    @address = address
    @connection = DISCONNECTED
  end

  def workers
    connect! do |connection|
      connection.write('workers')
      output = connection.drain.split("\n")

      workers = output.map do |line|
        if line.end_with?(':')
          function_names = []
          remainder = line
        else
          segments = line.split(':')

          function_names = segments.pop.strip.split(' ')

          remainder = segments.join(':')
        end

        fd, ip_address, client_id = remainder.split(' ').map(&:strip)

        Worker.new(
          :file_descriptor => fd,
          :ip_address => ip_address,
          :client_id => client_id,
          :function_names => function_names
        )
      end
    end
  end

  def status
    connect! do |connection|
      connection.write('status')
      output = connection.drain.split("\n")

      output.map do |line|
        function_name, total, running, workers = line.split("\t")

        RegisteredFunction.new(
          :name => function_name,
          :jobs_in_queue => total,
          :running_jobs => running,
          :available_workers => workers
        )
      end
    end
  end

  def server_version
    connect! do |connection|
      connection.write('version')
      connection.read.strip
    end
  end

  def shutdown(options = {})
    connect! do |connection|
      command = ['shutdown']

      if options.fetch(:graceful, false)
        command << 'graceful'
      end

      connection.write(command.join(' '))
      connection.read.strip

      connection.eof? && disconnect!
    end

    true
  end

  def max_queue_size(function_name, queue_size = nil)
    connect! do |connection|
      command = ['maxqueue', function_name, queue_size].compact

      connection.write(command.join(' '))
      connection.read.strip
    end
  end

  def disconnected?
    DISCONNECTED == @connection
  end

  def disconnect!
    @connection.close
    @connection = DISCONNECTED
  end

  private

  def connect!(&and_then)
    if disconnected?
      just_open_a_socket do |socket|
        @connection = Connection.new(socket)
      end
    end

    and_then.call(@connection)
  end

  def just_open_a_socket
    host, port = address.split(':')

    if host && port
      yield TCPSocket.new(host, port)
    else
      raise BadAddress, "expected address to look like HOST:PORT"
    end
  end

end
