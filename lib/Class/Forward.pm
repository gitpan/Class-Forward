# ABSTRACT: Traverse Class Namspaces

package Class::Forward;

use strict;
use warnings;

our $VERSION = '0.100000'; # VERSION

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


1;

__END__

=pod

=head1 NAME

Class::Forward - Traverse Class Namspaces

=head1 VERSION

version 0.100000

=head1 SYNOPSIS

    package MyApp;

    use Class::Forward;

    sub class {

        my ($self, $shorthand, @arguments) = @_;

        my $class = Class::Forward->new(namespace => ref $self);

        return $class->forward($shorthand, @arguments);

    }

    package main;

    my $app  = MyApp->new;
    my $data = $app->class('data.new'); # returns a new MyApp::Data object

=head1 DESCRIPTION

Class::Forward is designed to simply return class names and/or dispatch method
calls using shorthand. It uses file-system path specification conventions to
match against class namespaces.

=head1 EXPORTS

=head2 clsf

The exported function clsf is responsible for resolving your shorthand. It
provides the follow functionality:

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
                                      # ... it tries to do the right thing

    1;

The clsf function takes two arguments, the shorthand to be translated, and an
optional list of arguments to be passed to the last method appended to the
shorthand.

=head2 clsr

The exported function clsr is responsible for resolving your shorthand. It
provides the follow functionality:

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

The clsr function takes two arguments, the shorthand to be translated, and an
optional list of arguments to be passed to the last method appended to the
shorthand.

=head1 SEE ALSO

Along my travels I recall visiting a similar module on the CPAN called
L<Namespace::Dispatch> which provides somewhat of the same functionality.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
