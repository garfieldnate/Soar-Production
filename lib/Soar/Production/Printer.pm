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

    print Dumper($trees);
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
}

1;

	