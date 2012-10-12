#Test that the printer prints each production in big.soar with exactly the same structure
use strict;
use warnings;
use Test::More;
# plan tests => 1*blocks;

use Soar::Production::Parser;
use Soar::Production::Printer;
use FindBin qw($Bin);
use File::Spec::Functions 'catfile';

my $datafile = File::Spec->catfile( $Bin, 'big.soar);

my $parser = Soar::Production::Parser->new();
my $productions = $parser->productions(file => $fullPath, parse => 0);
plan tests => 1 + @$productions;

my $printer = Soar::Production::Printer->new();

diag('Testing printer\'s ability to correctly print all productions in big.soar');
is($#$productions,821,'Found 822 productions in examples/big.soar');

# parse each prod in big.soar; then print and reparse. Compare the parses deeply to make sure nothing was
# structurally changed in printing.
my ($name, $parsed, $printed, $reparsed);
for my $prod(@$productions){
	$name = $prod =~ /sp \{(.*)/;
	$parsed = $parser->parse_text($prod);
	$printed = $printer->print($parsed);
	$reparsed = $parser->parse_text($printed);
	
	cmp_deeply($parsed, $reparsed, $name);
}