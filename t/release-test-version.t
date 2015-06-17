
BEGIN {
    unless ( $ENV{RELEASE_TESTING} ) {
        require Test::More;
        Test::More::plan(
            skip_all => 'these tests are for release candidate testing' );
    }
}

use strict;
use warnings;
use Test::More;

# generated by Dist::Zilla::Plugin::Test::Version 1.03
use Test::Version;

my @imports = qw( version_all_ok );

my $params = {
    is_strict   => 1,
    has_version => 1,

};

push @imports, $params
    if version->parse($Test::Version::VERSION) >= version->parse('1.002');

Test::Version->import(@imports);

version_all_ok;
done_testing;
