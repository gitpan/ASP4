
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

1;# return true:

