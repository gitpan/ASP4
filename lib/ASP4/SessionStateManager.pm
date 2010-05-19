
package ASP4::SessionStateManager;

use strict;
use warnings 'all';
use base 'Ima::DBI::Contextual';
use HTTP::Date qw( time2iso time2str str2time );
use Digest::MD5 'md5_hex';
use Storable qw( freeze thaw );
use Scalar::Util 'weaken';
use ASP4::ConfigLoader;


sub new
{
  my ($class, $r) = @_;
  my $s = bless { }, $class;
  my $conn = ASP4::ConfigLoader->load->data_connections->session;
  
  local $^W = 0;
  __PACKAGE__->set_db('Main',
    $conn->dsn,
    $conn->username,
    $conn->password
  );
  
  my $id = $s->parse_session_id();
  unless( $id && $s->verify_session_id( $id, $conn->session_timeout ) )
  {
    $s->{SessionID} = $s->new_session_id();
    $s->write_session_cookie($r);
    return $s->create( $s->{SessionID} );
  }# end unless()
  
  return $s->retrieve( $id );
}# end new()


sub context { ASP4::HTTPContext->current }


sub parse_session_id
{
  my $session_config = ASP4::ConfigLoader->load->data_connections->session;
  my $cookie_name = $session_config->cookie_name;
  my ($id) = ($ENV{HTTP_COOKIE}||'') =~ m/\b\Q$cookie_name\E\=([a-f0-9]{32,32})/s;

  return $id;
}# end parse_session_id()


sub new_session_id { md5_hex( rand() . time() . \"" ) }


sub write_session_cookie
{
  my ($s, $r) = @_;
  
  my $context = ASP4::HTTPContext->current;
  my $config = $context->config->data_connections->session;
  my $domain = "";
  unless( $config->cookie_domain eq '*' )
  {
    $domain = "domain=" . ( $config->cookie_domain || $ENV{HTTP_HOST} ) . ";";
  }# end unless()
  my $name = $config->cookie_name;
  
  my $expires = "";
  if( $config->session_timeout eq '*' )
  {
    $expires = "";
  }
  else
  {
    my $expire_time = time2str( time() + ( $config->session_timeout * 60 ) );
    $expires = "expires=$expire_time;";
  }# end if()
  
  my @cookie = (
    'Set-Cookie' => "$name=$s->{SessionID}; path=/; $domain $expires"
  );
  $context->headers_out->push_header( @cookie );
  @cookie;
}# end write_session_cookie()


sub verify_session_id
{
  my ($s, $id, $timeout ) = @_;
  
  my $is_active;
  if( $timeout eq '*' )
  {
    local $s->db_Main->{AutoCommit} = 1;
    my $sth = $s->db_Main->prepare_cached(<<"");
      SELECT *
      FROM asp_sessions
      WHERE session_id = ?

    $sth->execute( $id );
    ($is_active) = $sth->fetchrow();
    $sth->finish();
  }
  else
  {
    my $range_start = time() - ( $timeout * 60 );
    local $s->db_Main->{AutoCommit} = 1;
    my $sth = $s->db_Main->prepare_cached(<<"");
      SELECT *
      FROM asp_sessions
      WHERE session_id = ?
      AND modified_on BETWEEN ? AND ?

    $sth->execute( $id, time2iso($range_start), time2iso() );
    ($is_active) = $sth->fetchrow();
    $sth->finish();
  }# end if()

  return $is_active;
}# end verify_session_id()


sub create
{
  my ($s, $id) = @_;
  
  local $s->db_Main->{AutoCommit} = 1;
  my $sth = $s->db_Main->prepare_cached(<<"");
    INSERT INTO asp_sessions (
      session_id,
      session_data,
      created_on,
      modified_on
    )
    VALUES (
      ?, ?, ?, ?
    )

  my $time = time();
  my $now = time2iso($time);
  $s->{__lastMod} = $time;
  
  $s->sign();
  
  my %clone = %$s;
  
  $sth->execute(
    $id,
    freeze( \%clone ),
    $now,
    $now,
  );
  $sth->finish();
  
  return $s->retrieve( $id );
}# end create()


sub retrieve
{
  my ($s, $id) = @_;

  local $s->db_Main->{AutoCommit} = 1;
  my $sth = $s->db_Main->prepare_cached(<<"");
    SELECT session_data, modified_on
    FROM asp_sessions
    WHERE session_id = ?

  my $now = time2iso();
  $sth->execute( $id );
  my ($data, $modified_on) = $sth->fetchrow;
  $data = thaw($data) || { SessionID => $id };
  $sth->finish();

  my $max_timeout = $s->context->config->data_connections->session->session_timeout;
  my $seconds_since_last_modified = time() - str2time($modified_on);
  if( $max_timeout eq '*' )
  {
    if( $seconds_since_last_modified >= 1 )
    {
      local $s->db_Main->{AutoCommit} = 1;
      my $sth = $s->db_Main->prepare_cached(<<"");
      UPDATE asp_sessions SET
        modified_on = ?
      WHERE session_id = ?

      $sth->execute( time2iso(), $id );
      $sth->finish();
    }# end if()
  }
  else
  {
    my $timeout_seconds = $max_timeout * 60;
    if( $seconds_since_last_modified >= 1 && $seconds_since_last_modified < $timeout_seconds )
    {
      local $s->db_Main->{AutoCommit} = 1;
      my $sth = $s->db_Main->prepare_cached(<<"");
      UPDATE asp_sessions SET
        modified_on = ?
      WHERE session_id = ?

      $sth->execute( time2iso(), $id );
      $sth->finish();
    }# end if()
  }# end if()
  
  undef(%$s);
  $s = bless $data, ref($s);
  weaken($s);
  
  return $s;
}# end retrieve()


sub save
{
  my ($s) = @_;
  
  no warnings 'uninitialized';
  my $seconds_since_last_modified = time() - $s->{__lastMod};
  return unless ( $seconds_since_last_modified > 60 ) || $s->is_changed;
  $s->{__lastMod} = time();
  $s->sign;
  
  local $s->db_Main->{AutoCommit} = 1;
  my $sth = $s->db_Main->prepare_cached(<<"");
    UPDATE asp_sessions SET
      session_data = ?,
      modified_on = ?
    WHERE session_id = ?

  my %clone = %$s;
  my $data = freeze( \%clone );
  $sth->execute( $data, time2iso(), $s->{SessionID} );
  $sth->finish();
  
  1;
}# end save()


sub sign
{
  my $s = shift;
  
  $s->{__signature} = $s->_hash;
}# end sign()


sub _hash
{
  my $s = shift;
  
  no warnings 'uninitialized';
  md5_hex(
    join ":", 
      map { "$_:$s->{$_}" }
        grep { $_ ne '__signature' } sort keys(%$s)
  );
}# end _hash()


sub is_changed
{
  my $s = shift;
  
  no warnings 'uninitialized';
  $s->_hash ne $s->{__signature};
}# end is_changed()


sub reset
{
  my $s = shift;
  
  map { delete($s->{$_}) } grep { $_ ne 'SessionID' } keys %$s;
  $s->save;
  return;
}# end reset()


sub DESTROY
{
  my $s = shift;
  $s->save;
  undef(%$s);
}# end DESTROY()

1;# return true:

=pod

=head1 NAME

ASP4::SessionStateManager - Per-user state persistence

=head1 SYNOPSIS

  You've seen this page <%= $Session->{counter}++ %> times before.

=head1 DESCRIPTION

Web applications require session state management - and the simpler, the better.

C<ASP4::SessionStateManager> is a simple blessed hash.  When it goes out of scope,
it is saved to the database (or whatever).

If no changes were made to the session, it is not saved.

=head1 PUBLIC METHODS

=head2 save( )

Causes the session data to be saved.

=head2 reset( )

Causes the session data to be emptied.

=cut

