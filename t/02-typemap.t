#!perl

use Cwd;
use English '-no_match_vars';
use Dist::Zilla::Tester 4.101550;
use File::Temp;
use Path::Class;
use Test::Most;
use Test::Moose;

use Dist::Zilla::Plugin::WSDL;

my $tests;
my $typemap_class = 'MyTypemap::WSDLInteropTestDocLitService';
my %typemap       = (
    TestTypeString => 'SOAP::WSDL::XSD::Typelib::Builtin::string',
    TestTypeToken  => 'SOAP::WSDL::XSD::Typelib::Builtin::token',
);
my $typemap_conf = join q{},
    map {"typemap = $ARG => $typemap{$ARG}\n"} keys %typemap;

my $dist_dir = File::Temp->newdir();
my $zilla    = Dist::Zilla::Tester->from_config(
    { dist_root => "$dist_dir" },
    { add_files => { 'source/dist.ini' => <<"END_INI"} },
name     = test
author   = test user
abstract = test release
license  = Perl_5
version  = 1.0
copyright_holder = test holder

[WSDL]
uri = http://www.whitemesa.com/r3/InteropTestDocLitParameters.wsdl
$typemap_conf
END_INI
);

$zilla->build();
eval $zilla->slurp_file(
    file(qw(source lib MyTypemap WSDLInteropTestDocLitService.pm))
        ->stringify() );
while ( my ( $key, $class ) = each %typemap ) {
    is( $typemap_class->get_class( [$key] ), $class, "typemap $key" );
    $tests++;
}

done_testing($tests);