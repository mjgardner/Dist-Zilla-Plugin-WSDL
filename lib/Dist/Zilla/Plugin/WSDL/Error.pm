package Dist::Zilla::Plugin::WSDL::Error;

# ABSTRACT: Simple exception class

use English '-no_match_vars';
use Moose;
use MooseX::Has::Sugar;
use namespace::autoclean;
extends 'Throwable::Error';

=attr plugin

If provided, the
L<Dist::Zilla::Role::Plugin|Dist::Zilla::Role::Plugin>-consuming object that
should log the exception.

=cut

has plugin => ( ro, lazy_build,
    does      => 'Dist::Zilla::Role::Plugin',
    predicate => '_has_plugin',
);

=method throw

If L</plugin> exists, will call C<plugin->log_fatal> on the arguments instead of
throwing a plain exception.

=cut

around throw => sub {
    my ( $original_method, $invoker ) = splice @ARG, 0, 2;

    my $throwable = blessed $invoker ? $invoker : $invoker->new(@ARG);

    if ( $throwable->_has_plugin ) {
        $throwable->plugin->log_fatal( $throwable->message );
    }
    return $throwable->$original_method(@ARG);
};

1;

=head1 SYNOPSIS

    package Dist::Zilla::Plugin::MyPlugin;
    use Moose;
    with 'Dist::Zilla::Role::Plugin';
    use Dist::Zilla::Plugin::WSDL::Error;

    sub some_method {
        my $self = shift;
        Dist::Zilla::Plugin::WSDL::Error->throw(
            message => 'bad WSDL',
            plugin  => $self,
        );
    }

=head1 DESCRIPTION

This is a subclass of L<Throwable::Error|Throwable::Error> that also knows how
to log exceptions to a L<Dist::Zilla|Dist::Zilla> plugin's logger.

=head1 SEE ALSO

=over

=item L<Dist::Zilla|Dist::Zilla>

=item L<Throwable::Error|Throwable::Error>

=back
