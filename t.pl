#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use Time::HiRes 'gettimeofday';
use ASP4::API;
use HTTP::Request::Common;
use ASP4::SimpleCGI;
my $api; BEGIN { $api = ASP4::API->new }

#$api->ua->get('/');
ok(1);

my $r = ASP4::Mock::RequestRec->new( uri => '/handlers/dev.speed', args => '' );
my $req = GET '/handlers/dev.speed';
my $env = { %ENV };
%ENV = (
  %$env,
  HTTP_HOST       => 'localhost',
  HTTP_REFERER    => '',
  DOCUMENT_ROOT   => $api->config->web->www_root,
  REQUEST_METHOD  => 'GET',
  CONTENT_TYPE    => 'application/x-www-form-urlencoded',
  HTTP_COOKIE     => '',
  REQUEST_URI     => '/handlers/dev.speed',
);
my $cgi = _setup_cgi( $req );

{
  my $sub = sub {
    $api->ua->get('/handlers/dev.speed');
#    ASP4::HTTPContext->new->setup_request( $r, $cgi )->execute();
  };
  my ($time, $persec) = bench($sub, 1000);
  warn "\nRan handler 1000 times in $time seconds ($persec/second)\n";
}


sub bench {
  my ($sub, $times) = @_;
  my $start = gettimeofday();
  for( 1..$times ) {
    $sub->();
  }
  
  my $diff = gettimeofday() - $start;
  my $persec = $times / $diff;
  return ($diff, $persec);
}

sub _setup_cgi
{
  my ($req) = @_;


  $req->referer('');
  
  no warnings 'uninitialized';
  (my ($uri_no_args), $ENV{QUERY_STRING} ) = split /\?/, $req->uri;
  $ENV{SERVER_NAME} = $ENV{HTTP_HOST} = 'localhost';
  
  unless( $req->uri =~ m@^/handlers@ )
  {
    $ENV{SCRIPT_FILENAME} = $api->config->web->www_root . $uri_no_args;
    $ENV{SCRIPT_NAME} = $uri_no_args;
  }# end unless()
  
  # User-Agent:
  $req->header( 'User-Agent' => 'test-useragent v1.0' );
#  $req->header( 'Cookie' => $ENV{HTTP_COOKIE} );
  $ENV{HTTP_USER_AGENT} = 'test-useragent v2.0';
  
  # Simple 'GET' request:
  return ASP4::SimpleCGI->new( querystring => $ENV{QUERY_STRING} );
}# end _setup_cgi()

