
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

=pod

=head1 NAME

ASP4::Mock::ClientSocket - Mimics APR::Socket object

=head1 SYNOPSIS

  my $socket = $r->connection->client_socket

=head1 DESCRIPTION

Mimics (minimally) the L<APR::Socket> object.

=head1 PUBLIC METHODS

=head2 close( )

Internal use only.

=cut

