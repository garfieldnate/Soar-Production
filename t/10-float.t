#test correct float handling

use t::TestSoarProdParser;
use Test::Deep;
use Data::Dumper;

plan tests => 1*blocks;

filters { 
	# parse_success 		=> [qw(parse_success)],
	parse_struct		=> ['parse', 'dive=LHS,conditions,0,condition,attrValueTests,0,values,0,test,simpleTest'],
	expected_structure	=> 'eval'
};

run_is 'parse_success' => 'expected';

for my $block ( blocks('parse_struct')){
	# diag Dumper($block->parse_struct);
	cmp_deeply($block->expected_structure, subhashof($block->parse_struct), $block->name)
}

__END__
We just vary the value of foo

=== x.x
--- parse_struct 
sp {one
	(state <s> ^foo 1.2)
-->	(<s> ^foo foo)
}
--- expected_structure
{ type=>'float', constant=>'1.2' }

=== -x.x
--- parse_struct 
sp {neg-x-x
	(state <s> ^foo -1.3)
-->	(<s> ^foo foo)
}
--- expected_structure
{ type=>'float', constant=>'-1.3' }

=== x.xex
--- parse_struct 
sp {x-xex
	(state <s> ^foo 4.3e5)
-->	(<s> ^foo foo)
}
--- expected_structure
{ type=>'float', constant=>'4.3e5' }

=== x.xE-x
--- parse_struct 
sp {neg-x-xE-x
	(state <s> ^foo 4.3E-5)
-->	(<s> ^foo foo)
}
--- expected_structure
{ type=>'float', constant=>'4.3E-5' }

=== -x.xE-x
--- parse_struct 
sp {neg-x-xE-x
	(state <s> ^foo -4.3E-5)
-->	(<s> ^foo foo)
}
--- expected_structure
{ type=>'float', constant=>'-4.3E-5' }