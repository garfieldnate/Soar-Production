#Test that the parser can parse a wide variety of productions
use strict;
use warnings;
use Test::More 0.88;
use t::parser::TestSoarProdParser;
# plan tests => 1*blocks;

use Soar::Production::Parser;
use FindBin qw($Bin);
use File::Spec::Functions(qw(catdir catfile));

my $path = File::Spec->catdir( $Bin,'examples' );


my $file = 'big';
my $parser = Soar::Production::Parser->new();
my $fullPath = File::Spec->catfile($path, $file . '.soar');
my $productions = $parser->productions(file => $fullPath, parse => 0);
plan tests => 1 + @$productions;

note('Testing parser\'s ability to parse all productions in examples/big.soar');
is($#$productions,821,'Found 822 productions in examples/big.soar');

for my $prod(@$productions){
	$prod =~ /sp \{(.*)/;
	ok(defined $parser->parse_text($prod), $1);
}