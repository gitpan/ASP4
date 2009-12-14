
package ASP4::FileUpload;

use strict;
use warnings 'all';
use Carp 'confess';


sub new
{
  my ($class, %args) = @_;
  
  foreach(qw( ContentType FileHandle FileName ))
  {
    confess "Required param '$_' was not provided"
      unless $args{$_};
  }# end foreach()
  
  $args{UploadedFileName} = $args{FileName};
  ($args{FileName})       = $args{FileName} =~ m{[/\\]?([^/\\]+)$};
  ($args{FileExtension})  = $args{FileName} =~ m/([^\.]+)$/;
  $args{FileSize}         = (stat($args{FileHandle}))[7];
  
  return bless \%args, $class;
}# end new()


# Public readonly properties:
sub ContentType       { shift->{ContentType} }
sub FileHandle        { shift->{FileHandle} }
sub FileName          { shift->{FileName} }
sub UploadedFileName  { shift->{UploadedFileName} }
sub FileExtension     { shift->{FileExtension} }
sub FileSize          { shift->{FileSize} }
sub FileContents {
  my $s = shift;
  local $/;
  my $ifh = $s->FileHandle;
  my $ref = \scalar(<$ifh>);
  seek($ifh, 0, 0) or confess "Cannot seek to beginning of filehandle '$ifh': $!";
  return $$ref;
}


# Public methods:
sub SaveAs
{
  my ($s, $path) = @_;
  
  open my $ofh, '>', $path
    or confess "Cannot open '$path' for writing: $!";
  my $ifh = $s->FileHandle;
  while( my $line = <$ifh> )
  {
    print $ofh $line;
  }# end while()
  close($ofh);
  seek($ifh,0,0);
}# end SaveAs()


sub DESTROY
{
  my $s = shift;
  my $ifh = $s->FileHandle;
  close($ifh);
  undef(%$s);
}# end DESTROY()

1;# return true:

