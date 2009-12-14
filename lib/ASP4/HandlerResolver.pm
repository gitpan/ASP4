
package ASP4::HandlerResolver;

use strict;
use warnings 'all';
use ASP4::PageLoader;
use File::stat;
my %HandlerCache = ( );
my %FileTimes = ( );


sub new
{
  my ($class, %args) = @_;
  
  return bless \%args, $class;
}# end new()


sub context { ASP4::HTTPContext->current }


sub resolve_request_handler
{
  my ($s, $uri) = @_;
  
  ($uri) = split /\?/, $uri;
  $s->check_reload( $uri );
  return $HandlerCache{$uri} if $HandlerCache{$uri};
  
  if( $uri =~ m/^\/handlers\// )
  {
    (my $handler = $uri) =~ s/^\/handlers\///;
    $handler =~ s/[^a-z0-9_]/::/gi;
    (my $path = "$handler.pm") =~ s/::/\//g;
    my $filepath = $s->context->config->web->handler_root . "/$path";
    
    if( -f $filepath )
    {
      $s->context->config->load_class( $handler );
      return $HandlerCache{$uri} = $handler;
    }
    else
    {
      return;
    }# end if()
  }
  else
  {
    my $info = ASP4::PageLoader->discover( script_name => $uri );
    if( -f $info->{filename} )
    {
      my $page = ASP4::PageLoader->load( script_name => $uri );
      return $HandlerCache{$uri} = $page->package;
    }
    else
    {
      return;
    }# end if()
  }# end if()
}# end resolve_request_handler()


sub check_reload
{
  my ($s, $uri) = @_;

  if( $uri =~ m/^\/handlers\// )
  {
    (my $handler = $uri) =~ s/^\/handlers\///;
    $handler =~ s/[^a-z0-9_]/::/gi;
    (my $path = "$handler.pm") =~ s/::/\//g;
    my $filepath = $s->context->config->web->handler_root . "/$path";
    (my $inc_entry = "$handler.pm") =~ s/::/\//g;
    return unless -f $filepath;
    
    if( stat($filepath)->mtime > ($FileTimes{ $filepath } || 0) )
    {
      $FileTimes{ $filepath } = stat($filepath)->mtime;
      $s->_forget_package(
        $inc_entry, $handler
      );
      delete( $HandlerCache{$uri} );
    }# end if()
  }
  else
  {
    my $info = ASP4::PageLoader->discover( script_name => $uri );
    return unless -f $info->{saved_to};
    $FileTimes{ $info->{filename} } ||= 0;
    if( stat($info->{filename})->mtime > ( $FileTimes{ $info->{filename} } || stat($info->{saved_to})->mtime ) )
    {
      $s->_forget_package(
        $info->{compiled_as}, $info->{package}
      );
      delete( $HandlerCache{$uri} );
    }# end if()
  }# end if()
}# end check_reload()


sub _forget_package
{
  my ($s, $inc, $package) = @_;
  
  # Forcibly forget all about the handler we are going to reload:
  no strict 'refs';
  delete( $INC{ $inc } );
  if( *{"$package\::run"} )
  {
    no warnings;
    *{"$package\::run"} = undef;
    *{"$package\::before_run"} = undef;
    *{"$package\::after_run"} = undef;
  }# end if()
}# end _forget_package()

1;# return true:
