use Test::More tests => 47;

use_ok('QDB::Commands');

my ($endpoint, $url_params, $curl_params);
my %params = ();

sub contains {
  my ($str, $substr, $message) = @_;
  cmp_ok(index($str, $substr), '>', -1, $message);
}

# Status
($endpoint, $url_params) = QDB::Commands::status(gc => 0);
is($endpoint, 'status');
is($url_params, '');

($endpoint, $url_params) = QDB::Commands::status(gc => 1);
is($endpoint, 'status');
contains($url_params, 'gc=true');

# Queues
($endpoint) = QDB::Commands::queues(argv => []);
is($endpoint, 'q');

## Read
($endpoint) = QDB::Commands::queues(argv => ['audit']);
is($endpoint, 'q/audit', 'queues/read creates the endpoint correctly');

## Delete
($endpoint, $url_params, $curl_params) = QDB::Commands::queues(argv => ['audit'], delete => 1);
is($endpoint, 'q/audit', 'queue/delete creates the endpoint correctly');
contains($curl_params, '-X DELETE', 'queues delete has DELETE header');

## Create
%params = (
  create => 1,
  max_size => '10g',
  max_payload_size => '100m',
  argv => ['audit'],
);

($endpoint, $url_params, $curl_params) = QDB::Commands::queues(%params);

is($endpoint, 'q/audit', 'queue endpoint is correct');
contains($curl_params, '-d maxSize=10g', 'queues has maxSize');
contains($curl_params, '-d maxPayloadSize=100m', 'queues has maxPayloadSize');
contains($curl_params, '-X POST', 'queues has POST header');

# Message

## Read
%params = (
  argv        => ['audit'],
  single      => 1,
  from_id     => 1,
  from        => '2016/01/01',
  to          => '2016/12/31',
  routing_key => 'sample',
  timeout     => 4,
  headers     => 1,
  grep        => '/abc/'
);

($endpoint, $url_params, $curl_params) = QDB::Commands::messages(%params);

is($endpoint, 'q/audit', 'message/read endpoint is correct');
contains($url_params, 'single=true');
contains($url_params, 'fromId=1');
contains($url_params, 'from=2016/01/01');
contains($url_params, 'to=2016/12/31');
contains($url_params, 'routingKey=sample');
contains($url_params, 'timeoutMs=4');
contains($url_params, 'noHeaders=false');
contains($url_params, 'grep=/abc/');

is($curl_params, '');

# Timeline

## Read
%params = (
  argv => ['audit'],
);

($endpoint, $url_params, $curl_params) = QDB::Commands::timeline(%params);
is($endpoint, 'q/audit/timeline');

%params = (
  argv => ['audit'],
  bucket => 'awesome',
);

($endpoint, $url_params, $curl_params) = QDB::Commands::timeline(%params);
is($endpoint, 'q/audit/timeline/awesome');

# Inputs

## Read
%params = (
  argv => ['audit'],
);

($endpoint, $url_params, $curl_params) = QDB::Commands::inputs(%params);
is($endpoint, 'q/audit/in');

%params = (
  argv => ['audit', 'rabbit'],
);

($endpoint, $url_params, $curl_params) = QDB::Commands::inputs(%params);
is($endpoint, 'q/audit/in/rabbit');

## Create
%params = (
  argv     => ['audit', 'rabbit'],
  create   => 1,
  url      => 'amqp://127.0.0.1',
  queue    => 'backup',
  exchange => 'default',
);

($endpoint, $url_params, $curl_params) = QDB::Commands::inputs(%params);
is($endpoint, 'q/audit/in/rabbit');
contains($curl_params, '-X POST', 'inputs/create contains -X POST');
contains($curl_params, '-d type=rabbitmq', 'inputs/create contains -d type=rabbitmq');
contains($curl_params, '-d url=amqp://127.0.0.1', 'inputs/create contains -d url=amqp://127.0.0.1');
contains($curl_params, '-d queue=backup', 'inputs/create contains -d queue=backup');
contains($curl_params, '-d exchange=default', 'inputs/create contains -d queue=backup');

## Delete
%params = (
  argv   => ['audit', 'rabbit'],
  delete => 1,
);

($endpoint, $url_params, $curl_params) = QDB::Commands::inputs(%params);
is($endpoint, 'q/audit/in/rabbit', 'inputs/delete creates the correct url');
contains($curl_params, '-X DELETE', 'inputs/delete contains -X DELETE');

# Outputs

## Read
%params = (
  argv => ['audit'],
);

($endpoint, $url_params, $curl_params) = QDB::Commands::outputs(%params);
is($endpoint, 'q/audit/out', 'outputs/read creates the correct endpoint');

%params = (
  argv => ['audit', 'rabbit'],
);

($endpoint, $url_params, $curl_params) = QDB::Commands::outputs(%params);
is($endpoint, 'q/audit/out/rabbit');

## Create
%params = (
  argv        => ['audit', 'rabbit'],
  create      => 1,
  url         => 'amqp://127.0.0.1',
  queue       => 'backup',
  exchange    => 'default',
  from_id     => 1,
  routing_key => 'sample',
);

($endpoint, $url_params, $curl_params) = QDB::Commands::outputs(%params);
is($endpoint, 'q/audit/out/rabbit', 'outputs/create creates the correct endpoint');
contains($curl_params, '-X POST', 'outputs/create contains -X POST');
contains($curl_params, '-d type=rabbitmq', 'outputs/create contains -d type=rabbitmq');
contains($curl_params, '-d url=amqp://127.0.0.1', 'outputs/create contains -d url=amqp://127.0.0.1');
contains($curl_params, '-d queue=backup', 'outputs/create contains -d queue=backup');
contains($curl_params, '-d exchange=default', 'outputs/create contains -d queue=backup');
contains($curl_params, '-d routingKey=sample', 'outputs/create contains -d routingKey=sample');
contains($curl_params, '-d fromId=1', 'outputs/create contains -d fromId=1');

## Delete
%params = (
  argv   => ['audit', 'rabbit'],
  delete => 1,
);

($endpoint, $url_params, $curl_params) = QDB::Commands::outputs(%params);
is($endpoint, 'q/audit/out/rabbit', 'outputs/delete creates the correct url');
contains($curl_params, '-X DELETE', 'outputs/delete contains -X DELETE');

1;