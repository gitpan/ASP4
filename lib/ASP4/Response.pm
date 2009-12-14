
package ASP4::Response;

use strict;
use warnings 'all';
use HTTP::Date qw( time2str );
use ASP4::HTTPContext;
use ASP4::Mock::RequestRec;


sub new
{
  my $s = bless {
    _status           => 200,
    _expires          => 0,
    _content_type     => 'text/html',
    _expires_absolute => time2str( time() ),
  }, shift;
  $s->Status( $s->Status );
  $s->Expires( $s->Expires );
  $s->ContentType( $s->ContentType );
  
  return $s;
}# end new()

sub context { ASP4::HTTPContext->current }


sub ContentType
{
  my $s = shift;
  
  if( @_ )
  {
    my $type = shift;
    $s->{_content_type} = $type;
    $s->context->r->content_type( $type );
  }
  else
  {
    return $s->{_content_type};
  }# end if()
}# end ContentType()


sub Expires
{
  my $s = shift;
  if( @_ )
  {
    $s->{_expires} = shift;
    $s->{_expires_absolute} = time2str( time() + ( $s->{_expires} * 60 ) );
    $s->AddHeader( expires  => $s->ExpiresAbsolute );
  }# end if()
  
  return $s->{_expires};
}# end Expires()


sub ExpiresAbsolute { shift->{_expires_absolute} }


sub Status
{
  my $s = shift;
  
  @_ ? $s->context->r->status( $s->{_status} = +shift ) : $s->{_status};
}# end Status()


sub End
{
  my $s = shift;
  $s->Flush;
  
  # Would be nice to somehow stop all execution:
  $s->context->did_end( 1 );
}# end End()


sub Flush
{
  my $s = shift;
  $s->context->rflush;
}# end Flush()


sub Clear
{
  shift->context->rclear
}# end Clear()


sub IsClientConnected
{
  ! shift->context->r->connection->aborted();
}# end IsClientConnected()


sub Write
{
  my $s = shift;
  $s->context->rprint( shift(@_) )
}# end Write()


sub SetCookie
{
  my ($s, %args) = @_;
  
  $args{domain} ||= $ENV{HTTP_HOST};
  $args{path}   ||= '/';
  my @parts = ( );
  push @parts, $s->context->server->URLEncode($args{name}) . '=' . $s->context->server->URLEncode($args{value});
  push @parts, 'domain=' . $s->context->server->URLEncode($args{domain});
  push @parts, 'path=' . $args{path};
  if( $args{expires} )
  {
    push @parts, 'expires=' . $args{expires};
  }# end if()
  $s->AddHeader( 'Set-Cookie' => join('; ', @parts) . ';' );
}# end SetCookie()


sub AddHeader
{
  my ($s, $name, $value) = @_;
  
  $s->context->headers_out->header( $name => $value );
}# end AddHeader()


sub Headers
{
  my $s = shift;
  
  my $out = $s->context->headers_out;
  map {{
    $_ => $out->{$_}
  }} keys %$out;
}# end Headers()


sub Redirect
{
  my ($s, $url) = @_;
  
  return if $s->context->did_send_headers;
  
  $s->Clear;
  $s->Status( 301 );
  $s->AddHeader( Location => $url );
  $s->End;
}# end Redirect()


sub Declined { -1 }


sub Include
{
  my ($s, $file, $args) = @_;
  
  $s->Write( $s->_subrequest( $file, $args ) );
}# end Include()


sub TrapInclude
{
  my ($s, $file, $args) = @_;
  
  return $s->_subrequest( $file, $args );
}# end TrapInclude()


sub _subrequest
{
  my ($s, $file, $args) = @_;
  
  $s->context->add_buffer();
  my $original_r = $s->context->r;
  my $root = $s->context->config->web->www_root;
  (my $uri = $file) =~ s/^\Q$root\E//;
  my $r = ASP4::Mock::RequestRec->new(
    uri   => $uri,
    args  => $original_r->args,
  );
  local $ENV{SCRIPT_NAME} = $uri;
  local $ENV{REQUEST_URI} = $uri;
  local $ENV{SCRIPT_FILENAME} = $file;
  $s->context->setup_request( $r, $s->context->cgi );
  $s->context->execute( $args, 1 );
  $s->Flush;
  my $buffer = $s->context->purge_buffer();
  $s->context->{r} = $original_r;
  return $r->buffer;
}# end _subrequest()


sub DESTROY
{
  my $s = shift;
  undef(%$s);
}# end DESTROY()

1;# return true:

