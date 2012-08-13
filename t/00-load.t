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
    
    clsf_ok 0       => "main";
    clsf_ok((undef) => "main");
    
    clsf_ok "//"    => "main";
    clsf_ok "./"    => "main";
    clsf_ok "/"     => "main";
    
    clsf_ok "main"           => "Main";
    clsf_ok "test-more"      => "Test::More";
    
    clsf_ok "class-forward"  => "Class::Forward";
    clsf_ok "CLASS-FORWARD"  => "Class::Forward";
    
    clsf_ok "my_app" => "MyApp";
    
    ok "MyApp" eq ref clsf('my_app.new'), "Dipatched MyApp->new method call";
    ok "Hello World" eq clsf('my_app.new.hello_world'), "Dipatched MyApp->new->hello_world method calls in succession";
    
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
    
}

done_testing;
