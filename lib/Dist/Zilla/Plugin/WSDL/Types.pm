package Dist::Zilla::Plugin::WSDL::Types;

# ABSTRACT: Moose subtypes for DZP::WSDL

use Modern::Perl;
use English '-no_match_vars';
use Regexp::DefaultFlags;
use Moose;
use MooseX::Types::Moose 'Str';
use MooseX::Types::Path::Class qw(File to_File);
use MooseX::Types -declare => [qw(AbsoluteFile ClassPrefix)];

subtype AbsoluteFile, as File, where { $ARG->is_absolute() };
coerce AbsoluteFile, from File, via { to_File($ARG)->absolute() };
coerce AbsoluteFile, from Str,  via { to_File($ARG)->absolute() };

subtype ClassPrefix, as Str, where {
    $ARG =~ /\A
        (?: \w+ )                   # top of name hierarchy
        (?: (?: :: ) (?: \w+ ) )*   # possibly more levels down
        (?: :: )?                   # possibly followed by ::
    /;
};

1;
