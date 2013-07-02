# GearmanAdminClient

Connect and issue administrative commands to a [Gearman](http://gearman.org) server. `GearmanAdminClient`'s API follows the Administrative Protocol closely. You can read more about the Adminstrative Protocol under the "Administrative Protocol" section of the [Gearman protocol specification](http://gearman.org/protocol).

## Usage

```ruby
client = GearmanAdminClient.new('localhost:4730')

# list registered workers
client.workers

# list registered functions
client.status

# set the maximum queue size for a function
client.max_queue_size('function_name', 1_000)

# get the version of the server
client.server_version

# shutdown the server gracefully
client.shutdown graceful: true

# shutdown the server forcefully
client.shutdown
```
