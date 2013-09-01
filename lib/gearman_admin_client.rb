require 'celluloid'

require 'gearman_admin_client/worker'
require 'gearman_admin_client/registered_function'
require 'gearman_admin_client/connection'

class GearmanAdminClient
  include Celluloid

  trap_exit :disconnect
  finalizer :disconnect

  attr_reader :address, :connection

  def initialize(address)
    @address = address
    @connect = Connection.method(:new_link)
    build_connection
  end

  def workers
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

  def status
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

  def server_version
    connection.write('version')
    connection.read.strip
  end

  def shutdown(options = {})
    command = ['shutdown']

    if options.fetch(:graceful, false)
      command << 'graceful'
    end

    connection.write(command.join(' '))
    connection.read.strip

    connection.eof? && disconnect

    true
  end

  def max_queue_size(function_name, queue_size = nil)
    command = ['maxqueue', function_name, queue_size].compact

    connection.write(command.join(' '))
    connection.read.strip
  end

  def disconnect(actor = nil, reason = nil)
    if @connection && @connection.alive?
      @connection.terminate
    end

    if reason
      build_connection
    end
  end

  def disconnected?
    if @connection
      not @connection.alive?
    end
  end

  def build_connection
    @connection = @connect.call(@address)
  end

  def connect(&and_then)
    disconnect
    build_connection

    if and_then
      and_then.call(@connection)
    end
  end

end
