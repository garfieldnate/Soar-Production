#test correct handling of state/impasse/nothing in a condition

use t::parser::TestSoarProdParser;
use Test::Deep;
use Data::Dumper;
use Test::More 0.88;

plan tests => 1*blocks;

filters {
	parse_success 		=> [qw(parse_success)],
	parse_struct		=> 'parse',
	expected_structure	=> 'eval'
};

run_is 'parse_success' => 'expected';

for my $block ( blocks('parse_struct')){
	# print STDERR Dumper($block->parse_struct);
	cmp_deeply($block->expected_structure, subhashof($block->parse_struct), $block->name)
		or diag explain $block->parse_struct;
}

__END__
Conditions which have attribute/value matches but no bound variable parse,
but Soar prints a warning:
 Warning: On the LHS of production xyz, identifier <s*1>
 is not connected to any goal or impasse.
=== empty condition
Currently this actually crashes Soar
--- parse_success
sp {empty-condition
	()
-->	(<bar> ^foo <bar>)
}
--- expected: 1

=== state only
--- parse_success
sp {state-only
	(state)
-->	(<bar> ^foo <bar>)
}
--- expected: 1

=== missing variable from non-state condition
Prints a warning in Soar
--- parse_success
sp {no-state-no-variable
    (^foo <baz>)
-->
}
--- expected: 1

=== state with variable
--- parse_success
sp {state-var
	(state <s>)
-->
}
--- expected: 1

=== state without variable, with assignment
Prints a warning in Soar
--- parse_success
sp {state-no-variable
	(state ^foo <bar>)
-->	(<bar> ^foo <bar>)
}
--- expected: 1

=== impasse only
--- parse_success
sp {impasse
	(impasse)
-->	(<i> ^foo <bar>)
}
--- expected: 1

=== structure of condition with state
--- parse_struct dive=LHS,conditions,0,condition
sp {foo
	(state)
-->
}
--- expected_structure
{
	condType 			=> 'state',
	idTest			=> undef,
	attrValueTests 	=> [],
}
