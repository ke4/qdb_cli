QDB Client
==========

##Description

A command line tool for managing qdb.

###Setup

Clone this respository and add the bin directory to your path. Set the environment variable QDB_URI to qdb's root.

###Running Tests

`perl -I path/to/lib tests/qdb.t`

##Usage

###Global Options

**`--verbose`**

Displays the CURL request sent to QDB.

**`--dry-run`**

Does not send any requests to QDB but displays what CURL request would be made.

###Status

**`qdb status [--gc]`**

Returns information about the status of qdb.

Use `--gc` to garbage collect for more accurate free memory info.

###Queues

**`qdb queues`**

Returns a list of all queues.

**`qdb queues <queue_id>`**

Shows the current values of the configurable parameters of the queue as well as its current status.

**`qdb queues <queue_id> --create [--max-size <size>] [--max-payload-size <size>]`**

Creates a queue with the given queue id. The maximum size of the queue can be configured with `--max-size`. The maximum message size can be configured with the `--max-payload-size` option.

**`qdb queues <queue_id> --delete`**

Deletes the given queue and gives the result of the current queues.

###Messages

**`qdb messages <queue_id> [--grep <expression>] [--routing-key <routing_key>] [--from-id 1] [--from <datetime>] [--to <datetime>] [--no-headers] [--single]`**

Multiple messages are streamed as they come in or from a past id or timestamp.

__DELETING MESSAGES???__

###Timeline

**`qdb timeline <queue_id> [--bucket bucket_id]`**

QBD maintains an efficient index of each queue by timestamp and message id. You can peek at this index using the timelines command.

You can specify a bucket by adding the bucket option.

###Inputs

**`qdb inputs <queue_id> [<input>]`**

This command shows the current values of the configurable parameters of the input as well as its current status.

**`qdb inputs <queue_id> <input> --create [--url <amqp://127.0.0.1>] [--queue <rabbitmq_queue>] [--exchange <rabbitmq_exchange>]`**

Creates an input to the given `queue_id`. `--url` is the url of RabbitMQ and `--queue` is the queue to use as an input. If the queue of exchange do not exist QDB will create them and bind them together.

**`qdb inputs <queue_id> <input> --delete`**

Deletes the given input and returns the rest of the inputs for the given queue_id.

###Outputs

**`qdb output <queue_id> [<output>]`**

Shows a list of current outputs for a queue.

**`qdb output <queue_id> <output> --create [--url <amqp://127.0.0.1>] [--queues <rabbitmq_queue_a>[,<rabbitmq_queue_b>]] [--exchange <rabbitmq_exchange>] [--grep <expression>] [--routing-key <routing_key>] [--from-id 1] [--from <datetime>] [--to <datetime>]`**

Create a QDB output to a RabbitMQ queue or exchange. You can specify multiple RabbitMQ queues.

**`qdb output <queue_id> [<output>] --delete`**

Deletes an output.

##Examples

**`qdb queues audit --create --max-size 10g --max-payload-size 10m`**

Creates a queue called "audit" with a maximum size of 10gb and a may payload size of 10mb.

**`qdb messages audit`**

Retrieves all messages (including the headers) from the "audit" queue.

**`qdb message audit --grep sample`**

Retrieves all messages (including the headers) from the "audit" queue that has the string "sample" in its body.

**`qdb message audit --routing-key study`**

Retrieves all messages (including the headers) from the "audit" queue that have the routing key "study".

