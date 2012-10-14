use strict;
use warnings;

# ABSTRACT: Print Soar productions
package Soar::Production::Printer;
use Soar::Production::Parser;
use Data::Dumper;
use Carp;

our $VERSION = '.01';

#default behavior is to read the input Soar file and output another one; worthless except for testing
__PACKAGE__->new->_run(@ARGV) unless caller;

sub new {
  my ($class) = @_;
  my $printer = bless {}, $class;
  $printer->_init;
  $printer;
}

#pass in an Soar grammar file name. Parse the file, then reconstruct it and print to STDOUT.
sub _run {
	my ($printer, $file) = @_;

    my $parser = Soar::Production::Parser->new();
    my $trees   = $parser->productions(file => $file, parse => 1);
    croak "parse failure\n" if ( $#$trees == -1 );

    # print Dumper($trees);
    print $printer->print_tree($$trees[0]);
	return;
}

sub _init {
  my ($printer) = @_;
  $printer->{output_fh} = \*STDOUT;
	$printer->{input_fh} = \*STDIN;
}

sub output_fh {
	my ( $printer, $fh ) = @_;
	if ($fh) {
		if(ref($fh) eq 'GLOB'){
			$printer->{output_fh} = $fh;
		}
		else{
			open my $fh2, '>', $fh or die "Couldn't open $fh";
			$printer->{output_fh} = $fh2;
		}
	}
	$printer->{output_fh};
}

sub input_fh {
	my ( $printer, $fh ) = @_;
	if ($fh) {
		if(ref($fh) eq 'GLOB'){
			$printer->{input_fh} = $fh;
		}
		else{
			open my $fh2, '<', $fh or die "Couldn't open $fh";
			$printer->{input_fh} = $fh2;
		}
	}
	$printer->{input_fh};
}

sub print_tree{
	my ($printer, $tree) = @_;
	
    #traverse tree and construct the Soar production text
    my $text = 'sp {';

    $text .= _name( $tree->{name} );
    $text .= _doc( $tree->{doc} );
    $text .= _flags( $tree->{flags} );
	
    $text .= _LHS( $tree->{LHS} );
	$text .= "\n-->\n\t";
    $text .= _RHS( $tree->{RHS} );
	$text .= "\n}";
	
	return $text;
}

sub _name {
	my $name = shift;
	return $name . "\n\t";;
}

sub _doc {
	my $doc = shift;
	if(defined $doc){
		return '"' . $doc . '"' . "\n\t";
	}
	return '';
}

sub _flags {
	my $flags = shift;
	my $text = '';
	for my $flag (@$flags){
		$text .= ':' . $flag . "\n\t";
	}
	return $text;
}

sub _LHS {
	my $LHS = shift;
	return join "\n\t", 
		map { _condition($_) } @{ $LHS->{conditions} };
}

sub _condition {
	my $condition = shift;
	my $text = '';
	
	$text .= '-'
		if($condition->{negative} eq 'yes');
		
	$text .= _positive_condition( $condition->{condition} );
	
	return $text;
}

sub _positive_condition {
	my $condition = shift;
	my $text = '';
	
	return _conjunction( $condition->{conjunction} )
		if($condition->{conjunction});
		
	return _condsForOneId($condition);
}

sub _condsForOneId {
	my $condsForOneId = shift;
	my $text = '(';
	my ($type, $idTest, $attrValueTests) = 
		(
			$condsForOneId->{condType}, 
			$condsForOneId->{idTest}, 
			$condsForOneId->{attrValueTests}
		);
		
	$text .= $type
		if(defined $type);
	
	$text .= ' ' . _test($idTest)
		if(defined $idTest);
		
	if($#$attrValueTests != -1){
		$text .= ' ';
		$text .= join ' ', map { _attrValueTests($_) } @$attrValueTests;
	}
	
	$text .= ')';
	return $text;
}

sub _test {
	my $test = shift;
	
	if(exists $test->{conjunctiveTest}){
		return _conjunctiveTest( 
			$test->{conjunctiveTest} );
	}
	
	return _simpleTest( $test->{simpleTest} );
}

sub _conjunctiveTest {
	my $conjTest = shift;
	my $text = '{';
	$text .= join ' ',
		map { _simpleTest($_) } @$conjTest;
	$text .= '}';
}

sub _simpleTest {
	my $test = shift;
	return _disjunctionTest($test->{disjunctionTest})
		if( exists $test->{disjunctionTest} );
	return _relationalTest($test->{relationalTest} )
		if( exists $test->{relationalTest} );
	return _singleTest($test);
}

sub _disjunctionTest {
	my $test = shift;
	my $text = '<< ';
	$text .= join ' ', map { _constant($_) } @$test;
	$text .= ' >>';
	return $text;
}

sub _relationalTest {
	my $test = shift;
	
	my $text = _relation( $test->{relation} );
	$text .= ' ';
	$text .= _singleTest( $test->{test} );
	
	return $text;
}

sub _relation {
	my $relation = shift;
	return $relation;
}

sub _singleTest {
	my $test = shift;
	return _variable($test->{variable})
		if( exists $test->{variable} );
	return _constant($test);
}

sub _attrValueTests {
	my $attrValuetests = shift;
	print 'hello';
	my ($negative, $attrs, $values) = 
		(
			$attrValuetests->{negative},
			$attrValuetests->{attrs},
			$attrValuetests->{values}
		);
	my $text = '';
	$text .= '-'
		if($negative eq 'yes');
	$text .= _attTest($attrs);
	
	if($#$values != -1){
		$text .= ' ';
		$text .= map { _valueTest($_) } @$values;
	}
	return $text;
}

sub _attTest {
	my $attTest = shift;
	my $text = '^';
	$text .= join '.', map { _test($_) } @$attTest;
	print $text;
	return $text;
}

sub _valueTest {
	my $valueTest = shift;
	my $text = '';
	
	if(exists $valueTest->{test}){
		$text = _test( $valueTest->{test} );
	}else{
		#condsForOneId
		$text = _condsForOneId($valueTest->{conds});
	}
	
	$text .= '+'
		if($valueTest->{'+'} eq 'yes');
	
	return $text
}

sub _conjunction {
	my $conjunction = shift;
	my $text = '{';
	$text .= join "\n\t", map { _condition($_) } @$conjunction;
	$text .= '}';
	return $text;
}

sub _RHS {
	my $RHS = shift;
	my $text = '';
	for my $action (@$RHS){
		$text .= _action($action);
		$text .= "\n\t";
	}
	return $text;
}

sub _action {
	my $action = shift;
	if(exists $action->{funcCall}){
		return _funcCall($action->{funcCall});
	}
	
	my $text = '(';
	$text .= _variable($action->{variable});
	$text .= ' ';
	$text .= join ' ',
		map {_attrValueMake($_)} @{ $action->{attrValueMake} };
	$text .= ')';
	return $text;
}

sub _attrValueMake {
	my $attrValueMake = shift;
	my ($attr, $valueMake) = 
		($attrValueMake->{attr}, $attrValueMake->{valueMake});
	my $text = '';
	if($#$attr != -1){
		$text .= join '.', map {_attr($_)} @$attr;
	}
	
	$text .= ' ';
	$text .= join ' ', map{_valueMake($_)} @$valueMake;
	
	return $text;
}

sub _valueMake {
	my $valueMake = shift;
	my ($rhsValue, $preferences) = 
		($valueMake->{rhsValue}, $valueMake->{preferences});
	my $text = _rhsValue($rhsValue);
	#there will always be at least one preference; '+' is default
	$text .= ' ';
	$text .= join ',', map { _preference($_) } @$preferences;
	return $text;
}

sub _preference {
	my $preference = shift;
	my $text = $preference->{value};
	if($preference->{type} eq 'binary'){
		$text .= ' ' . _rhsValue( $preference->{compareTo} );
	}
	return $text;
}

#variable | constant | "(crlf)" | funcCall
sub _rhsValue {
	my $rhsValue = shift;
	
	return '(crlf)'
		if($rhsValue eq '(crlf)');
		
	if(exists $rhsValue->{variable}){
		return _variable($rhsValue->{variable});
	}
	if(exists $rhsValue->{constant}){
		return _constant($rhsValue);
	}
	if(exists $rhsValue->{function}){
		return _funcCall($rhsValue);
	}
	return $rhsValue;
}

#(write |Hello World| |hello again|)
sub _funcCall {
	my $funcCall = shift;
	
	my ($name, $args) = 
		(_funcName($funcCall->{function}), $funcCall->{args});
	my $text = '(' . $name;
	if($#$args != -1){
		$text .= ' ';
		$text .= join ' ', map {_rhsValue($_)} @$args;
	}
	return $text . ')';
}

# arithmetic operator (+ - * /) or a symConstant, being the name of some function
sub _funcName {
	my $funcName = shift;
	
	if(ref $funcName eq 'HASH'){
		return _symConstant($funcName);
	}
	return $funcName;
}

sub _attr {
	my $attr = shift;
	return '^' . _variable($attr->{variable})
		if(exists $attr->{variable});
	return '^' . _symConstant($attr);
}

sub _variable {
	my $variable = shift;
	return '<' . $variable . '>'
}

sub _constant {
	my $constant = shift;
	my ($type, $value) = ($constant->{type}, $constant->{constant});
	
	return _symConstant($value) if($type eq 'sym');
	return _int($value) if($type eq 'int');
	return _float($value);#only other type is 'float'
}

sub _float {
	my $float = shift;
	return $float;
}

sub _int {
	my $int = shift;
	return $int;
}

#either string or quoted
sub _symConstant {
	my $symConstant = shift;
	my ($type, $value) = ($symConstant->{type}, $symConstant->{value});
	return _string($value) if($type eq 'string');
	return _quoted($value);
}

sub _string {
	return shift;
}

sub _quoted {
	return '|' . shift . '|';
}

1;

	