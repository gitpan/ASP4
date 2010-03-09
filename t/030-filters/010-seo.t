#!/usr/bin/perl -w

use strict;
use warnings 'all';
use ASP4::API;
use Test::More tests => 3;
my $api; BEGIN { $api = ASP4::API->new }

ok( $api, "Got api");

my $res = $api->ua->get("/seo/123/");

ok( $res->is_success, "request is successful" );

ok(1, "Got something");



