#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use ASP4::API;

my $api; BEGIN { $api = ASP4::API->new }

ok( my $res = $api->ua->get('/everything/step01.asp'), "Got res");

ok(
  $res = $api->ua->get('/handlers/dev.headers'), "Got headers res again"
);
is(
  $res->header('content-type') => 'text/x-test'
);
is(
  $res->header('content-length') => 3000
);
is(
  $res->content => "X"x3000
);


