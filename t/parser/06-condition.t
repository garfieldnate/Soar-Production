#test basic condition structure (including state and impasse)

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
	cmp_deeply($block->expected_structure, $block->parse_struct, $block->name)
		or diag explain $block->parse_struct;
}

__END__
Conditions which have attribute/value matches but no bound variable parse,
but Soar prints a warning:
 Warning: On the LHS of production xyz, identifier <s*1>
 is not connected to any goal or impasse.
The two that say "Crashes Soar" are related to this bug:
https://code.google.com/p/soar/issues/detail?id=161
=== empty condition
Crashes Soar
--- parse_success
sp {empty-condition
	()
-->
}
--- expected: 1

=== state only
--- parse_success
sp {state-only
	(state)
-->
}
--- expected: 1

=== state with variable
--- parse_success
sp {state-variable
	(state <s>)
-->
}
--- expected: 1

=== state with assignment
Prints a warning in Soar
--- parse_success
sp {state-assignment
	(state ^foo <bar>)
-->
}
--- expected: 1

=== state with variable and assignment
--- parse_success
sp {state-var-assignment
	(state <s> ^foo <bar>)
-->
}
--- expected: 1

=== assignment without state or variable
Prints a warning in Soar
--- parse_success
sp {unbound-assignment
    (^foo <baz>)
-->
}
--- expected: 1

=== variable with no state or assignment
Crashes Soar
--- parse_success
sp {variable-alone
    (<bar>)
-->
}
--- expected: 1

=== impasse only
--- parse_success
sp {impasse
	(impasse)
-->
}
--- expected: 1

=== impasse with variable and assignment
--- parse_success
sp {impasse
	(impasse <i> ^foo <bar>)
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

=== negative
--- parse_success
sp {negative
	(state <s>)
	-(<s> ^foo bar)
-->
}
--- expected: 1

=== negative structure
--- parse_struct dive=LHS,conditions,0,negative
sp {negative
	-(<s> ^foo bar)
-->
}
--- expected_structure
'yes'

=== positive structure
--- parse_struct dive=LHS,conditions,0,negative
sp {positive
	(state <s>)
	(<s> ^foo bar)
-->
}
--- expected_structure
'no'

=== condition starts with test
--- parse_success
sp {state-conjunction
	(state { <> stuff <s2> })
	-->
}
--- expected: 1

=== condition starts with test (two id's)
Soar parses it but ignores the test.
"ignoring test(s) whose referent is unbound: Symbol: <s1>  Test: <> <s2>"
--- parse_success
sp {state-conjunction-unbound
	(state { <> <s2> <s1> })
	-->
}
--- expected: 1

=== condition starts with test (constant id field)
Soar parses it but won't add it to the productions.
"Constant stuff in id field test. This will never match."
--- parse_success
sp {state-conjunction-no-match
	(state { <> <s2> stuff })
	-->
}
--- expected: 1
