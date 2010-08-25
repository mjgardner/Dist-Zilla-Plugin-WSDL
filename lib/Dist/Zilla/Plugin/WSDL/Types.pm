package Dist::Zilla::Plugin::WSDL::Types;

# ABSTRACT: Subtypes for Dist::Zilla::Plugin::WSDL

use Modern::Perl;
use English '-no_match_vars';
use Regexp::DefaultFlags;
use Moose;
use MooseX::Types::Moose 'Str';
use MooseX::Types::Path::Class qw(File to_File);
use MooseX::Types -declare => [qw(AbsoluteFile ClassPrefix)];

=head1 TYPES

=head2 AbsoluteFile

A subtype of L<Path::Class::File> that only accepts files with absolute paths.
Has coercions for relative-pathed files as well as strings.

=cut

subtype AbsoluteFile, as File, where { $ARG->is_absolute() };
coerce AbsoluteFile, from File, via { to_File($ARG)->absolute() };
coerce AbsoluteFile, from Str,  via { to_File($ARG)->absolute() };

=head2 ClassPrefix

A string subtype for Perl class names C<Like::This> or class prefix names
C<Like::This::>.

=cut

subtype ClassPrefix, as Str, where {
    $ARG =~ m{\A
        (?: \w+ )                   # top of name hierarchy
        (?: (?: :: ) (?: \w+ ) )*   # possibly more levels down
        (?: :: )?                   # possibly followed by ::
    };
};

1;

__END__

=head1 DESCRIPTION

This is a L<Moose> subtype library for L<Dist::Zilla::Plugin::WSDL>.
