
package ASP4::Request;

use strict;
use warnings 'all';


sub new
{
  my ($class, %args) = @_;
  
  return bless {
    %args,
    form  => scalar( $class->context->cgi->Vars ),
  }, $class;
}# end new()


sub context { ASP4::HTTPContext->current }
sub Form { shift->{form} }
sub Cookies { 
  my ($s, $name) = @_;
  $name ? $s->context->cgi->cookie( $name ) : $s->context->cgi->cookie;
}
sub QueryString { shift->context->cgi->query_string() }
sub ServerVariables { $ENV{ $_[1] } }


sub FileUpload
{
  my ($s, $field) = @_;
  
  my $ifh = $s->context->cgi->upload($field)
    or return;
  my %info = ( );
  
  if( my $upInfo = eval { $s->context->cgi->uploadInfo( $ifh ) } )
  {
    no warnings 'uninitialized';
    %info = (
      ContentType         => $upInfo->{'Content-Type'},
      FileHandle          => $ifh,
      FileName            => $s->{form}->{ $field } . "",
      ContentDisposition  => $upInfo->{'Content-Disposition'},
    );
  }
  else
  {
    no warnings 'uninitialized';
    %info = (
      ContentType         => $s->context->cgi->{uploads}->{ $field }->{headers}->{'Content-Type'},
      FileHandle          => $ifh,
      FileName            => $s->context->cgi->{uploads}->{ $field }->{filename},
      ContentDisposition  => 'attachment',
    );
  }# end if()
  
  require ASP4::FileUpload;
  return ASP4::FileUpload->new( %info );
}# end FileUpload()


sub DESTROY
{
  my $s = shift;
  undef(%$s);
}# end DESTROY()

1;# return true:

