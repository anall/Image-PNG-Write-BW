package Image::PNG::Write::BW;

use v5.10;
use strict;
use warnings FATAL => 'all';

use Digest::CRC;
use Compress::Raw::Zlib;

# ABSTRACT: Create minimal black-and-white PNG files.
our $VERSION = '0.01';

=head1 SYNOPSIS

Turns a variety of raw black-and-white (1bpp) image representations into a minimal PNG image format.

    use Image::PNG::Write::BW qw( make_png_string );

    my $data = make_png_string( [ "# ", " #" ] ); # Returns a 2x2 repeatalbe grid pattern.

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 make_png_string( \@lines )

Takes an arrayref of strings and turns them into a PNG. Whitespace characters are white, non-whitespace are black.

For example: make_png_string( [ "###", "# #", "###" ] ) will make a 3x3 box with a hole in the middle.

=cut

sub make_png_string($) {
    my ( $data ) = @_;

    die "cannot make 0-height png" if @$data == 0;

    my $deflate = Compress::Raw::Zlib::Deflate->new( -AppendOutput => 1 ) or die "failed to create Deflate module"; 
    my $out;

    my $width = undef;

    foreach my $line ( @$data ) {
      my $lineCp = $line; # We actually need a copy;
      if ( ! defined $width ) {
        $width = length( $lineCp );
        die "cannot make 0-width png" if $width == 0;
      }
      die "all lines must have same width" if $width != length( $lineCp );

      $lineCp =~ s/\S/0/g;
      $lineCp =~ s/\s/1/g;

      $deflate->deflate( pack("xB*",$lineCp) , $out ) == Z_OK or die "failed to deflate";
    }
    $deflate->flush( $out, Z_FINISH ) == Z_OK or die "failed to finish";

    return _make_png_raw_idat( $out, $width, scalar( @$data ) );
}


=head2 make_png_bitstream_array( \@scanlines, $width )
 
One bit per pixel, left-to-right on the image is high-bit to low-bit, lowest index to highest index. Each scanline passed as a seperate array element.

This currently copies each scanline.

=cut

sub make_png_bitstream_array($$) {
    my ( $data, $width ) = @_;

    die "cannot make 0-height png" if @$data == 0;
    die "cannot make 0-width png" if $width <= 0;

    my $width_bytes = int( ( $width + 7 ) / 8 );

    my $deflate = Compress::Raw::Zlib::Deflate->new( -AppendOutput => 1 ) or die "failed to create Deflate module";   
    my $out;

    my $cBuf = "\0" . "\0" x $width_bytes;

    for ( my $i = 0; $i < @$data; ++$i ) {
        die "data has wrong number of bytes on row $i" unless $width_bytes == length( $data->[$i] );
        
        substr( $cBuf, 1, $width_bytes ) = $data->[$i];
        $deflate->deflate( $cBuf, $out ) == Z_OK or die "failed to deflate";
    }

    $deflate->flush( $out, Z_FINISH ) == Z_OK or die "failed to finish";

    return _make_png_raw_idat( $out, $width, scalar( @$data ) );
}

=head2 make_png_bitstream_packed( $scanlines, $width, $height );
 
One bit per pixel, left-to-right on the image is high-bit to low-bit, lowest index to highest index. Each scanline starting on a byte boundary, with all scanlines packed into the same string.

This is the closest to the "native" PNG format.

This currently copies each scanline.  If you have the ability to use the raw format ( prefix each line with \0 ), the make_png_bitstream_raw method may be more efficient.

=cut

sub make_png_bitstream_packed($$$) {
    my ( $data, $width, $height ) = ( \$_[0], $_[1], $_[2] );

    die "cannot make 0-height png" if $height <= 0;
    die "cannot make 0-width png"  if $width <= 0;

    my $width_bytes = int( ( $width + 7 ) / 8 );
    die "data has wrong number of bytes" unless $width_bytes*$height == length($$data);

    my $deflate = Compress::Raw::Zlib::Deflate->new( -AppendOutput => 1 ) or die "failed to create Deflate module";   
    my $out;

    my $cBuf = "\0" . "\0" x $width_bytes;

    for ( my $i = 0; $i < $height; ++$i ) {
        substr( $cBuf, 1, $width_bytes ) = substr( $$data, $width_bytes * $i, $width_bytes ); 
        $deflate->deflate( $cBuf, $out ) == Z_OK or die "failed to deflate";
    }

    $deflate->flush( $out, Z_FINISH ) == Z_OK or die "failed to finish";

    return _make_png_raw_idat( $out, $width, $height );
}

=head2 make_png_bitstream_raw( $data, $width, $height );

This is the "native" format that PNG uses: One bit per pixel, left-to-right on the image is high-bit to low-bit, lowest index to highest index. Each scanline starting on a byte boundary, with all scanlines packed into the same string. Every scanline must be prefixed by the filter type ( which should be \0 -- assumptions made in this function will not work unless all scanlines are the same length )

=cut

sub make_png_bitstream_raw($$$) {
    my ( $data, $width, $height ) = ( \$_[0], $_[1], $_[2] );

    die "cannot make 0-height png" if $height <= 0;
    die "cannot make 0-width png"  if $width <= 0;

    my $width_bytes = int( ( $width + 7 ) / 8 ) + 1;
    die "data has wrong number of bytes" unless $width_bytes*$height == length($$data);

    my $deflate = Compress::Raw::Zlib::Deflate->new( -AppendOutput => 1 ) or die "failed to create Deflate module";   
    my $out;

    if ( length($$data) ) {
        $deflate->deflate( $$data, $out ) == Z_OK or die "failed to deflate";
    }
    $deflate->flush( $out, Z_FINISH ) == Z_OK or die "failed to finish";

    return _make_png_raw_idat( $out, $width, $height );
}


# Internal method to make a PNG file from all parts ( including raw IDAT content )

my $PNG_SIGNATURE = pack("C8",137,80,78,71,13,10,26,10);
my $PNG_IEND      = _make_png_chunk( "IEND", "" );
sub _make_png_raw_idat($$$) {
    my ( $data, $width, $height ) = ( \$_[0], $_[1], $_[2] );

    return join("", $PNG_SIGNATURE,
        _make_png_chunk( "IHDR", pack("NNCCCCC",$width,$height,1,0,0,0,0) ),
        _make_png_chunk( "IDAT", $$data ),
        $PNG_IEND);
}

# Internal method to make a PNG chunk

sub _make_png_chunk {
    my ($type,$data) = ( $_[0], \$_[1] );

    my $ctx = Digest::CRC->new(type => "crc32");
    $ctx->add( $type );
    $ctx->add( $$data );

    return join("", pack("N",length($$data)), $type, $$data, pack("N",$ctx->digest) );
}

=head1 AUTHOR

Andrea Nall, C<< <anall at cpan.org> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Image::PNG::Write::BW

=over 4

=item * Meta CPAN

L<https://metacpan.org/pod/Image::PNG::Write::BW>

=back

=cut

1; # End of Image::PNG::Write::BW
