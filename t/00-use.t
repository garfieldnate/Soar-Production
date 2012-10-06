#test that the module is loaded properly

use strict;
use Test::More tests => 2;

use_ok('Soar::Production::Parser', 'use');
is(ref(Soar::Production::Parser->new) => 'Soar::Production::Parser', 'class');

__END__