#!perl
on configure => sub {
    requires 'File::Spec'                         => 0;
    requires 'Module::Build'                      => '0.4004';
    requires 'Module::Build::Pluggable'           => 0;
    requires 'Module::Build::Pluggable::CPANfile' => '0.05';
};

on runtime => sub {
    requires 'DBI'             => 0;
    requires 'GraphViz2'       => 0;
    requires 'Moo'             => 0;
    requires 'OptArgs2'        => 0;
    requires 'Scalar::Util'    => 0;
    requires 'Time::Piece'     => 0;
    requires 'Types::Standard' => 0;
    requires 'XML::API'        => 0;
};

on test => sub {
    requires 'Test2::Bundle::Extended' => 0;
};
