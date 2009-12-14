use strict;
use warnings;
use inc::Module::Install;
use 5.008005;

name 'ASP4';
perl_version '5.008005';
license 'perl';
all_from 'lib/ASP4.pm';

test_requires 'Test::More'          => 0;
test_requires 'Test::Memory::Cycle' => 0;
test_requires 'DBD::SQLite'         => 0;
test_requires 'Time::HiRes'         => 0;
test_requires 'HTML::Form'          => 0;

requires    'Data::Properties::YAML'  => 0;
requires    'Cwd'                     => 0;
requires    'Digest::MD5'             => 0;       # Session state.
requires    'DBI'                     => 0;       # Session state.
requires    'Storable'                => 2.18;    # Session state.
requires    'HTTP::Date'              => 0;       # For Session timeouts.
requires    'MIME::Types'             => 0;       # For MediaManager.
requires    'Mail::Sendmail'          => 0;       # For sending email.
requires    'CGI'                     => 3.43;    # For...cgi stuff...
requires    'HTTP::Body'              => 0;
requires    'Ima::DBI'                => 0.35;    # For session state.
requires    'JSON::XS'                => 0;       # For Configs

install_script 'sbin/asp4';
install_script 'sbin/asphelper';

tests_recursive();
WriteAll();
