
package ASP4::PageLoader;

use strict;
use warnings 'all';
use ASP4::PageParser;
use ASP4::ConfigLoader;
use File::stat;
my %FileTimes = ( );


sub discover
{
  my ($class, %args) = @_;
  
  my $web = ASP4::ConfigLoader->load()->web;
  my $filename = $web->www_root . $args{script_name};
  
  # Expand /folder/ to /folder/index.asp
  if( -d $filename )
  {
    $filename =~ s{/$}{};
    $args{script_name} .= "/index.asp";
    $filename .= "/index.asp";
  }# end if()
  (my $package = $args{script_name}) =~ s/[^a-z0-9]/_/ig;
  $package = $web->application_name . '::' . $package;
  
  (my $compiled_as = "$package.pm") =~ s/::/\//g;
  
  return {
    script_name => $args{script_name},
    'package'   => $package,
    filename    => $filename,
    compiled_as => $compiled_as,
    saved_to    => $web->page_cache_root . "/$compiled_as",
  };
}# end discover()


sub load
{
  my ($class, %args) = @_;
  
  my $info = $class->discover( script_name => $args{script_name} );
  if( $class->needs_recompile( $info->{saved_to}, $info->{filename} ) )
  {
    my $page = ASP4::PageParser->new( script_name => $info->{script_name} )->parse();
    $FileTimes{ $info->{filename} } = stat($info->{filename})->mtime;
    return $page;
  }# end if()

  my $config = ASP4::ConfigLoader->load();
  $config->load_class( $info->{package} );
  $FileTimes{ $info->{filename} } ||= stat($info->{filename})->mtime;
  return $info->{package}->new();
}# end load()


sub needs_recompile
{
  my ($class, $compiled_as, $filename) = @_;
  
  return 1 unless $compiled_as && -f $compiled_as;
  return stat($filename)->mtime > ( $FileTimes{ $filename } || stat($compiled_as)->mtime );
}# end needs_recompile()

1;# return true:

