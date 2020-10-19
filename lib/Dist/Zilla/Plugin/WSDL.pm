package Dist::Zilla::Plugin::WSDL;

# ABSTRACT: WSDL to Perl classes when building your dist

use Modern::Perl '2010';    ## no critic (Modules::ProhibitUseQuotedVersion)

# VERSION
use utf8;

=head1 SYNOPSIS

In your F<dist.ini>:

    [WSDL]
    uri = http://example.com/path/to/service.wsdl
    prefix = My::Dist::Remote::

=head1 DESCRIPTION

This L<Dist::Zilla|Dist::Zilla> plugin will create classes in your
distribution for interacting with a web service based on that service's
published WSDL file.  It uses L<SOAP::WSDL|SOAP::WSDL> and can optionally add
both a class prefix and a typemap.

=head1 SEE ALSO

=over

=item L<Dist::Zilla|Dist::Zilla>

=item L<SOAP::WSDL|SOAP::WSDL>

=back

=cut

use autodie;
use English '-no_match_vars';
use File::Copy 'copy';
use LWP::UserAgent;
use Moose;
use Moose::Meta::TypeConstraint;
use MooseX::AttributeShortcuts;
use MooseX::Types::Moose qw(ArrayRef Bool HashRef Str);
use MooseX::Types::Perl 'ModuleName';
use MooseX::Types::URI 'Uri';
use Path::Tiny;
use SOAP::WSDL::Expat::WSDLParser;
use SOAP::WSDL::Factory::Generator;
use Try::Tiny;
use namespace::autoclean;
with qw(
    Dist::Zilla::Role::Tempdir
    Dist::Zilla::Role::BeforeBuild
);

=attr uri

URI (sometimes spelled URL) pointing to the WSDL that will be used to generate
Perl classes.

=cut

has uri => ( is => 'ro', required => 1, coerce => 1, isa => Uri );

has _definitions => ( is => 'lazy', isa => 'SOAP::WSDL::Definitions' );

sub _build__definitions {
    my $self = shift;
    my $uri  = $self->uri;

    my $lwp = LWP::UserAgent->new();
    $lwp->env_proxy();
    my $parser = SOAP::WSDL::Expat::WSDLParser->new( { user_agent => $lwp } );

    my $wsdl;
    try { $wsdl = $parser->parse_uri( $self->uri ) }
    catch { $self->log_fatal("could not parse $uri into WSDL: $_") };
    return $wsdl;
}

has _OUTPUT_PATH => ( is => 'lazy', isa => Str, default => q{.} );

=attr prefix

String used to prefix generated class names.  Default is "My", which will result
in classes under:

=over

=item C<MyAttributes::>

=item C<MyElements::>

=item C<MyInterfaces::>

=item C<MyServer::>

=item C<MyTypes::>

=item C<MyTypemaps::>

=back

=cut

has prefix => (
    is      => 'ro',
    default => 'My',
    isa     => Moose::Meta::TypeConstraint->new(
        message =>
            sub {'must be valid class name, optionally ending in "::"'},
        constraint => sub {
            ## no critic (Modules::RequireExplicitInclusion)
            s/ :: \z//msx;
            ModuleName->check($_);
        },
    ),
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
    is       => 'ro',
    isa      => ArrayRef [Str],
    traits   => ['Array'],
    init_arg => 'typemap',
    handles  => { _typemap_array => 'elements' },
    default  => sub { [] },
);

has _typemap => (
    is      => 'lazy',
    isa     => HashRef [ModuleName],
    traits  => ['Hash'],
    handles => { _has__typemap => 'count' },
    default => sub {
        return { map { split / \s* => \s* /msx } $_[0]->_typemap_array };
    },
);

has _generator =>
    ( is => 'lazy', isa => 'SOAP::WSDL::Generator::Template::XSD' );

sub _build__generator {
    my $self = shift;

    my $generator
        = SOAP::WSDL::Factory::Generator->get_generator( { type => 'XSD' } );
    if ( $self->_has__typemap and $generator->can('set_typemap') ) {
        $generator->set_typemap( $self->_typemap );
    }

    my %prefix_method = map { ( $_ => "set_${_}_prefix" ) }
        qw(attribute type typemap element interface server);
    while ( my ( $prefix, $method ) = each %prefix_method ) {
        next if not $generator->can($method);
        $generator->$method( $self->prefix
                . ucfirst($prefix)
                . ( 'server' eq $prefix ? q{} : 's' ) );
    }

    my %attr_method
        = map { ( "_$_" => "set_$_" ) } qw(OUTPUT_PATH definitions);
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

has generate_server => ( is => 'lazy', isa => Bool, default => 0 );

=method before_build

Instructs L<SOAP::WSDL|SOAP::WSDL> to generate Perl classes for the provided
WSDL and gathers them into the C<lib> directory of your distribution.

=cut

sub before_build {
    my $self = shift;

    my (@generated_files) = $self->capture_tempdir(
        sub {
            $self->_generator->generate();
            my $method = 'generate_'
                . ( $self->generate_server ? 'server' : 'interface' );
            $self->_generator->$method;
        },
    );

    for my $file ( map { $_->file } grep { $_->is_new() } @generated_files ) {
        $file->name( path( 'lib', $file->name )->stringify() );
        $self->log( 'Saving ' . $file->name );
        my $file_path = $self->zilla->root->path( $file->name );
        $file_path->parent->mkpath();
        my $fh = $file_path->openw()
            or $self->log_fatal(
            "could not open $file_path for writing: $OS_ERROR");
        print {$fh} $file->content;
        close $fh;
    }
    return;
}

__PACKAGE__->meta->make_immutable();
no Moose;
1;
