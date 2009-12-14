
package ASP4::OutBuffer;

use strict;
use warnings 'all';


sub new {
  return bless { data => '' }, shift;
}

sub add {
  my ($s, $str) = @_;
  return unless defined($str);
  $s->{data} .= $str;
  return;
}
sub data { shift->{data} }
sub clear {shift->{data} = '' }

sub DESTROY {
  my $s = shift;
  delete($s->{data});
  undef(%$s);
}

1;# return true:

