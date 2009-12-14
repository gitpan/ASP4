
package ASP4::HTTPHandler;

use strict;
use warnings 'all';
use Data::Properties::YAML;

BEGIN {
  sub VARS {
    qw(
      $Request      $Response
      $Session      $Server
      $Config       $Form
      $Stash
    )
  }
  use vars __PACKAGE__->VARS;
}


sub new {
  my ($class, %args) = @_;
  return bless \%args, $class;
}


sub before_run { 1; }
sub after_run  { }


sub init_asp_objects
{
  my ($s, $context) = @_;
  
  $Request  = $context->request;
  $Response = $context->response;
  $Session  = $context->session;
  $Server   = $context->server;
  $Form     = $context->request->Form;
  $Config   = $context->config;
  $Stash    = $context->stash;
  
  my $class = ref($s) ? ref($s) : $s;
  my @classes = $s->_parents( $class );
  no strict 'refs';
  my %saw = ( );
  map {
    ${"$_\::Request"}   = $Request;
    ${"$_\::Response"}  = $Response;
    ${"$_\::Session"}   = $Session;
    ${"$_\::Server"}    = $Server;
    ${"$_\::Form"}      = $Form;
    ${"$_\::Config"}    = $Config;
    ${"$_\::Stash"}     = $Stash;
  } grep { ! $saw{$_}++ } @classes;
  
  return 1;
}# end init_asp_objects()


sub properties
{
  my ($s, $file) = @_;
  
  $file ||= $Config->web->application_root . '/etc/properties.yaml';
  return Data::Properties::YAML->new( properties_file => $file );
}# end properties()

sub trim_form
{
  no warnings 'uninitialized';
  
  map {
    $Form->{$_} =~ s/^\s+//;
    $Form->{$_} =~ s/\s+$//;
  } keys %$Form;
}# end trim()


sub _parents
{
  my ($s, $class ) = @_;
  
  my @classes = ( $class );
  no strict 'refs';
  my $pkg = __PACKAGE__;
  push @classes, map { $s->_parents( $_ ) }
                   grep { $_->isa($pkg) }
                     @{"$class\::ISA"};
  
  return @classes;
}# end _parents()


sub DESTROY
{
  my $s = shift;
  undef(%$s);
}# end DESTROY()

1;# return true:
