require 'gearmand_control'
require 'gearman_admin_client'

require 'timeout'
require 'securerandom'

describe GearmanAdminClient do

  before do
    @sockets = []
    @gearmand = GearmandControl.new(4730)
    @gearmand.start
  end

  after do
    @sockets.each(&:close)
    @gearmand.stop
  end

  def can_do(server_address, *function_names)
    host, port = server_address.split(':')
    socket = TCPSocket.new(host, port)

    @sockets << socket

    function_names.each do |function_name|
      request(socket, 1, [function_name])
    end
  end

  def submit_job_bg(server_address, *function_names)
    host, port = server_address.split(':')
    socket = TCPSocket.new(host, port)

    @sockets << socket

    function_names.each do |function_name|
      id = SecureRandom.hex
      request(socket, 18, [function_name, id, 'arg'])
    end
  end

  def request(socket, type, arguments)
    body = arguments.join("\0")
    header = ["\0REQ", type, body.size].pack('a4NN')

    IO::select([], [socket])
    socket.write(header + body)

    read_a_little_from(socket)
  end

  def read_a_little_from(socket)
    begin
      Timeout.timeout(1.0e-6, RuntimeError) do
        IO::select([socket])
        socket.read
      end
    rescue
    end
  end

  it 'knows the server version' do
    client = GearmanAdminClient.new(@gearmand.address)

    expect(client.server_version).to match(/OK \d+\.?+/)
  end

  it 'can shutdown the server gracefully' do
    client = GearmanAdminClient.new(@gearmand.address)

    client.shutdown :graceful => true

    expect do
      @gearmand.test!
    end.to raise_error(GearmandControl::TestFailed)
  end

  it 'can shutdown the server forcefully' do
    client = GearmanAdminClient.new(@gearmand.address)

    client.shutdown

    expect do
      @gearmand.test!
    end.to raise_error(GearmandControl::TestFailed)
  end

  it 'can list registered workers' do
    client = GearmanAdminClient.new(@gearmand.address)

    expect(client.workers).to be_empty

    can_do(@gearmand.address, 'function_1', 'function_2')
    can_do(@gearmand.address, 'function_3')

    functions = client.workers.
      map { |worker| worker.function_names.sort }.
      sort_by(&:size)

    expect(functions).to eql([
      ['function_3'],
      ['function_1', 'function_2']
    ])
  end

  it 'knows all registered functions' do
    client = GearmanAdminClient.new(@gearmand.address)

    expect(client.status).to be_empty

    can_do(@gearmand.address, 'function_1', 'function_2')
    can_do(@gearmand.address, 'function_3')
    submit_job_bg(@gearmand.address, 'function_2', 'function_4')

    expect(client.status.sort_by(&:name)).to eql([
      { :name => 'function_1', :jobs_in_queue => 0, :running_jobs => 0,
        :available_workers => 1 },
      { :name => 'function_2', :jobs_in_queue => 1, :running_jobs => 0,
        :available_workers => 1 },
      { :name => 'function_3', :jobs_in_queue => 0, :running_jobs => 0,
        :available_workers => 1 },
      { :name => 'function_4', :jobs_in_queue => 1, :running_jobs => 0,
        :available_workers => 0 }
    ].map(&GearmanAdminClient::RegisteredFunction.method(:new)))
  end

  it 'can set the max queue size' do
    client = GearmanAdminClient.new(@gearmand.address)

    can_do(@gearmand.address, 'function_1')

    client.max_queue_size('function_1', 1)

    2.times do
      submit_job_bg(@gearmand.address, 'function_1')
    end

    expect(client.status).to eql([GearmanAdminClient::RegisteredFunction.new(
      :name => 'function_1',
      :jobs_in_queue => 1,
      :running_jobs => 0,
      :available_workers => 1
    )])

    client.max_queue_size('function_1', 3)

    2.times do
      submit_job_bg(@gearmand.address, 'function_1')
    end

    expect(client.status).to eql([GearmanAdminClient::RegisteredFunction.new(
      :name => 'function_1',
      :jobs_in_queue => 3,
      :running_jobs => 0,
      :available_workers => 1
    )])
  end

end
