
package ASP4::Server;

use strict;
use warnings 'all';
use ASP4::HTTPContext;
use encoding 'utf8';
use Mail::Sendmail;

sub new
{
  return bless { }, shift;
}# end new()


sub context { ASP4::HTTPContext->current }


sub URLEncode
{
  ASP4::HTTPContext->current->cgi->escape( $_[1] );
}# end URLEncode()


sub URLDecode
{
  ASP4::HTTPContext->current->cgi->unescape( $_[1] );
}# end URLDecode()


sub HTMLEncode
{
  my ($s, $str) = @_;
  no warnings 'uninitialized';
  $str =~ s/&/&amp;/g;
  $str =~ s/</&lt;/g;
  $str =~ s/>/&gt;/g;
  $str =~ s/"/&quot;/g;
  $str =~ s/'/&#39;/g;
  return $str;
}# end HTMLEncode()


sub HTMLDecode
{
  my ($s, $str) = @_;
  no warnings 'uninitialized';
  $str =~ s/&lt;/</g;
  $str =~ s/&gt;/>/g;
  $str =~ s/&quot;/"/g;
  $str =~ s/&amp;/&/g;
  return $str;
}# end HTMLDecode()


sub MapPath
{
  my ($s, $path) = @_;
  
  return unless defined($path);
  
  ASP4::HTTPContext->current->config->web->www_root . $path;
}# end MapPath()


sub Mail
{
  my $s = shift;
  
  Mail::Sendmail::sendmail( @_ );
}# end Mail()


sub RegisterCleanup
{
  my ($s, $sub, @args) = @_;
  
  $s->context->r->pool->cleanup_register( $sub, \@args );
}# end RegisterCleanup()


1;# return true:

