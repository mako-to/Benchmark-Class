use inc::Module::Install;
name 'Benchmark-Class';
all_from 'lib/Benchmark/Class.pm';

requires 'parent';
requires 'Carp';
requires 'Class::Accessor::Lite::Lazy';
requires 'Exporter::Lite';
requires 'Log::Minimal';
requires 'JSON';
requires 'Module::Load';
requires 'Role::Tiny';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
