
package ASP4::GlobalASA;

use strict;
use warnings 'all';
use base 'ASP4::HTTPHandler';
use vars __PACKAGE__->VARS;

sub Script_OnStart { }
sub Script_OnEnd { }
sub Session_OnStart { }

1;# return true:

=pod

=head1 NAME

ASP4::GlobalASA - For reverse compatibility only.

=head1 SYNOPSIS

B<DEPRECATED - DO NOT USE THIS IN NEW APPLICATIONS.>

  package MyApp::GlobalASA;

  use strict;
  use warnings 'all';
  use base 'ASP4::GlobalASA';
  use vars __PACKAGE__->VARS;

  sub Script_OnStart {
    warn "Script_OnStart!";
  }

  sub Script_OnEnd {
    warn "Script_OnEnd!";
  }

  sub Session_OnStart {
    warn "Session_OnStart!";
  }

  1;# return true:

=head1 DESCRIPTION

B<DEPRECATED - DO NOT USE THIS IN NEW APPLICATIONS.>

The GlobalASA handles 3 kinds of events:

=head2 Script_OnStart

B<DEPRECATED - DO NOT USE THIS IN NEW APPLICATIONS.>

Called after all objects have been initialized, but before the request is processed by its handler (or page).

=head2 Script_OnEnd

B<DEPRECATED - DO NOT USE THIS IN NEW APPLICATIONS.>

Called at the end of a request.

=head2 Session_OnStart

B<DEPRECATED - DO NOT USE THIS IN NEW APPLICATIONS.>

Called when a session is first created.

=head1 BUGS

B<DEPRECATED - DO NOT USE THIS IN NEW APPLICATIONS.>

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ASP4> to submit bug reports.

=head1 HOMEPAGE

Please visit the ASP4 homepage at L<http://0x31337.org/code/> to see examples
of ASP4 in action.

=cut
