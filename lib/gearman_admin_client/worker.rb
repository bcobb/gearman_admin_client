require 'virtus'

class GearmanAdminClient
  class Worker
    include Virtus::ValueObject

    attribute :file_descriptor, String
    attribute :ip_address, String
    attribute :client_id, String
    attribute :function_names, Array[String]

  end
end
