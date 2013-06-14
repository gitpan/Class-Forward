BEGIN {

    use FindBin;
    use lib $FindBin::Bin . "/lib";
    use lib $FindBin::Bin . "/../lib";

}

use Test::More;

use_ok 'Class::Forward';

{

    package main;

    use Test::More;
    use Class::Forward;

    use MyApp;

    my  $last;

    sub clsf_ok {
        $last = clsf("$_[0]");
        ok $_[1] eq $last, "$_[1] namespace translated OK";
    }

    # simple namespace translation tests

    ok clsf(), "Class::Forward has a method named clsf";

    clsf_ok 0                 => "main";
    clsf_ok((undef)           => "main");
    clsf_ok "//"              => "main";
    clsf_ok "./"              => "main";
    clsf_ok "/"               => "main";
    clsf_ok "main"            => "main::Main";
    clsf_ok "/test-more"      => "Test::More";
    clsf_ok "/class-forward"  => "Class::Forward";
    clsf_ok "/CLASS-FORWARD"  => "Class::Forward";
    clsf_ok "/my_app" => "MyApp";

    ok "MyApp" eq ref clsf('my_app.new'),
        "Dipatched MyApp->new method call";
    ok "Hello World" eq clsf('my_app.new.hello_world'),
        "Dipatched MyApp->new->hello_world method calls in succession";

}

{

    package main;

    use Test::More;
    use Class::Forward;

    use MyApp;

    my  $last;

    sub clsr_ok {
        my ($arg, $tar) = (shift, pop);
        $last = clsr("$arg", @_);
        ok $tar eq $last, "$tar namespace translated OK";
    }

    # simple namespace reverse-translation tests

    ok clsr(), "Class::Forward has a method named clsr";

    clsr_ok 0                 => "/main";
    clsr_ok((undef)           => "/main");
    clsr_ok "//"              => "/main";
    clsr_ok "./"              => "/main";
    clsr_ok "../../.././"     => "/main";
    clsr_ok "/"               => "/main";
    clsr_ok "main"            => "/main/main";
    clsr_ok "/test-more"      => "/test/more";
    clsr_ok "/class-forward"  => "/class/forward";
    clsr_ok "/CLASS-FORWARD"  => "/class/forward";
    clsr_ok "/my_app"         => "/my_app";
    clsr_ok "/my_app.new"     => "/my_app";
    clsr_ok "/my_app.new.can" => "/my_app";
    clsr_ok "a"               => "/main/a";
    clsr_ok "a",0             => "/main/a";
    clsr_ok "a",1             => "a";
    clsr_ok "A::B::C",0       => "/main/a/b/c";
    clsr_ok "A::B::C",1       => "a/b/c";
    clsr_ok "A::B::C",2       => "b/c";
    clsr_ok "/A::B::C",0      => "/a/b/c";
    clsr_ok "/A::B::C",1      => "b/c";
    clsr_ok "/A::B::C",0,'.'  => ".a.b.c";
    clsr_ok "/A::B::C",1,'.'  => "b.c";

}

{

    package MyApp::Person::Good;

    use Test::More;
    use Class::Forward;

    my  $last;

    sub clsf_ok {
        $last = clsf("$_[0]");
        ok $_[1] eq $last, "$_[1] namespace translated OK";
    }

    # hierarchical namespace translation tests

    ok clsf(), "Class::Forward has a method named clsf";

    clsf_ok "//"        => "MyApp";
    clsf_ok "./_man"    => "MyApp::Person::Good::Man";
    clsf_ok "/App"      => "App";

    ok scalar(keys(%{Class::Forward::CACHE})), "The cache appears to be in use";

}

done_testing;
