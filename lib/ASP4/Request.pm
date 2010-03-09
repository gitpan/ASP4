
package ASP4::Request;

use strict;
use warnings 'all';


sub new
{
  my ($class, %args) = @_;
  
  my $cgi = $class->context->cgi;
  my $s = bless {
    %args,
    form  => {
      map {
        # CGI->Vars joins multi-value params with a null byte.  Which sucks.
        # To avoid that behavior, we do this instead:
        my @val = $cgi->param($_);
        $_ => scalar(@val) > 1 ? \@val : shift(@val)
      } $cgi->param
    },
  }, $class;
  
  return $s;
}# end new()


sub context { ASP4::HTTPContext->current }

# Not documented - for a reason (want to deprecate):
sub Form { shift->{form} }

# Not documented - for a reason (want to deprecate):
sub QueryString { shift->context->cgi->query_string() }

sub Cookies { 
  my ($s, $name) = @_;
  $name ? $s->context->cgi->cookie( $name ) : $s->context->cgi->cookie;
}

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


sub Reroute
{
  my ($s, $where) = @_;
  
  my ($uri, $querystring) = split /\?/, $where;
  $querystring ||= "";
  $s->context->r->uri( $uri );
  my $args = $s->context->r->args;
  $args .= $args ? "&$querystring" : $querystring;
  $s->context->r->args( $args );
  $ENV{QUERY_STRING} = $args;
  $ENV{REQUEST_URI} = $uri . ( length($args) ? "?$args" : "" );
  
  my $cgi = $s->context->cgi;
  my $Form = $s->context->request->Form;
  map {
    # CGI->Vars joins multi-value params with a null byte.  Which sucks.
    # To avoid that behavior, we do this instead:
    my @val = $cgi->param($_);
    $Form->{$_} = scalar(@val) > 1 ? \@val : shift(@val);
  } $cgi->param;
  
  ( my $path = $s->context->server->MapPath( $uri ) ) =~ s{/+$}{};
  $path .= "/index.asp" if -f "$path/index.asp";
  $ENV{SCRIPT_FILENAME} = $path;
  $ENV{SCRIPT_NAME} = $path;
  return $s->context->response->Declined;
}# end Reroute()


sub DESTROY
{
  my $s = shift;
  undef(%$s);
}# end DESTROY()

1;# return true:

=pod

=head1 NAME

ASP4::Request - Interface to the incoming request

=head1 SYNOPSIS

  if( my $cookie = $Request->Cookies('cust-email') ) {
    # Greet our returning user:
  }
  
  if( my $file = $Request->FileUpload('avatar_pic') ) {
    # Handle the uploaded file:
    $file->SaveAs( "/var/media/$Session->{user_id}/avatar/" . $file->FileName );
  }
  
  if( $Request->ServerVariables("HTTPS") ) {
    # We're under SSL:
  }

=head1 DESCRIPTION

The intrinsic C<$Request> object provides a few easy-to-use methods to simplify
the processing of incoming requests - specifically file uploads and cookies.

=head1 METHODS

=head2 Cookies( [$name] )

Returns a cookie by name, or all cookies if no name is provided.

=head2 ServerVariables( [$name] )

A wrapper around the global C<%ENV> variable.

This means that:

  $Request->ServerVariables('HTTP_HOST')

is the same as:

  $ENV{HTTP_HOST}

=head2 FileUpload( $fieldname )

Returns a L<ASP4::FileUpload> object that corresponds to the fieldname specified.

So...if your form has this:

  <input type="file" name="my_uploaded_file" />

Then you would get to it like this:

  my $upload = $Request->FileUpload('my_uploaded-file');

=cut

