
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

ASP4::GlobalASA - Application event handler

=head1 SYNOPSIS

  package DefaultApp::GlobalASA;

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

The GlobalASA handles 3 kinds of events:

=head2 Script_OnStart

Called after all objects have been initialized, but before the request is processed by its handler (or page).

=head2 Script_OnEnd

Called at the end of a request.

=head2 Session_OnStart

Called when a session is first created.

=cut

