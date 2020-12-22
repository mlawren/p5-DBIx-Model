#!perl
on configure => sub {
    requires 'File::Spec'                         => 0;
    requires 'Module::Build'                      => '0.4004';
    requires 'Module::Build::Pluggable'           => 0;
    requires 'Module::Build::Pluggable::CPANfile' => '0.05';
};

on runtime => sub {
    requires 'DBI'             => 0;
    requires 'Scalar::Util'    => 0;
    requires 'Types::Standard' => 0;
};

on test => sub {
    requires 'Test2::Bundle::Extended' => 0;
    requires 'Test2::Require::Module'  => 0;
};

on develop => sub {
    requires 'Class::Inline' => 0;
};

