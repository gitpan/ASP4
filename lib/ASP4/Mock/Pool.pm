
package ASP4::Mock::Pool;

use strict;
use warnings 'all';

sub new { return bless { cleanup_handlers => [ ] }, shift }
sub call_cleanup_handlers {
  my $s = shift;
  map { $_->( ) } @{ $s->{cleanup_handlers} }
}
sub cleanup_register {
  my ($s, $handler, $args) = @_;
  
  push @{ $s->{cleanup_handlers} }, sub { $handler->( $args ) };
}

sub DESTROY
{
  my $s = shift;
  $s->call_cleanup_handlers();
  undef(%$s);
}# end DESTROY()

1;# return true:

