
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
  my $test_data = ASP4::Test::Fixtures->new(
    properties_file => $config->web->application_root . '/etc/test_fixtures.yaml'
  ) if -f $config->web->application_root . '/etc/test_fixtures.yaml';
  
  # Our diagnostic messages:
  my $properties = Data::Properties::YAML->new(
    properties_file => $config->web->application_root . '/etc/properties.yaml'
  ) if -f $config->web->application_root . '/etc/properties.yaml';
  
  return bless {
    test_data   => $test_data,
    properties  => $properties,
    ua          => ASP4::UserAgent->new(),
    config      => $config,
  }, $class;
}# end new()

*init = \&new;

sub test_data   { shift->{test_data} }
sub properties  { shift->{properties} }
sub ua          { shift->{ua} }
sub context     { ASP4::HTTPContext->current }
sub config      { shift->{config} }
sub data        { shift->test_data }    # Deprecated! - for Apache2::ASP compat only.


sub DESTROY
{
  my $s = shift;
  undef(%$s);
}# end DESTROY()

1;# return true:

=pod

=head1 NAME

ASP4::API - Public Programmatic API to an ASP4 Application

=head1 SYNOPSIS

  #!/usr/bin/perl -w
  
  use strict;
  use warnings 'all';
  
  # Load up and initialize ASP4::API *before* using your app's classes:
  use ASP4::API;
  my $api; BEGIN { $api = ASP4::API->new }
  
  # - or -
  my $api; BEGIN { $api = ASP4::API->init }
  
  # Now you can use your app's other classes:
  use app::user;
  use app::product;
  use app::order;
  
  # Use the API:
  
  my $res = $api->ua->get('/index.asp');
  if( $res->is_success ) {
    print $res->content;
  }
  
  # Access your test data:
  warn $res->test_data->contact_form->email;
  
  # Access your properties YAML:
  warn $res->properties->contact_form->email->is_missing;
  
  # Access the application config:
  warn $api->config->system->settings->foo;

=head1 DESCRIPTION

C<ASP4::API> is B<very useful for unit tests> - specifically when writing tests
for the actual web pages themselves.

=head2 Example Unit Test

  #!/usr/bin/perl -w
  
  use strict;
  use warnings 'all';
  use Test::More 'no_plan';
  
  use ASP4::API;
  my $api; BEGIN { $api = ASP4::API->new }
  
  ok(
    $api, "Got api"
  );
  is(
    $api->ua->get('/hello.asp')->content => 'Hello World!',
    'Website is friendly'
  );

=head1 CONSTRUCTOR

=head2 new( )

Takes no arguments.  Finds and initializes your application's configuration, which
means that any other part of your application which requires the configuration
to have been loaded up will now work.

=head2 init( )

C<init()> is simply an alias of C<new()>

=head1 PUBLIC PROPERTIES

=head2 ua

Returns an L<ASP4::UserAgent> that can be used to interact with pages on your website.

=head2 context

Returns the current instance of L<ASP4::HTTPContext> in use.

=head2 config

Returns the L<ASP4::Config> object for the web application.

=head2 properties

Returns an object representing your C</etc/properties.yaml> file.

=head2 data

Returns an object representing your C</etc/test_fixtures.yaml> file.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ASP4> to submit bug reports.

=head1 HOMEPAGE

Please visit the ASP4 homepage at L<http://0x31337.org/code/> to see examples
of ASP4 in action.

=cut

