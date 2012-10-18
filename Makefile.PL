use inc::Module::Install;
name 'Benchmark-Class';
all_from 'lib/Benchmark/Class.pm';

requires 'parent';
requires 'Cache::Memcached::Fast';
requires 'Carp';
requires 'Class::Accessor::Lite::Lazy';
requires 'Exporter::Lite';
requires 'JSON';
requires 'Module::Load';
requires 'Role::Tiny';
requires 'Scalar::Util';
requires 'Smart::Args';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
