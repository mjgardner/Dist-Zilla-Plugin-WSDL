package Dist::Zilla::Plugin::WSDL::Types;

# ABSTRACT: Subtypes for Dist::Zilla::Plugin::WSDL

use Modern::Perl;
use English '-no_match_vars';
use Regexp::DefaultFlags;
use Moose;
use MooseX::Types::Moose 'Str';
use MooseX::Types -declare => ['ClassPrefix'];
## no critic (Subroutines::ProhibitCallsToUndeclaredSubs)

=head1 TYPES

=head2 C<ClassPrefix>

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

This is a L<Moose|Moose> subtype library for
L<Dist::Zilla::Plugin::WSDL|Dist::Zilla::Plugin::WSDL>.
