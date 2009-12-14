
package ASP4::ConfigFinder;

use strict;
use warnings 'all';
use Cwd 'cwd';

our $CONFIGFILE = 'asp4-config.json';


sub config_path
{
  my $path = $CONFIGFILE;
  
  my $root = $ENV{DOCUMENT_ROOT} || cwd();
  
  # Try test dir:
  if( -f "$root/t/conf/$CONFIGFILE" )
  {
    return "$root/t/conf/$CONFIGFILE";
  }# end if()
  
  # Start moving up:
  for( 1...10 )
  {
    my $path = "$root/conf/$CONFIGFILE";
    return $path if -f $path;
    $root =~ s/\/[^\/]+$//
      or last;
  }# end for()
  
  die "CANNOT FIND '$CONFIGFILE' anywhere under '$root'";
}# end config_path()

1;# return true:

