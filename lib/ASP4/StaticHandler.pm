
package
ASP4::StaticHandler;

use strict;
use warnings 'all';
use base 'ASP4::FormHandler';
use vars __PACKAGE__->VARS;

sub run
{
  my ($s, $context) = @_;
  
  my ($uri) = split /\?/, $ENV{REQUEST_URI};
  my $file = $Server->MapPath( $uri );
  unless( -f $file )
  {
    $Response->Status( 404 );
    $Response->End;
    return 404;
  }# end unless()
  open my $ifh, '<', $file
    or die "Cannot open '$file' for reading: $!";
  local $/;
  $Response->SetHeader('content-length' => (stat($file))[7] );
  
  my ($ext) = $file =~ m{\.([^\.]+)$};
  my %types = (
    swf => 'application/x-shockwave-flash',
    xml => 'text/xml'
  );
  my $type = $types{lc($ext)} || 'application/octet-stream';
  $Response->ContentType( $type );
  
  my ($filename) = $file =~ m{([^/]+)$};
  my $disp = lc($type) eq 'pdf' ? 'attachment' : 'inline';
  $Response->SetHeader('content-disposition' => qq($disp; filename="$filename"; yay=yay;));
  $Response->Write( scalar(<$ifh>) );
  close($ifh);
}# end run()

1;# return true:

