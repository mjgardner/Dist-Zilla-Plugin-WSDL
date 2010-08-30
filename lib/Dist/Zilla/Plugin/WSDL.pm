package Dist::Zilla::Plugin::WSDL;

# ABSTRACT: WSDL to Perl classes when building your dist

use Modern::Perl;
use English '-no_match_vars';
use LWP::UserAgent;
use Moose;
use MooseX::Types::Moose qw(ArrayRef Bool HashRef Str);
use MooseX::Types::URI 'Uri';
use SOAP::WSDL::Expat::WSDLParser;
use SOAP::WSDL::Factory::Generator;
use Dist::Zilla::Plugin::WSDL::Types qw(ClassPrefix);
with 'Dist::Zilla::Role::Tempdir';
with 'Dist::Zilla::Role::FileGatherer';

=attr uri

URI (sometimes spelled URL) pointing to the WSDL that will be used to generate
Perl classes.

=cut

has uri => (
    is       => 'ro',
    isa      => Uri,
    required => 1,
    coerce   => 1,
);

has _definitions => (
    is         => 'ro',
    isa        => 'SOAP::WSDL::Base',
    lazy_build => 1,
    init_arg   => undef,
);

sub _build__definitions {    ## no critic (ProhibitUnusedPrivateSubroutines)
    my $self = shift;

    my $lwp = LWP::UserAgent->new();
    $lwp->env_proxy();
    my $parser = SOAP::WSDL::Expat::WSDLParser->new( { user_agent => $lwp } );
    return $parser->parse_uri( $self->uri() );
}

has _OUTPUT_PATH => (
    is       => 'ro',
    isa      => Str,
    default  => q{.},
    init_arg => undef,
);

=attr prefix

String used to prefix generated classes.  Default is "My".

=cut

has prefix => (
    is        => 'ro',
    isa       => ClassPrefix,
    predicate => 'has_prefix',
    default   => 'My',
);

=attr typemap

A list of SOAP types and the classes that should be mapped to them. Provided
because some WSDL files don't always define every type, especially fault
responses.  Listed as a series of C<< => >> delimited pairs.

Example:

    typemap = Fault/detail/FooException => MyTypes::FooException
    typemap = Fault/detail/BarException => MyTypes::BarException

=for Pod::Coverage mvp_multivalue_args

=cut

sub mvp_multivalue_args { return 'typemap' }

has _typemap_lines => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => ArrayRef[Str],
    init_arg => 'typemap',
    handles  => { _typemap_array => 'elements' },
    lazy     => 1,
    default  => sub { [] },
);

has _typemap => (
    is         => 'ro',
    isa        => HashRef[Str],
    predicate  => 'has_typemap',
    init_arg   => undef,
    lazy_build => 1,
);

sub _build__typemap {    ## no critic (ProhibitUnusedPrivateSubroutines)
    my $self = shift;

    return { map { +split /\s*=>\s*/, $ARG } $self->_typemap_array() };
}

has _generator => (
    is         => 'ro',
    isa        => 'SOAP::WSDL::Generator::Template::XSD',
    lazy_build => 1,
);

sub _build__generator {    ## no critic (ProhibitUnusedPrivateSubroutines)
    my $self = shift;

    my $generator
        = SOAP::WSDL::Factory::Generator->get_generator( { type => 'XSD' } );
    if ( $self->has_typemap() and $generator->can('set_typemap') ) {
        $generator->set_typemap( $self->_typemap() );
    }

    my %prefix_method = map { ( $ARG => "set_${ARG}_prefix" ) }
        qw(attribute type typemap element interface server);
    while ( my ( $prefix, $method ) = each %prefix_method ) {
        next if not $generator->can($method);
        $generator->$method( $self->prefix()
                . ucfirst($prefix)
                . ( $prefix eq 'server' ? 's' : q{} ) );
    }

    my %attr_method
        = map { ( "_$ARG" => "set_$ARG" ) } qw(OUTPUT_PATH definitions);
    while ( my ( $attr, $method ) = each %attr_method ) {
        next if not $generator->can($method);
        $generator->$method( $self->$attr );
    }

    return $generator;
}

=attr generate_server

Boolean value on whether to generate CGI server code or just interface code.
Defaults to false.

=cut

has generate_server => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

=method gather_files

Instructs L<SOAP::WSDL|SOAP::WSDL> to generate Perl classes for the provided
WSDL and gathers them into the C<lib> directory of your distribution.

=cut

sub gather_files {
    my $self = shift;

    my (@generated_files) = $self->capture_tempdir(
        sub {
            $self->_generator->generate();
            my $method = 'generate_'
                . ( $self->generate_server ? 'server' : 'interface' );
            $self->_generator->$method;
        }
    );

    for ( grep { $ARG->is_new() } @generated_files ) {
        $ARG->file->name( 'lib/' . $ARG->file->name() );
        $self->add_file( $ARG->file() );
    }
    return;
}

1;

__END__

=head1 DESCRIPTION

This L<Dist::Zilla|Dist::Zilla> plugin will create classes in your
distribution for interacting with a web service based on that service's
published WSDL file.  It uses L<SOAP::WSDL|SOAP::WSDL> and can optionally add
both a class prefix and a typemap.
