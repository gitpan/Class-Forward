# ABSTRACT: Namespace Dispatch and Resolution

package Class::Forward;

use strict;
use warnings;

our $VERSION = '0.100006'; # VERSION

use Exporter ();

our @ISA    = qw(Exporter);
our @EXPORT = qw(clsf clsr);
our %CACHE  = ();



sub clsf {
    return Class::Forward->new(namespace => (caller)[0])->forward(@_);
}


sub clsr {
    return Class::Forward->new(namespace => (caller)[0])->reverse(@_);
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

    my $namespace = $self->namespace() || (caller)[0] || 'main';

    my $backspace;
    my $methods;
    my $myspace;

    my $class   = '';
    my @class   = ();
    my @methods = ();

    my $CACHE_KEY = $shorthand;
       $CACHE_KEY .= "\@$namespace";

    my $DATA = $CACHE{$CACHE_KEY} ||= do {

        if ($shorthand) {

            # capture path relativity notation

            $backspace = $1 if $shorthand =~ s/^((\.{1,2}\/){1,})//;

            $backspace = $1 if $shorthand =~ s/^(\/+)// && !$backspace;

            # capture method call notation

            ($methods) = $1 if $shorthand =~ s/((\.\w+){1,})$//;

            # convert shorthand to package notation

            $myspace = join "::", map {
                /_/ ? join '', map { ucfirst lc } split /_/, $_ : ucfirst $_
            }   split /(?:::|\-|\/)/, $shorthand;

            if ($backspace) {
                unless ($backspace =~ /^\/$/) {
                    @class = split /::/, $namespace;
                    if ($backspace =~ /^\/\/$/) {
                        while (@class > 1) {
                            pop @class;
                        }
                    }
                    else {
                        unless ($backspace =~ /^\.\/$/) {
                            my @backspaces = $backspace =~ /\.\.\//g;
                            for (@backspaces) {
                                pop @class unless @class == 1;
                            }
                        }
                    }
                }
            }
            else {
                push @class, $namespace;
            }

            push @class, split /::/, $myspace if $myspace;

            push @methods, grep /\w+/, split /\./, $methods if $methods;

        }

        push @class, $namespace if !@class;

        # build class namespace

        my $class = @class > 1 ? join('::', @class) : $class[0];

        # leverage @INC to validate and possibly correct any case issues

        my $file = "$class.pm";
        $file =~ s/::/\//g;

        unless ($INC{$file}) {

            # don't assume $#!+

            my @matches = grep(/^$file/i, keys %INC);

            if (@matches == 1) {

                $class = $matches[0];
                $class =~ s/\//::/g;
                $class =~ s/\.pm$//;

            }

        }

        # cache the results
        $CACHE{$CACHE_KEY} = {
            'CLASS'   => $class,
            'METHODS' => [@methods]
        };

    };

    $class   = $DATA->{'CLASS'};
    @methods = @{$DATA->{'METHODS'}} if $DATA && ! @methods;

    # return result of method call(s) or class name

    if (@methods) {

        for (my $i = 0 ; $i < @methods ; $i++) {

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

sub forward_lookup {
    goto \&forward
}


sub reverse {
    my ($self, $shorthand, $offset, $delimiter) = @_;

    $self->namespace((caller)[0] || 'main') unless $self->namespace;

    $shorthand =~ s/((\.\w+){1,})$// if $shorthand;
    $delimiter ||= '/';

    my $result = $self->forward($shorthand);
    my @pieces = split /::/, $result;

    if (defined $offset and $offset >= 0) {
        if ($offset == 0) {
            unshift @pieces, '';
        }
        else {
            shift @pieces for (1..$offset);
        }
    }
    else {
        unshift @pieces, '';
    }

    return join $delimiter,
        map { if ($_) { s/([a-z])([A-Z])/$1_\l$2/g; lc } } @pieces;
}

sub reverse_lookup {
    goto \&reverse
}


1;

__END__

=pod

=head1 NAME

Class::Forward - Namespace Dispatch and Resolution

=head1 VERSION

version 0.100006

=head1 SYNOPSIS

    use Class::Forward;

    # create a resolution object
    my $res = Class::Forward->new(namespace => 'MyApp');

    # returns MyApp::Data
    say $res->forward('data');

    # returns a MyApp::Data instance
    my $data  = $res->forward('data.new');

    # returns the string /my_app/data
    my $string = $res->reverse('data.new');

    # returns MyApp::Data
    say $res->forward($string);

=head1 DESCRIPTION

Class::Forward is designed to resolve Perl namespaces from shorthand (which is
simply a file-path-like specification). Class::Forward can also be used to
dispatch method calls using said shorthand. See the following exported
functions for examples on how this can be used.

=head1 EXPORTS

=head2 clsf

The exported function clsf is responsible for resolving your shorthand. The
following is an example of how it functions:

    package App::Store;

    use CGI;
    use Class::Forward;

    clsf;                             # returns App::Store
    clsf './user';                    # returns App::Store::User
    clsf './user.new', name => 'N30'; # return a new App::Store::User object
    clsf './user_profile.new';        # ... App::Store::UserProfile object
    clsf '../user';                   # returns App::User
    clsf '//';                        # returns App; (top of the calling class)
    clsf '//.new';                    # returns a new App object
    clsf '//view';                    # ... returns App::View
    clsf '//view.new';                # ... returns a new App::View object
    clsf '//view.new.render';         # ... dispatches methods in succession
    clsf 'cgi';                       # returns App::Store::Cgi
    clsf '/cgi';                      # returns Cgi (or CGI if already loaded)

    1;

The clsf function takes two arguments, the shorthand to be translated, and an
optional list of arguments to be passed to the last method appended to the
shorthand.

=head2 clsr

The exported function clsr is responsible for resolving your shorthand. The
following is an example of how it functions:

    package App::Store;

    use CGI;
    use Class::Forward;

    clsr;                             # returns /app/store
    clsr './user';                    # returns /app/store/user
    clsr './user.new', name => 'N30'; # returns /app/store/user
    clsr './user_profile';            # returns /app/store/user_profile
    clsr '../user';                   # returns /app/user
    clsr '//';                        # returns /app
    clsr '//.new';                    # returns /app
    clsr '//view';                    # returns /app/view
    clsr '//view.new';                # returns /app/view
    clsr '//view.new.render';         # returns /app/view
    clsr 'cgi';                       # returns /app/store/cgi
    clsr '/cgi';                      # returns /cgi

    1;

The clsr function takes three arguments, the shorthand to be translated
(required), the offset (optional level of namespace nodes to omit
left-to-right), and the delimiter to be used to generate the resulting path
(defaults to forward-slash).

=head1 METHODS

=head2 new

The new method is used to instantiate a new instance.

=head2 namespace

The namespace method is used to get/set the root namespace used as an anchor for
all resolution requests.

    my $namespace = $self->namespace('MyApp');

=head2 forward

The forward (or forward_lookup) method is used to resolve Perl namespaces from
path-like shorthand.

    say $self->forward('example');
    # given a default namespace of MyApp
    # prints MyApp::Example

=head2 reverse

The reverse method (or reverse_lookup) is used to generate path-like shorthand
from Perl namespaces.

    say $self->reverse('Simple::Example');
    # given a default namespace of MyApp
    # prints /my_app/simple/example

    say $self->reverse('Simple::Example', 1);
    # given a default namespace of MyApp
    # prints simple/example

    say $self->reverse('Simple::Example', 1, '_');
    # given a default namespace of MyApp
    # prints simple_example

=head1 SEE ALSO

Class::Forward was designed to provide shorthand and easy access to class
namespaces in an environment where you're dealing with a multitude of long
well-named classes. In that vein, it provides an alternative to modules like
L<aliased>, L<aliased::factory>, L<as>, and the like, and also modules like
L<Namespace::Dispatch> which are similar enough to be mentioned but really
address a completely different issue.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
