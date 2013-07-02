require 'virtus'

class GearmanAdminClient
  class RegisteredFunction
    include Virtus::ValueObject

    attribute :name, String
    attribute :jobs_in_queue, Integer
    attribute :running_jobs, Integer
    attribute :available_workers, Integer

  end
end
