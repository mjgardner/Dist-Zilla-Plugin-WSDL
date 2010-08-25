package Dist::Zilla::Plugin::WSDL;

# ABSTRACT: WSDL to Perl classes when building your dist

use Modern::Perl;
use English '-no_match_vars';
use IPC::System::Simple 'systemx';
use Moose;
use MooseX::Types::URI 'Uri';
use Dist::Zilla::Plugin::WSDL::Types qw(AbsoluteFile ClassPrefix);
with 'Dist::Zilla::Role::Tempdir';
with 'Dist::Zilla::Role::FileGatherer';

=attr uri

URI string pointing to the WSDL that will be used to generate Perl classes.

=cut

has uri => (
    is       => 'ro',
    isa      => Uri,
    required => 1,
    coerce   => 1,
);

=attr prefix

String used to prefix generated classes.

=cut

has prefix => (
    is  => 'ro',
    isa => ClassPrefix,
);

=attr typemap

Name of a typemap file to load in addition to the generated classes.

=cut

has typemap => (
    is     => 'ro',
    isa    => AbsoluteFile,
    coerce => 1,
);

=method gather_files

Instructs C<wsdl2perl.pl> to generate Perl classes for the provided WSDL
and gathers them into the C<lib> directory of your distribution.

=cut

sub gather_files {
    my $self = shift;

    my @command = (
        'wsdl2perl.pl',
        '--typemap_include' => $self->typemap(),
        '--prefix'          => $self->prefix(),
        '--base_path'       => q{.},
        $self->uri(),
    );

    my (@generated_files)
        = $self->capture_tempdir( sub { systemx(@command) } );

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
published WSDL file.  It uses L<SOAP::WSDL|SOAP::WSDL>'s C<wsdl2perl.pl>
script, which must be in your executable path, and can optionally add both a
class prefix and a typemap.
