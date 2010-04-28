
package ASP4;

use strict;
use warnings 'all';
our $VERSION = '1.029';


1;# return true:

=pod

=head1 NAME

ASP4 - Fast, Simple, Scalable Web Development

=head1 DESCRIPTION

ASP4 is a web development environment.  It takes lessons learned from other web
development environments such as Microsoft ASP.Net, Ruby on Rails and Catalyst.

This project has some top-level priorities:

=over 4

=item * Test-Driven

ASP4 is made for the test-writing fanatic.  Anything your web application might do
can be tested - using L<Test::Simple>, L<HTML::Form> and L<ASP4::UserAgent>.

ASP4 supports test-fixtures, properties files (useful for error messages, etc)
and uses a simple plain-text JSON configuration file format.

=item * Keep It Simple, Smartypants (KISS)

ASP4 provides a clean slate on which to build web applications.  It does not go
out of its way to do everything for the developer, and does not enforce any kind
of specific coding style.

=item * Go Faster

On a server configuration which can serve a static "HELLO WORLD" page at 12,000 requests per second,
ASP4 can serve the "HELLO WORLD" equivalent at 1,200 requests per second.  A more
complex page that involves deeply-nested MasterPages and server-side includes may
come in at 1,000 requests per second.

=item * Easy to Learn

The intrinsic ASP objects - C<$Request>, C<$Response>, C<$Session>, C<$Server> -
and ASP4 extensions - C<$Form>, C<$Config>, C<$Stash> - focus developer attention
on a simplified environment, while still offering direct access to the "metal" underneath.

The classic Perl L<Apache2::RequestRec> C<$r> and L<CGI> objects are always accessible
via the L<ASP4::HTTPContext> api.

=item * Easy to Scale

Session state can be stored in a database (or distributed via memcached) which means
that ASP4 web applications can be served by one machine or many machines.

B<Outward Scalability> is in the DNA of ASP4.

=back

=head1 EXAMPLES

=head2 ASP Scripts

ASP scripts are pretty much as you might expect, if you've ever seen an ASP script before:

  <html>
    <body>
      <h1>Welcome Back, <%= $Session->{email} || "You" %>!</h1>
  <%
    for(1..5) {
  %>
    <%= $_ %>: Hello, World!<br/>
  <%
    }
  %>
    <p>
      Favorite Color: <%= $Server->HTMLEncode( $Form->{favorite_color} ) %>
    </p>
    </body>
  </html>

=head2 Form Handlers

Like "Controllers" in the MVC paradigm, "Handlers" respond to user input without
any of the Perl-embedded-in-HTML distraction.

Some URL-masking happens, so a request to C</handlers/hello.world> would go to:

  package hello::world;
  
  use strict;
  use warnings 'all';
  use base 'ASP4::FormHandler';
  use vars __PACKAGE__->VARS; # Import $Request, $Response, $Session, etc:
  
  sub run {
    my ($self, $context) = @_;
    
    $Response->SetCookie(
      name    => "last-seen",
      value   => scalar(localtime()),
      expires => 30 * 60 * 60 * 24, # 30 days:
    );
    $Response->Write("Hello World!");
  }
  
  1;# return true:

=head2 MasterPages

Similar to ASP.Net's concept of MasterPages, ASP4's MasterPages allow Page Composition.

Example: (eg: C</masters/global.asp>)

  <%@ MasterPage %>
  <html>
    <head>
      <title>
        <asp:ContentPlaceHolder id="meta_title">Default Title</asp:ContentPlaceHolder>
      </title>
      <meta name="keywords" content="<asp:ContentPlaceHolder id="meta_keywords"></asp:ContentPlaceHolder>" />
      <meta name="description" content="<asp:ContentPlaceHolder id="meta_description"></asp:ContentPlaceHolder>" />
    </head>
    <body>
      <h1>
        <asp:ContentPlaceHolder id="page_heading">HELLO</asp:ContentPlaceHolder>
      </h1>
      <p>
        <asp:ContentPlaceHolder id="page_body">Content coming soon!</asp:ContentPlaceHolder>
      </p>
    </body>
  </html>

If you access the page directly, you would see the default content displayed.

=head2 Child Pages

Child pages inherit from MasterPages - exactly like child classes inherit from super classes.

Example: (eg: C</child.asp>)

  <%@ Page UseMasterPage="/masters/global.asp" %>
  
  <asp:Content PlaceHolderID="meta_title">Child Title</asp:Content>
  
  <asp:Content PlaceHolderID="meta_keywords">child keywords</asp:Content>
  
  <asp:Content PlaceHolderID="meta_description">child description</asp:Content>
  
  <asp:Content PlaceHolderID="page_heading">The Child Page</asp:Content>
  
  <asp:Content PlaceHolderID="page_body">Hello from the Child Page - hooray!</asp:Content>

The result after accessing C</child.asp> you would see the following:

  <html>
    <head>
      <title>
        Child Title
      </title>
      <meta name="keywords" content="child keywords" />
      <meta name="description" content="child description" />
    </head>
    <body>
      <h1>
        The Child Page
      </h1>
      <p>
        Hello from the Child Page - hooray!
      </p>
    </body>
  </html>

=head2 MasterPage Inheritance

MasterPages can also inherit from other MasterPages.

Example: (eg: C</masters/submaster.asp>)

  <%@ MasterPage %>
  <%@ Page UseMasterPage="/masters/global.asp" %>

  <asp:Content PlaceHolderID="meta_title">Submaster Title</asp:Content>

  <asp:Content PlaceHolderID="meta_keywords">submaster keywords</asp:Content>

  <asp:Content PlaceHolderID="meta_description">submaster description</asp:Content>

  <asp:Content PlaceHolderID="page_heading">The Submaster Page</asp:Content>

  <asp:Content PlaceHolderID="page_body">
    The first part.<br/>
    <asp:ContentPlaceHolder id="sub_section">Hello from the subsection!</asp:ContentPlaceHolder>
    The final part.
  </asp:Content>

A page inheriting from C</masters/submaster.asp> could get by with only:

  <%@ Page UseMasterPage="/masters/submaster.asp" %>
  
  <asp:Content PlaceHolderID="sub_section">
    <b>Hello from the subsection!</b><br/>
  </asp:Content>

The resulting content would be:

  <html>
    <head>
      <title>
        Submaster Title
      </title>
      <meta name="keywords" content="submaster keywords" />
      <meta name="description" content="submaster description" />
    </head>
    <body>
      <h1>
        The Submaster Page
      </h1>
      <p>
    The first part.<br/>
    <b>Hello from the subsection!</b><br/>
    The final part.
      </p>
    </body>
  </html>

B<**THEN**> you could further subclass like this:

  <%@ Page UseMasterPage="/masters/submaster.asp" %>
  
  <asp:Content PlaceHolderID="meta_title">My Title!</asp:Content>
  
  <asp:Content PlaceHolderID="sub_section">My Content Too!</asp:Content>

The output would be:

  <html>
    <head>
      <title>
        My Title!
      </title>
      <meta name="keywords" content="submaster keywords" />
      <meta name="description" content="submaster description" />
    </head>
    <body>
      <h1>
        The Submaster Page
      </h1>
      <p>
        
    The first part.<br/>
    My Content Too!
    The final part.

      </p>
    </body>
  </html>

=head1 AUTHOR

John Drago <jdrago_999@yahoo.com>

=head1 COPYRIGHT

This software is Free software and may be used and redistributed under the same
terms as perl itself.

=cut

