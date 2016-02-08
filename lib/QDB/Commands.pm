package QDB::Commands;

use strict;
use warnings;
use List::Util qw/reduce/;
use Exporter 'import';
our @EXPORT_OK = qw(status queues messages
                    timeline inputs outputs);


# Status
my $get_status = command(sub {
  return {
    endpoint   => 'status',
    url_params => { gc => 'gc=true', }
  }
});

sub status {
  my %params = @_;
  return $get_status->(%params);
}

# Queues
my $create_queue = command(sub {
  return {
    endpoint    => \&queue_endpoint,
    curl_params => {
      max_size         => '-d maxSize=%s',
      max_payload_size => '-d maxPayloadSize=%s',
      METHOD           => '-X POST',
    }
  };
});

my $delete_queue = command(sub {
  return {
    endpoint    => \&queue_endpoint,
    curl_params => { METHOD => '-X DELETE', }
  };
});

my $get_queue = command(sub {
  return {
    endpoint => \&queue_endpoint,
  };
});

sub queues {
  my %params = @_;
  if    ($params{'create'}) { return $create_queue->(%params); }
  elsif ($params{'delete'}) { return $delete_queue->(%params); }
  else                      { return $get_queue->(%params);    }
}

# Messages
my $get_messages = command(sub{
  return {
    endpoint   => \&queue_endpoint,
    url_params => {
      single      => 'single=true',
      from_id     => 'fromId=%s',
      from        => 'from=%s',
      to          => 'to=%s',
      routing_key => 'routingKey=%s',
      timeout     => 'timeoutMs=%s',
      headers     => 'noHeaders=false',
      grep        => 'grep=%s',
    }
  };
});

sub messages {
  my %params = @_;
  return $get_messages->(%params);
}

# Timeline
my $get_timeline = command(sub{
  return {
    endpoint => sub {
      my $args = shift;
      my $url  = 'q/'. $args->{'argv'}[0] .'/timeline';
      return $args->{'bucket'} ? $url . "/" . $args->{'bucket'} : $url;
    }
  };
});

sub timeline {
  my %params = @_;
  return $get_timeline->(%params);
}

sub input_output_endpoint {
  my $in_or_out = shift;
  return sub {
    my $args = shift;
    my $endpoint = queue_endpoint($args) . '/' . $in_or_out;
    return @{$args->{'argv'}}[1] ? $endpoint . '/' . @{$args->{'argv'}}[1] : $endpoint;
  }
}

# Inputs

my $get_inputs = command(sub {
  return { endpoint => input_output_endpoint('in'), }
});

my $create_inputs = command(sub {
  return {
    endpoint => input_output_endpoint('in'),
    curl_params => {
      METHOD   => '-X POST',
      type     => '-d type=rabbitmq',
      url      => '-d url=%s',
      queue    => '-d queue=%s',
      exchange => '-d exchange=%s',
    }
  }
});

my $delete_inputs = command(sub {
  return {
    endpoint => input_output_endpoint('in'),
    curl_params => {
      METHOD => '-X DELETE',
    },
  };
});

sub inputs {
  my %params = @_;
  if    ($params{'create'}) { $create_inputs->(%params, type => 'rabbitmq'); }
  elsif ($params{'delete'}) { $delete_inputs->(%params); }
  else { $get_inputs->(%params); }
}

my $get_output = command(sub{
  return { endpoint => input_output_endpoint('out'), }
});

my $create_output = command(sub {
  return {
    endpoint => input_output_endpoint('out'),
    curl_params => {
      METHOD      => '-X POST',
      type        => '-d type=rabbitmq',
      url         => '-d url=%s',
      queue       => '-d queue=backup',
      exchange    => '-d exchange=default',
      routing_key => '-d routingKey=%s',
      from_id     => '-d fromId=%s',
    },
  }
});

my $delete_output = command(sub {
  return {
    endpoint => input_output_endpoint('out'),
    curl_params => {
      METHOD => '-X DELETE',
    },
  };
});

sub outputs {
  my %params = @_;
  if ($params{'create'})    { $create_output->(%params, type => 'rabbitmq') }
  elsif ($params{'delete'}) { $delete_output->(%params) }
  else { $get_output->(%params) };
}

sub command {
  my $fn = shift;

  return sub {
    my %args = @_;
    my $command_params = $fn->();
    my $endpoint    = endpoint(\%args, $command_params->{'endpoint'});
    my $url_params  = url_params(\%args, $command_params->{'url_params'});
    my $curl_params = curl_params(\%args, $command_params->{'curl_params'});
    return ($endpoint, $url_params, $curl_params);
  }
}

sub endpoint {
  my ($args, $endpoint) = @_;

  if (ref($endpoint) eq 'HASH') {
    my $key = (keys %{$endpoint})[0];
    return sprintf $endpoint->{$key}, $args->{$key};
  } elsif (ref($endpoint) eq 'CODE') {
    return $endpoint->($args);
  } else {
    return $endpoint;
  }
}

sub url_params {
  my ($args, $url_params, $param_str) = @_;
  $param_str ||= [];
  my @url_param_keys = keys(%{$url_params});
  return join "&", @{$param_str} if scalar @url_param_keys == 0;

  my $param_key   = $url_param_keys[0];
  my $param_value = delete $url_params->{$param_key};

  push @{$param_str}, sprintf $param_value, $args->{$param_key} if $args->{$param_key};

  return url_params($args, $url_params, $param_str);
}

sub curl_params {
  my ($args, $curl_params, $param_str) = @_;
  $param_str ||= "";
  my @curl_param_keys = keys(%{$curl_params});
  return $param_str if scalar @curl_param_keys == 0;

  my $param_key   = $curl_param_keys[0];
  my $param_value = delete $curl_params->{$param_key};

  $param_str .= " " . $param_value if $param_key eq 'METHOD';
  $param_str .= " " . sprintf $param_value, $args->{$param_key} if $args->{$param_key};

  return curl_params($args, $curl_params, $param_str);
}

sub queue_endpoint {
  my $args = shift;
  return (scalar @{$args->{'argv'}} == 0) ? 'q' : 'q/' . $args->{'argv'}[0];
}

1;