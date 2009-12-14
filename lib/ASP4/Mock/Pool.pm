
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

=pod

=head1 NAME

ASP4::Mock::Pool - Mimics the $r->pool APR::Pool object

=head1 SYNOPSIS

  my $pool = $r->pool;
  $pool->cleanup_register( sub { ... }, \@args );

=head1 DESCRIPTION

This package mimics the L<APR::Pool> object obtained via $r->pool in a normal mod_perl2 environment.

=head1 PUBLIC METHODS

=head2 cleanup_register( sub { ... }, \@args )

Causes the subref to be executed with C<\@args> at the end of the current request.

=cut
