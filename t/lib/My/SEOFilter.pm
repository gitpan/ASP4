
package My::SEOFilter;

use strict;
use warnings 'all';
use base 'ASP4::RequestFilter';
use vars __PACKAGE__->VARS;

sub run
{
  my ($s, $context) = @_;
  
  my ($id) = $ENV{REQUEST_URI} =~ m{/seo/(\d+)/};
  
  return $Request->Reroute("/seo-page/?id=$id");
}# end run()

1;# return true:

