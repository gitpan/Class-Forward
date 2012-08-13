# ABSTRACT: A class dispatcher that handles namespaces like paths

package Class::Forward;
{
    $Class::Forward::VERSION = '0.02';
}

use strict;
use warnings;

our $VERSION = '0.02';    # VERSION

use Exporter ();

our @ISA    = qw(Exporter);
our @EXPORT = qw(clsf);


sub clsf {

    my $namespace = caller(0);

    return Class::Forward->new(namespace => $namespace)->forward(@_);

}

sub new {

    my $self = bless {}, (shift);

    my %args = @_ ? @_ : ();

    $self->{namespace} = $args{namespace} if defined $args{namespace};

    return $self;

}

sub namespace {

    my ($self, $namespace) = @_;

    $self->{namespace} = $namespace if $namespace;

    return $self->{namespace};

}

sub forward {

    my ($self, $shorthand, @arguments) = @_;

    my @class;
    my @methods;

    my $caller = $self->namespace();

    my @segments = split /\//, $shorthand if $shorthand;

    if ($shorthand) {

        if ($shorthand eq '//' && !@segments) {

            @segments = ('', '');

        }

    }

    if (@segments) {

        # .method condition
        $segments[-1] =~ s/\.([\w\.]+)$//;

        push @methods, split /\./, $1 if $1;

        # // condition
        if (!$segments[0] && !$segments[1]) {

            # special condition, return top-level namespace of caller

            splice @segments, 0, 2;

            my $top = $caller;

            ($top) = $top =~ /^([^:]+)/ if $top =~ /:/;

            push @class, $top;

        }

        # / condition
        elsif (!$segments[0]) {

            splice @segments, 0, 1;

        }

        # ./ condition
        elsif ($segments[0] eq '.') {

            splice @segments, 0, 1;

            push @class, $caller;

        }

        # construct namespace from remaining segments

        foreach my $segment (@segments) {

            push @class, map {
                join '', map { ucfirst lc } split /_/, $_
              }
              split /-/, $segment;

        }

    }

    else {

        push @class, $caller;

    }

    # build class namespace

    my $class = @class > 1 ? join('::', @class) : $class[0];

    # leverage @INC to validate and possibly correct any case issues

    my $file = "$class.pm";
    $file =~ s/::/\//g;

    unless ($INC{$file}) {

        # dont assume $#!+

        my @matches = grep(/^$file/i, keys %INC);

        $class = $matches[0] if @matches == 1;

        $class =~ s/\//::/g;
        $class =~ s/\.pm$//;

    }

    # return result of method call(s) or class name

    if (@methods) {

        for (my $i = 0; $i < @methods; $i++) {

            my $method = $methods[$i];

            $class =
              $i == $#methods ? $class->$method(@arguments) : $class->$method;

        }

        return $class;

    }

    else {

        return $class;

    }

}


1;
__END__

=pod

=head1 NAME

Class::Forward - A class dispatcher that handles namespaces like paths

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    use CGI;
    use Class::Forward;
    
    my $q = clsf '/cgi.new'; # srsly?
    
    # OO syntax
    
    my $class = Class::Forward->new;
    
    $class->namespace(__PACKAGE__);
    
    my $root = $class->forward('//.new');

=head1 DESCRIPTION

Class::Forward is designed to simply return class names or dispatch method calls
using shorthand. It uses file-system path specification conventions to match
against class namespaces.

=head1 EXPORTS

=head2 clsf

The exported function clsf is responsible for resolving your shorthand. It
begets the follow functionaility:

    package App::Store;
    
    use CGI;
    use Class::Forward;
    
    clsf;                             # returns App::Store
    clsf './user';                    # returns App::Store::User
    clsf './user.new', name => 'N30'; # return a new App::Store::User object
    clsf './user_profile.new';        # ... App::Store::UserProfile object
    clsf '//';                        # returns App; (top of the calling class)
    clsf '//.new';                    # returns a new App object
    clsf '//view';                    # ... returns App::View
    clsf '//view.new';                # ... returns a new App::View object
    clsf '//view.new.render';         # ... dispatches methods in succession
    clsf 'cgi';                       # returns CGI
    clsf '/cgi';                      # ... also returns CGI
    
    # yada yada
    
    1;

The clsf function takes two arguments, the shorthand to be translated, and an
optional list of arguments to be passed to the last method appended to the
shorthand.

NOTE: There is only limited support for walk up a path, this is generally a bad
idea, writing code that executes other code based on its namespace's relativity
to the current class could yield unpredictable results, especially if the
calling class is ever relocated.

=head1 SEE ALSO

Along my travels I recall visiting a similar module on the CPAN called
L<Namespace::Dispatch> which provides somewhat of the same functionality.
Additionally, since this module looks like something INGY would upload, you
might want to check out his offerings also.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

