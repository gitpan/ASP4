
package ASP4::Mock::ClientSocket;

use strict;
use warnings 'all';

sub new {
  return bless {
    on_close  => sub { },
  }, shift;
}

sub on_close { my $s = shift; $s->{on_close} = shift }
sub close { shift->{on_close}->( ) }

1;# return true:

