package Dist::Zilla::Plugin::WSDL;

# ABSTRACT: WSDL to Perl classes when building your dist

use autodie;
use English '-no_match_vars';
use File::Copy 'copy';
use LWP::UserAgent;
use Moose;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw(ArrayRef Bool HashRef Str);
use MooseX::Types::URI 'Uri';
use Path::Class;
use Regexp::DefaultFlags;
## no critic (RequireDotMatchAnything,RequireExtendedFormatting)
## no critic (RequireLineBoundaryMatching)
use SOAP::WSDL::Factory::Generator;
use Try::Tiny;
use Dist::Zilla::Plugin::WSDL::Error;
use Dist::Zilla::Plugin::WSDL::Types qw(ClassPrefix Definitions);
use namespace::autoclean;
with 'Dist::Zilla::Role::Tempdir';
with 'Dist::Zilla::Role::BeforeBuild';

=attr uri

URI (sometimes spelled URL) pointing to the WSDL that will be used to generate
Perl classes.

=cut

has uri => ( ro, required, coerce, isa => Uri );

has _definitions => ( ro, lazy_build, isa => Definitions );

sub _build__definitions {    ## no critic (ProhibitUnusedPrivateSubroutines)
    my $self = shift;
    my $definitions;
    try { $definitions = Definitions->coerce( $self->uri ) }
    catch {
        Dist::Zilla::Plugin::WSDL::Error->throw(
            message => $ARG,
            plugin  => $self,
        );
    };
    return $definitions;
}

has _OUTPUT_PATH => ( ro, isa => Str, default => q{.} );

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

has prefix => ( ro, isa => ClassPrefix, default => 'My' );

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

has _typemap_lines => ( ro,
    isa => ArrayRef [Str],
    traits   => ['Array'],
    init_arg => 'typemap',
    handles  => { _typemap_array => 'elements' },
    default  => sub { [] },
);

has _typemap => ( ro, lazy_build,
    isa => HashRef [Str],
    traits  => ['Hash'],
    handles => { _has__typemap => 'count' },
);

sub _build__typemap {    ## no critic (ProhibitUnusedPrivateSubroutines)
    my $self = shift;

    return { map { +split / \s* => \s* /, $ARG } $self->_typemap_array };
}

has _generator =>
    ( ro, lazy_build, isa => 'SOAP::WSDL::Generator::Template::XSD' );

sub _build__generator {    ## no critic (ProhibitUnusedPrivateSubroutines)
    my $self = shift;

    my $generator
        = SOAP::WSDL::Factory::Generator->get_generator( { type => 'XSD' } );
    if ( $self->_has__typemap and $generator->can('set_typemap') ) {
        $generator->set_typemap( $self->_typemap );
    }

    my %prefix_method = map { ( $ARG => "set_${ARG}_prefix" ) }
        qw(attribute type typemap element interface server);
    while ( my ( $prefix, $method ) = each %prefix_method ) {
        next if not $generator->can($method);
        $generator->$method( $self->prefix
                . ucfirst($prefix)
                . ( $prefix eq 'server' ? q{} : 's' ) );
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

has generate_server => ( ro, isa => Bool, default => 0 );

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

    for my $file (
        map  { $ARG->file }
        grep { $ARG->is_new() } @generated_files,
        )
    {
        $file->name( file( 'lib', $file->name )->stringify() );
        $self->log( 'Saving ' . $file->name );
        my $file_path = $self->zilla->root->file( $file->name );
        $file_path->dir->mkpath();
        my $fh = $file_path->openw()
            or Dist::Zilla::Plugin::WSDL::Error->throw(
            message => "could not open $file_path for writing: $OS_ERROR",
            plugin  => $self,
            );
        print {$fh} $file->content;
        close $fh;
    }
    return;
}

__PACKAGE__->meta->make_immutable();
1;

=head1 SYNOPSIS

=for test_synopsis
1;
__END__

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
