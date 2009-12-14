
package ASP4::Mock::Connection;

use strict;
use warnings 'all';
use ASP4::Mock::ClientSocket;

sub new {
  my $s = bless {
    aborted => 0,
    client_socket  => ASP4::Mock::ClientSocket->new()
  }, shift;
  $s->{client_socket}->on_close(sub {
    $s->{aborted} = 0;
  });
  
  return $s;
}

sub aborted { shift->{aborted} }
sub client_socket { shift->{client_socket} }

1;# return true:

=pod

=head1 NAME

ASP4::Mock::Connection - Mimic the Apache2::Connection object

=head1 SYNOPSIS

  my $connection = $r->connection;
  
  if( $connection->aborted ) {
    # The connection has been closed:
  }
  
  my $socket = $connection->client_socket;

=head1 DESCRIPTION

Minimal mimic of the L<Apache2::Connection> object.

=head1 PUBLIC PROPERTIES

=head2 aborted( )

Returns true or false, if the current connection has been aborted or not - respectively.

=head2 client_socket( )

Returns an instance of L<ASP4::Mock::ClientSocket>.

=cut

