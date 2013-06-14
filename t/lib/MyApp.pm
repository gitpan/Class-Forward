package MyApp;

use strict;
use warnings;

sub new {
    bless {}, shift;
}

sub hello_world {
    return 'Hello World'
}

1;
