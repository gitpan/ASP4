
package ASP4::API;

use strict;
use warnings 'all';
use ASP4::ConfigLoader;
use ASP4::HTTPContext;
use ASP4::UserAgent;
use Data::Properties::YAML;
use ASP4::Test::Fixtures;

sub new
{
  my ($class) = @_;;
  
  my $config = ASP4::ConfigLoader->load;
  # Our test fixtures:
  my $data = ASP4::Test::Fixtures->new(
    properties_file => $config->web->application_root . '/etc/test_fixtures.yaml'
  ) if -f $config->web->application_root . '/etc/test_fixtures.yaml';
  
  # Our diagnostic messages:
  my $properties = Data::Properties::YAML->new(
    properties_file => $config->web->application_root . '/etc/properties.yaml'
  ) if -f $config->web->application_root . '/etc/properties.yaml';
  
  return bless {
    data        => $data,
    properties  => $properties,
    ua          => ASP4::UserAgent->new()
  }, $class;
}# end new()


sub data { shift->{data} }
sub properties { shift->{properties} }
sub ua { shift->{ua} }
sub context { ASP4::HTTPContext->current }
sub config { ASP4::ConfigLoader->load }


sub DESTROY
{
  my $s = shift;
  undef(%$s);
}# end DESTROY()

1;# return true:

