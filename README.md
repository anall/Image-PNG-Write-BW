# NAME

Image::PNG::Write::BW - Create minimal black-and-white PNG files.

# VERSION

version 0.01

# SYNOPSIS

Turns a variety of raw black-and-white (1bpp) image representations into a minimal PNG image format.

    use Image::PNG::Write::BW qw( make_png_string );

    my $data = make_png_string( [ "# ", " #" ] ); # Returns a 2x2 repeatalbe grid pattern.

# EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

# SUBROUTINES/METHODS

## make\_png\_string( \\@lines )

Takes an arrayref of strings and turns them into a PNG. Whitespace characters are white, non-whitespace are black.

For example: make\_png\_string( \[ "###", "# #", "###" \] ) will make a 3x3 box with a hole in the middle.

## make\_png\_bitstream\_array( \\@scanlines, $width )

One bit per pixel, left-to-right on the image is high-bit to low-bit, lowest index to highest index. Each scanline passed as a seperate array element.

This currently copies each scanline.

## make\_png\_bitstream\_packed( $scanlines, $width, $height );

One bit per pixel, left-to-right on the image is high-bit to low-bit, lowest index to highest index. Each scanline starting on a byte boundary, with all scanlines packed into the same string.

This is the closest to the "native" PNG format.

This currently copies each scanline.  If you have the ability to use the raw format ( prefix each line with \\0 ), the make\_png\_bitstream\_raw method may be more efficient.

## make\_png\_bitstream\_raw( $data, $width, $height );

This is the "native" format that PNG uses: One bit per pixel, left-to-right on the image is high-bit to low-bit, lowest index to highest index. Each scanline starting on a byte boundary, with all scanlines packed into the same string. Every scanline must be prefixed by the filter type ( which should be \\0 -- assumptions made in this function will not work unless all scanlines are the same length )

# AUTHOR

Andrea Nall, `<anall at cpan.org>`

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Image::PNG::Write::BW

- Meta CPAN

    [https://metacpan.org/pod/Image::PNG::Write::BW](https://metacpan.org/pod/Image::PNG::Write::BW)

# AUTHOR

Andrea Nall <anall@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Andrea Nall.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
