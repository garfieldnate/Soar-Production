#test that the module is loaded properly

use strict;
use Test::More tests => 2;

use_ok('Soar::Production::Printer', 'use');
is(ref(Soar::Production::Printer->new) => 'Soar::Production::Printer', 'class');

__END__