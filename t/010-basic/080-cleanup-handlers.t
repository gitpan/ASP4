#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use ASP4::API;

ok( my $api = ASP4::API->new, 'got api' );

ok( $api->ua->get('/') );

my $cleanup_called = 0;
ok(
  $api->context->server->RegisterCleanup(sub {
    my $args = shift;
    $cleanup_called = 1;
    is( $args->[0] => 'the arg', "The arg is correct" );
  }, 'the arg')
);
ok( $api->ua->get('/') );

ok( $cleanup_called, "Cleanup handler was called" );


