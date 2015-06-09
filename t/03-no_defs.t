#!perl

use 5.008_008;
use strict;
use warnings;
use utf8;
use Cwd;
use Dist::Zilla::Tester 4.101550;
use File::Temp;
use Regexp::DefaultFlags;
use Test::Most 'bail', tests => 1;
use Test::Moose;

use Dist::Zilla::Plugin::WSDL;

my $dist_dir = File::Temp->newdir();
my $zilla    = Dist::Zilla::Tester->from_config(
    { dist_root => "$dist_dir" },
    { add_files => { 'source/dist.ini' => <<'END_INI'} },
name     = test
author   = test user
abstract = test release
license  = Perl_5
version  = 1.0
copyright_holder = test holder

[WSDL]
uri = http://example.com/path/to/service.wsdl
END_INI
);
throws_ok(
    sub { $zilla->build() },
    qr/\A [[] WSDL []] \s /,
    'WSDL exception',
);
