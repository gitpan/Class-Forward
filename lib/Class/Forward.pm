# ABSTRACT: A class dispatcher that handles namespaces like paths

package Class::Forward;
{
    $Class::Forward::VERSION = '0.06';
}

use strict;
use warnings;

our $VERSION = '0.06';    # VERSION

use Exporter ();

our @ISA    = qw(Exporter);
our @EXPORT = qw(clsf);


sub clsf {

    return Class::Forward->new(namespace => (caller)[0])->forward(@_);

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

    my @class   = ();
    my @methods = ();

    if ($shorthand) {

        # capture path relativity notation

        $backspace = $1 if $shorthand =~ s/^((\.{1,2}\/){1,})//;

        $backspace = $1 if $shorthand =~ s/^(\/+)// && !$backspace;

        # capture method call notation

        ($methods) = $1 if $shorthand =~ s/((\.\w+){1,})$//;

        # convert shorthand to package notation

        $myspace = join "::", map {
            join '', map { ucfirst lc } split /_/, $_
          }
          split /[\-\/]/, $shorthand;

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

version 0.06

=head1 SYNOPSIS

    # OO Usage and Syntax
    
    package MyApp;
    
    use Class::Forward;
    
    ...
    
    sub class {
        
        my ($self, $shorthand, @arguments) = @_;
        
        my $class = Class::Forward->new(namespace => ref $self);
        
        return $class->forward($shorthand, @arguments);
        
    }
    
    package main;
    
    my $app = MyApp->new;
    
    my $data = $app->class('data.new'); # returns a new MyApp::Data object

=head1 DESCRIPTION

Class::Forward is designed to simply return class names or dispatch method calls
using shorthand. It uses file-system path specification conventions to match
against class namespaces.

=head1 EXPORTS

=head2 clsf

The exported function clsf is responsible for resolving your shorthand. It
begets the follow functionality:

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
    
    # yada yada
    
    1;

The clsf function takes two arguments, the shorthand to be translated, and an
optional list of arguments to be passed to the last method appended to the
shorthand.

NOTE: Class::Forward also has support for walking up a path although this should
be done with caution, writing code that executes other code based on its
namespace's relativity to the current class could yield unpredictable results,
especially if the calling class is ever relocated.

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

