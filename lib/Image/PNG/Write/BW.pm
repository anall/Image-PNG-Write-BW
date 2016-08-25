package Image::PNG::Write::BW;

use v5.10;
use strict;
use warnings FATAL => 'all';

use Digest::CRC;
use Compress::Raw::Zlib;

=head1 NAME

Image::PNG::Write::BW - Create minimal black-and-white PNG files.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Image::PNG::Write::BW;

    my $foo = Image::PNG::Write::BW->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 make_png_bitstream_array( \@scanlines, $width );
 
One bit per pixel, left-to-right on the image is high-bit to low-bit, lowest index to highest index. Each scanline passed as a seperate array element.

This currently copies each scanline.

=cut

sub make_png_bitstream_array($$) {
    my ( $data, $width ) = @_;

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

This currently copies each scanline.  If you have the ability to use the raw format ( prefix each line with \0 ) and use the make_png_bitstream_raw method, that may be more efficient.

=cut

sub make_png_bitstream_packed($$$) {
    my ( $data, $width, $height ) = ( \$_[0], $_[1], $_[2] );

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

    my $ihdr = _make_png_chunk( "IHDR", pack("NNCCCCC",$width,$height,1,0,0,0,0) );

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

=head1 BUGS

Please report any bugs or feature requests to C<bug-image-png-write-bw at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Image-PNG-Write-BW>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Image::PNG::Write::BW

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Image-PNG-Write-BW>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Image-PNG-Write-BW>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Image-PNG-Write-BW>

=item * Search CPAN

L<http://search.cpan.org/dist/Image-PNG-Write-BW/>

=back

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Andrea Nall.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Image::PNG::Write::BW
