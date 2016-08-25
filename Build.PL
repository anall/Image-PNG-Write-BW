use v5.10;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Image::PNG::Write::BW',
    license             => 'artistic_2',
    dist_author         => q{Andrea Nall <anall@cpan.org>},
    dist_version_from   => 'lib/Image/PNG/Write/BW.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => '0.4004',
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Digest::CRC'         => 0,
        'Compress::Raw::Zlib' => 0,
    },
    add_to_cleanup     => [ 'Image-PNG-Write-BW-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();

