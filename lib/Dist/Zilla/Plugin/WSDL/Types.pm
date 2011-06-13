package Dist::Zilla::Plugin::WSDL::Types;

# ABSTRACT: Subtypes for Dist::Zilla::Plugin::WSDL

use English '-no_match_vars';
use Regexp::DefaultFlags;
## no critic (RequireDotMatchAnything,RequireExtendedFormatting)
## no critic (RequireLineBoundaryMatching)
use LWP::UserAgent;
use Moose;
use MooseX::Types::Moose 'Str';
use MooseX::Types::URI 'Uri';
use MooseX::Types -declare => [qw(ClassPrefix Definitions)];
## no critic (Subroutines::ProhibitCallsToUndeclaredSubs)
use SOAP::WSDL::Expat::WSDLParser;
use Dist::Zilla::Plugin::WSDL::Error;
use namespace::autoclean;

=head1 TYPES

=head2 C<ClassPrefix>

A string subtype for Perl class names C<Like::This> or class prefix names
C<Like::This::>.

=cut

subtype ClassPrefix, as Str, where {/\A \w+ (?: :: \w+ )* (?: :: )? \z/},
    message {
    <<'END_MESSAGE'};
Class prefixes should only have alphanumeric or _ characters,
separated and optionally ending with "::".
END_MESSAGE

class_type Definitions, { class => 'SOAP::WSDL::Definitions' };
coerce Definitions, from Uri, via {
    my $lwp = LWP::UserAgent->new();
    $lwp->env_proxy();
    my $parser = SOAP::WSDL::Expat::WSDLParser->new( { user_agent => $lwp } );
    my $wsdl = $parser->parse_uri($ARG)
        or Dist::Zilla::Plugin::WSDL::Error->throw(
        "could not parse $ARG into WSDL");
    return $wsdl;
};

__PACKAGE__->meta->make_immutable();
1;

=head1 SYNOPSIS

    use Moose;
    use Dist::Zilla::Plugin::WSDL::Types ':all';

    has prefix => ( is => 'ro', isa => ClassPrefix, default => 'Foo::' );

=head1 DESCRIPTION

This is a L<Moose|Moose> subtype library for
L<Dist::Zilla::Plugin::WSDL|Dist::Zilla::Plugin::WSDL>.
