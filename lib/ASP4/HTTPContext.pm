
package ASP4::HTTPContext;

use strict;
use warnings 'all';
use HTTP::Date ();
use HTTP::Headers ();
use ASP4::ConfigLoader;
use ASP4::Request;
use ASP4::Response;
use ASP4::Server;
use ASP4::OutBuffer;
use ASP4::SessionStateManager::NonPersisted;

use vars '$_instance';

sub new
{
  my ($class) = @_;
  
  my $s = bless {
    config => ASP4::ConfigLoader->load,
    buffer => [ ASP4::OutBuffer->new ],
    stash  => { },
    headers_out => HTTP::Headers->new(),
  }, $class;
  $s->config->_init_inc();
  
  $s->config->load_class( $s->config->web->handler_resolver );
  $s->config->load_class( $s->config->web->handler_runner );
  $s->config->load_class( $s->{config}->data_connections->session->manager );
  $s->config->load_class( $s->config->web->filter_resolver );
  
  return $s;
}# end new()


sub setup_request
{
  my ($s, $r, $cgi) = @_;
  
  $s->{r} = $r;
  $s->{cgi} = $cgi;
  
  # Must instantiate $_instance before creating the other objects:
  $_instance = $s;
  $s->{request}   ||= ASP4::Request->new();
  $s->{response}  ||= ASP4::Response->new();
  $s->{server}    ||= ASP4::Server->new();
  
  my $do_session_onstart;
  if( $s->do_disable_session_state )
  {
    $s->{session} ||= ASP4::SessionStateManager::NonPersisted->new( $s->r );
  }
  else
  {
    $s->{session}   ||= $s->config->data_connections->session->manager->new( $s->r );
    $do_session_onstart++;
  }# end if()
  
  $s->{global_asa} = $s->resolve_global_asa_class( );
  {
    no warnings 'uninitialized';
    $s->{global_asa}->init_asp_objects( $s );
    if( $do_session_onstart )
    {
      unless( $s->session->{__started} )
      {
        $s->handle_phase( $s->global_asa->can('Session_OnStart') );
        $s->session->{__started} = 1;
      }# end unless()
    }# end if()
  }
  
  eval {
    $s->{handler} = $s->config->web->handler_resolver->new()->resolve_request_handler( $r->uri );
  };
  if( $@ )
  {
    $s->server->{LastError} = $@;
    return $s->handle_error;
  }# end if()
  
  return $_instance;
}# end setup_request()


# Intrinsics:
sub current   { $_instance || shift->new }
sub request   { shift->{request} }
sub response  { shift->{response} }
sub server    { shift->{server} }
sub session   { shift->{session} }
sub config    { shift->{config} }
sub stash     { shift->{stash} }

# More advanced:
sub cgi         { shift->{cgi} }
sub r           { shift->{r} }
sub global_asa  { shift->{global_asa} }
sub handler     { shift->{handler} }
sub headers_out { shift->{headers_out} }
sub content_type  { my $s = shift; $s->r->content_type( @_ ) }
sub status        { my $s = shift; $s->r->status( @_ ) }
sub did_send_headers  { shift->{did_send_headers} }
sub did_end {
  my $s = shift;
  @_ ? $s->{did_end} = shift : $s->{did_end};
}

sub rprint {
  my ($s,$str) = @_;
  $s->buffer->add( $str )
}

sub rflush {
  my $s = shift;
  $s->send_headers;
  $s->r->print( $s->buffer->data );
  $s->r->rflush;
  $s->rclear;
}

sub rclear {
  my $s = shift;
  $s->buffer->clear;
}

sub send_headers
{
  my $s = shift;
  return if $s->{did_send_headers};
  
  my $headers = $s->headers_out;
  while( my ($k,$v) = each(%$headers) )
  {
    $s->r->err_headers_out->{$k} = $v;
  }# end while()

  $s->r->rflush;
  $s->{did_send_headers} = 1;
}# end send_headers()

# Here be dragons:
sub buffer        { shift->{buffer}->[-1] }
sub add_buffer    {
  my $s = shift;
  $s->rflush;
  push @{$s->{buffer}}, ASP4::OutBuffer->new;
}
sub purge_buffer  { shift( @{shift->{buffer}} ) }


sub execute
{
  my ($s, $args, $is_include) = @_;
  
  return $s->response->Status( 404 ) unless $s->{handler};

  unless( $is_include )
  {
    # Set up and execute any matching request filters:
    my $resolver = $s->config->web->filter_resolver;
    foreach my $filter ( $resolver->new()->resolve_request_filters( $s->r->uri ) )
    {
      $s->config->load_class( $filter->class );
      $filter->class->init_asp_objects( $s );
      my $res = $s->handle_phase(sub{ $filter->class->new()->run( $s ) });
      if( defined($res) && $res != -1 )
      {
        return $res;
      }# end if()
    }# end foreach()
    
    my $start_res = $s->handle_phase( $s->global_asa->can('Script_OnStart') );
    return $start_res if defined( $start_res );
  }# end unless()
  
  eval {
    $s->config->load_class( $s->handler );
    $s->config->web->handler_runner->new()->run_handler( $s->handler, $args );
  };
  if( $@ )
  {
    $s->server->{LastError} = $@;
    return $s->handle_error;
  }# end if()
  
  $s->response->Flush;
  my $res = $s->end_request();
  
  $res = 0 if $res =~ m/^200/;
  return $res;
}# end execute()


sub handle_phase
{
  my ($s, $ref) = @_;
  
  eval { $ref->( ) };
  if( $@ )
  {
    $s->handle_error;
  }# end if()
  
  # Undef on success:
  return $s->response->Status =~ m/^200/ ? undef : $s->response->Status;
}# end handle_phase()


sub handle_error
{
  my $s = shift;
  
  my $error = "$@";
  $s->response->Status( 500 );
  no strict 'refs';

  $s->response->Clear;
  my ($main, $title, $file, $line) = $error =~ m/^((.*?)\s(?:at|in)\s(.*?)\sline\s(\d+))/;
  $s->stash->{error} = {
    title       => $title,
    file        => $file,
    line        => $line,
    stacktrace  => $error,
  };
  warn "[Error: @{[ HTTP::Date::time2iso() ]}] $main\n";
  
  $s->config->load_class( $s->config->errors->error_handler );
  my $error_handler = $s->config->errors->error_handler->new();
  $error_handler->init_asp_objects( $s );
  eval { $error_handler->run( $s ) };
  confess $@ if $@;
  
  return $s->end_request;
}# end handle_error()


sub end_request
{
  my $s = shift;
  
  $s->handle_phase( $s->global_asa->can('Script_OnEnd') )
    unless $s->{did_end};
  
  $s->response->End;
  $s->session->save;
  my $res = $s->response->Status =~ m/^200/ ? 0 : $s->response->Status;
  
  return $res;
}# end end_request()


sub resolve_global_asa_class
{
  my $s = shift;
  
  my $file = $s->config->web->www_root . '/GlobalASA.pm';
  my $class;
  if( -f $file )
  {
    $class = $s->config->web->application_name . '::GlobalASA';
    eval { require $file };
    confess $@ if $@;
  }
  else
  {
    $class = 'ASP4::GlobalASA';
    $s->config->load_class( $class );
  }# end if()
  
  return $class;
}# end resolve_global_asa_class()


sub do_disable_session_state
{
  my ($s) = @_;
  
  my ($uri) = split /\?/, $s->r->uri;
  my ($yes) = grep { $_->disable_session } grep {
    if( my $pattern = $_->uri_match )
    {
      $uri =~ m/$pattern/
    }
    else
    {
      $uri eq $_->uri_equals;
    }# end if()
  } $s->config->web->disable_persistence;
  
  return $yes;
}# end do_disable_session_state()


sub DESTROY
{
  my $s = shift;
  undef(%$s);
}# end DESTROY()

1;# return true:

=pod

=head1 NAME

ASP4::HTTPContext - Provides access to the intrinsic objects for an HTTP request.

=head1 SYNOPSIS

  use ASP4::HTTPContext;
  
  my $context = ASP4::HTTPContext->current;
  
  # Intrinsics:
  my $request   = $context->request;
  my $response  = $context->response;
  my $session   = $context->session;
  my $server    = $context->server;
  my $config    = $context->config;
  my $stash     = $context->stash;
  
  # Advanced:
  my $cgi = $context->cgi;
  my $r = $context->r;

=head1 DESCRIPTION

The HTTPContext itself is the root of all request-processing in an ASP4 web application.

There is only one ASP4::HTTPContext instance throughout the lifetime of a request.

=head1 PROPERTIES

=head2 current

Returns the C<ASP4::HTTPContext> object in use for the current HTTP request.

=head2 request

Returns the L<ASP4::Request> for the HTTP request.

=head2 response

Returns the L<ASP4::Response> for the HTTP request.

=head2 server

Returns the L<ASP4::Server> for the HTTP request.

=head2 session

Returns the L<ASP4::SessionStateManager> for the HTTP request.

=head2 stash

Returns the current stash hash in use for the HTTP request.

=head2 config

Returns the current C<ASP4::Config> for the HTTP request.

=head2 cgi

Provided B<Just In Case> - returns the L<CGI> object for the HTTP request.

=head2 r

Provided B<Just In Case> - returns the L<Apache2::RequestRec> for the HTTP request.

B<NOTE:> Under L<ASP4::API> (eg: in a unit test) C<$r> will be an instance of L<ASP4::Mock::RequestRec> instead.

=cut
