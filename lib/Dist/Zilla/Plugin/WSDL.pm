package Dist::Zilla::Plugin::WSDL;

# ABSTRACT: WSDL to Perl classes when building your dist

use Modern::Perl;
use English '-no_match_vars';
use IPC::System::Simple 'systemx';
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Types::Path::Class 'to_File';
use MooseX::Types::URI 'Uri';
use Regexp::DefaultFlags;
with 'Dist::Zilla::Role::Tempdir';
with 'Dist::Zilla::Role::FileGatherer';

subtype AbsoluteFile => as 'Path::Class::File' =>
    where { $ARG->is_absolute() };
coerce AbsoluteFile => from 'Str' => via { to_File($ARG)->absolute() };

subtype ClassPrefix => as 'Str' => where {
    $ARG =~ /\A
        (?: \w+ )                   # top of name hierarchy
        (?: (?: :: ) (?: \w+ ) )*   # possibly more levels down
        (?: :: )?                   # possibly followed by ::
    /;
};

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
    isa => 'ClassPrefix',
);

=attr typemap

Name of a typemap file to load in addition to the generated classes.

=cut

has typemap => (
    is     => 'ro',
    isa    => 'AbsoluteFile',
    coerce => 1,
);

=method gather_files

Instructs L<wsdl2perl.pl> to generate Perl classes for the provided WSDL
and gathers them into the C<lib> directory of your distribution.

=cut

sub gather_files {
    my $self = shift;

    my @command = (
        'wsdl2perl.pl',
        '--typemap_include' => $self->typemap(),
        '--prefix'          => $self->prefix(),
        '--base_path'       => '.',
        $self->uri(),
    );

    my (@generated_files)
        = $self->capture_tempdir( sub { systemx(@command) } );

    for ( grep { $ARG->is_new() } @generated_files ) {
        $ARG->file->name( 'lib/' . $ARG->file->name() );
        $self->add_file( $ARG->file() );
    }
}

1;
