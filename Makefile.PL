# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name 'Net-DigitalNZ';
perl_version_from 'lib/Net/DigitalNZ/V3.pm';
all_from 'lib/Net/DigitalNZ.pm';

# Specific dependencies
requires 'JSON::Any'      => 1.19;
requires 'URI::Escape'    => 0;
requires 'LWP::UserAgent' => 0;
requires 'Carp'           => 0;
requires 'JSON::MaybeXS'  => 0;
requires 'URI'            => 0;
requires 'List::Util'     => 0;

#build_requires  'Test::More'        => '0.42';
build_requires 'Test2::Suite' => 0;
build_requires 'strictures'   => 0;

#recommends      'Your::OtherModule' => '0.01';

#no_index        'directory'         => 'demos';

#install_script  'bin/myscript';

auto_install;
WriteAll;
