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
	my $text = '';
	for my $cond (@{ $LHS->{conditions} }){
		$text .= _condition($cond);
	}
	return $text;
}

sub _condition {
	my $condition = shift;
	my $text = '';
	
	$text .= '-'
		if($condition->{negative} eq 'yes');
		
	$text .= '(';
	$text .= _positive_condition( $condition->{condition} );
	$text .= ')';
	
	return $text;
}

sub _positive_condition {
	my $condition = shift;
	my $text = '';
	
	return _conjunction( $condition->{conjunction} )
		if($condition->{conjunction});
	return '';#TODO: continue from here
	
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
	#TODO: continue here
	$text .= ')';
	return $text;
}

#variable | constant | "(crlf)" | funcCall
sub _rhsValue {
	my $rhsValue = shift;
	# print Dumper $rhsValue;
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
	
	my ($name, $args) = (_funcName($funcCall->{function}), $funcCall->{args});
	print $name;
	my $text = '(' . $name;
	if($#$args != -1){
		$text .= ' ';
		$text .= _args($args);
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

#just an array of values of some kind
sub _args {
	my $args = shift;
	my @rhsValues;
	for my $value (@$args){
		push @rhsValues, _rhsValue($value);
	}
	return join ' ', @rhsValues;
}

sub _variable {
	my $variable = shift;
	return '<' . $variable . '>'
}

sub _constant {
	my $constant = shift;
	# print '_const' . Dumper $constant;
	my ($type, $value) = ($constant->{type}, $constant->{constant});
	
	return _symConstant($value) if($type eq 'sym');
	return _float($value) if($type eq 'float');
	return _int($value) if($type eq 'int');
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
	# print '_sym' . Dumper $symConstant;
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

	