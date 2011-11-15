
package ASP4::ErrorHandler::Remote;

use strict;
use warnings 'all';
use base 'ASP4::ErrorHandler';
use vars __PACKAGE__->VARS;
use LWP::UserAgent;
use HTTP::Request::Common;
use HTTP::Date 'time2iso';
use JSON::XS;
use Data::Dumper;
require ASP4;

our $ua;

sub run
{
  my ($s, $context) = @_;
  
  my $error = $Stash->{error};
  
  $s->print_error( $error, $args );
  $s->send_error($error, $args);
}# end run()


sub send_error
{
  my ($s, $error, $args) = @_;
  
  $ua ||= LWP::UserAgent->new();
  $ua->agent( ref($s) . " $ASP4::VERSION" );
  my $req = POST $Config->errors->post_errors_to, $args;
  $ua->request( $req );
}# end send_error()

1;# return true:

=pod

=head1 NAME

ASP4::ErrorHandler - Default fatal error handler

=head1 SYNOPSIS

In your C<asp4-config.json>:

  ...
    "errors": {
      "error_handler":    "ASP4::ErrorHandler::Remote",
      "post_errors_to":   "http://errors.ohno.com/post/errors/here/"
    },
  ...

=head1 DESCRIPTION

This class provides a default error handler which does the following:

1) Makes a simple HTML page and prints it to the browser, telling the user
that an error has just occurred.

2) Sends that same HTML to the web address specified in the config, using POST.

The data contained within the POST will match the public properties of L<ASP4::Error>.

=head1 PUBLIC METHODS

=head2 send_error( $error )

Sends the error data to the web address specified in C<<$Config->errors->post_errors_to>>.

The field names and values will correspond to the properties of an C<ASP4::Error> object.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ASP4> to submit bug reports.

=head1 HOMEPAGE

Please visit the ASP4 homepage at L<http://0x31337.org/code/> to see examples
of ASP4 in action.

=head1 AUTHOR

John Drago <jdrago_999@yahoo.com>

=head1 COPYRIGHT

Copyright 2008 John Drago.  All rights reserved.

=head1 LICENSE

This software is Free software and is licensed under the same terms as perl itself.

=cut

