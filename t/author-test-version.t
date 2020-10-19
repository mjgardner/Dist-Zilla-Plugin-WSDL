
BEGIN {
    unless ( $ENV{AUTHOR_TESTING} ) {
        print qq{1..0 # SKIP these tests are for testing by the author\n};
        exit;
    }
}

use strict;
use warnings;
use Test::More;

# generated by Dist::Zilla::Plugin::Test::Version 1.09
use Test::Version;

my @imports = qw( version_all_ok );

my $params = {
    is_strict   => 1,
    has_version => 1,
    multiple    => 0,

};

push @imports, $params
    if version->parse($Test::Version::VERSION) >= version->parse('1.002');

Test::Version->import(@imports);

version_all_ok;
done_testing;
