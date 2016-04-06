#!perl
on configure => sub {
    requires 'File::Spec'                         => 0;
    requires 'Module::Build'                      => '0.4004';
    requires 'Module::Build::Pluggable'           => 0;
    requires 'Module::Build::Pluggable::CPANfile' => '0.05';
};

on runtime => sub {
    requires 'Carp'     => 0;
    requires 'Moo'      => 0;
    requires 'OptArgs2' => 0;
};

on test => sub {
    requires 'Test2::Bundle::Extended' => 0;
};
