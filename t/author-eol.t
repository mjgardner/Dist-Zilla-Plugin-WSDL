
BEGIN {
    unless ( $ENV{AUTHOR_TESTING} ) {
        print qq{1..0 # SKIP these tests are for testing by the author\n};
        exit;
    }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/Plugin/WSDL.pm', 't/00-compile.t',
    't/00-report-prereqs.dd',        't/00-report-prereqs.t',
    't/01-whitemesa.t',              't/02-typemap.t',
    't/03-no_defs.t',                't/author-critic.t',
    't/author-eol.t',                't/author-minimum-version.t',
    't/author-mojibake.t',           't/author-no-tabs.t',
    't/author-pod-coverage.t',       't/author-pod-linkcheck.t',
    't/author-pod-syntax.t',         't/author-portability.t',
    't/author-test-version.t',       't/release-changes_has_content.t',
    't/release-cpan-changes.t',      't/release-dist-manifest.t',
    't/release-distmeta.t',          't/release-kwalitee.t',
    't/release-meta-json.t',         't/release-unused-vars.t'
);

eol_unix_ok( $_, { trailing_whitespace => 1 } ) foreach @files;
done_testing;
