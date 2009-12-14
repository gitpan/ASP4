
package ASP4::Mock::RequestRec;

use strict;
use warnings 'all';
use ASP4::Mock::Pool;
use ASP4::Mock::Connection;
use ASP4::ConfigLoader;
use Scalar::Util 'weaken';


sub new
{
  my ($class, %args) = @_;
  
  my $s = bless {
    status  => 200,
    content_type  => 'text/plain',
    buffer        => '',
    document_root => ASP4::ConfigLoader->load()->web->www_root,
    headers_in  => { },
    headers_out => { },
    uri     => $args{uri} || $ENV{REQUEST_URI},
    args    => $args{args} || $ENV{QUERY_STRING},
    pnotes  => { },
    method  => $args{method},
    pool    => ASP4::Mock::Pool->new(),
    connection  => ASP4::Mock::Connection->new(),
  }, $class;
  weaken($s->{connection});
  $s->{err_headers_out} = $s->{headers_out};
  
  $s->{filename} = $s->document_root . $s->uri;
  
  return $s;
}# end new()


# Public read-write properties:
sub pnotes
{
  my $s = shift;
  my $name = shift;
   @_ ? $s->{pnotes}->{$name} = shift : $s->{pnotes}->{$name};
}# end pnotes()

sub uri
{
  my $s = shift;
  @_ ? $s->{uri} = shift : $s->{uri};
}# end uri()

sub args
{
  my $s = shift;
  @_ ? $s->{args} = shift : $s->{args};
}# end args()


# Public read-only properties:
sub document_root   { shift->{document_root} }
sub method          { shift->{method} }
sub pool            { shift->{pool} }
sub connection      { shift->{connection} }
sub filename        { shift->{filename} }
sub buffer          { shift->{buffer} }
sub headers_out     { shift->{headers_out} }
sub err_headers_out { shift->{err_headers_out} }


# Public methods:
sub print { my ($s,$str) = @_; $s->{buffer} .= $str; }
sub status { my $s = shift; @_ ? $s->{status} = +shift : $s->{status} }
sub content_type { my $s = shift; @_ ? $s->{content_type} = +shift : $s->{content_type} }

sub rflush { }

sub clone
{
  my $s = shift;
  return bless { %$s }, ref($s);
}# end clone()

1;# return true:

