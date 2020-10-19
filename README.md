# NAME

Dist::Zilla::Plugin::WSDL - WSDL to Perl classes when building your dist

# VERSION

version 0.208

# SYNOPSIS

In your `dist.ini`:

    [WSDL]
    uri = http://example.com/path/to/service.wsdl
    prefix = My::Dist::Remote::

# DESCRIPTION

This [Dist::Zilla](https://metacpan.org/pod/Dist%3A%3AZilla) plugin will create classes in your
distribution for interacting with a web service based on that service's
published WSDL file.  It uses [SOAP::WSDL](https://metacpan.org/pod/SOAP%3A%3AWSDL) and can optionally add
both a class prefix and a typemap.

# ATTRIBUTES

## uri

URI (sometimes spelled URL) pointing to the WSDL that will be used to generate
Perl classes.

## prefix

String used to prefix generated class names.  Default is "My", which will result
in classes under:

- `MyAttributes::`
- `MyElements::`
- `MyInterfaces::`
- `MyServer::`
- `MyTypes::`
- `MyTypemaps::`

## typemap

A list of SOAP types and the classes that should be mapped to them. Provided
because some WSDL files don't always define every type, especially fault
responses.  Listed as a series of `=>` delimited pairs.

Example:

    typemap = Fault/detail/FooException => MyTypes::FooException
    typemap = Fault/detail/BarException => MyTypes::BarException

## generate\_server

Boolean value on whether to generate CGI server code or just interface code.
Defaults to false.

# METHODS

## before\_build

Instructs [SOAP::WSDL](https://metacpan.org/pod/SOAP%3A%3AWSDL) to generate Perl classes for the provided
WSDL and gathers them into the `lib` directory of your distribution.

# SEE ALSO

- [Dist::Zilla](https://metacpan.org/pod/Dist%3A%3AZilla)
- [SOAP::WSDL](https://metacpan.org/pod/SOAP%3A%3AWSDL)

# SUPPORT

## Perldoc

You can find documentation for this module with the perldoc command.

    perldoc Dist::Zilla::Plugin::WSDL

## Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

- CPANTS

    The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

    [http://cpants.cpanauthors.org/dist/Dist-Zilla-Plugin-WSDL](http://cpants.cpanauthors.org/dist/Dist-Zilla-Plugin-WSDL)

- CPAN Testers

    The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

    [http://www.cpantesters.org/distro/D/Dist-Zilla-Plugin-WSDL](http://www.cpantesters.org/distro/D/Dist-Zilla-Plugin-WSDL)

- CPAN Testers Matrix

    The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

    [http://matrix.cpantesters.org/?dist=Dist-Zilla-Plugin-WSDL](http://matrix.cpantesters.org/?dist=Dist-Zilla-Plugin-WSDL)

- CPAN Testers Dependencies

    The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

    [http://deps.cpantesters.org/?module=Dist::Zilla::Plugin::WSDL](http://deps.cpantesters.org/?module=Dist::Zilla::Plugin::WSDL)

## Bugs / Feature Requests

Please report any bugs or feature requests through the web
interface at [https://github.com/mjgardner/Dist-Zilla-Plugin-WSDL/issues](https://github.com/mjgardner/Dist-Zilla-Plugin-WSDL/issues). You will be automatically notified of any
progress on the request by the system.

## Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

[https://github.com/mjgardner/Dist-Zilla-Plugin-WSDL](https://github.com/mjgardner/Dist-Zilla-Plugin-WSDL)

    git clone git://github.com/mjgardner/Dist-Zilla-Plugin-WSDL.git

# AUTHOR

Mark Gardner <mjgardner@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by GSI Commerce.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
