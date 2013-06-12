#modified from "Effective Perl Programming" by Joseph N. Hall, et al.
use strict;
use warnings;

# ABSTRACT: REPRESENT SOAR PRODUCTIONS
package Soar::Production;
use Carp;
use Soar::Production::Parser;
use Data::Dumper;
use Exporter::Easy (
	OK => [qw(prods_from prods_from_file)]
);

# VERSION

=head1 NAME

Soar::Production- Store and manipulate Soar productions

=head1 SYNOPSIS

	use Soar::Production qw(prods_from prods_from_file);
	my $prods = prods_from_file( '/path/to/file' );
	for my $prod (@$prods){
		print $prod->name . "\n";
	}
	my $prod =
	'sp{myName
		(state <s>)
		-->
		(<s> ^foo bar)
	}';
	my $prod = Soar::Production->new($prod);

=head1 DESCRIPTION

This is a module for storing, manipulating, and querying Soar productions.
There isn't much functionality implemented, yet. Currently there are functions
for

=cut


my $parser = Soar::Production::Parser->new;

#if run as a script, prints the name of every production in an input file.
unless(caller){
	my $prods = prods_from_file( $ARGV[0] );
	for my $prod (@$prods){
		print $prod->name . "\n";
	}
}

sub _run {
  my ($prod) = @_;
}

=head1 METHODS

=head2 C<new>

Argument: text of a Soar production.
Creates a new production object using the input text.

=cut

sub new {
  my ($class, $text) = @_;
  my $prod = bless $parser->parse_text($text), $class;
  return $prod;
}

# sub as_text {
# 	my ($class) = @_;
# 	# return $printer->tree_to_text($class)
# }

=head2 C<name>

Optional argument: name to assign production.
Sets the name of the current production if an argument is given.
Returns the name of the production.

=cut

sub name {
	my ($prod, $name) = @_;
	# print Dumper $prod;
	$prod->{name} = $name
		if($name);
	return $prod->{name};
}

=head1 EXPORTED FUNCTIONS

The following functions may be exported:

=head2 C<prods_from_file>

A shortcut for C<prods_from(file => $arg)>.

=cut

sub prods_from_file{
	return prods_from( file => shift() );
}

=head2 C<prods_from>

This method extracts productions from a given text. It returns a reference to an array containing production objects. Note that all comments are removed as a preprocessing step to detecting and extracting productions. It takes a set of named arguments:
C<file>- the name of a file to read.
C<text>- the text to read.
You must choose to export this function via the C<use> function:

	use Soar::Production qw(prods_from);

=cut

sub prods_from {
	my %args = @_;
	$args{text} or $args{file}
		or croak 'Must specify parameter \'file\' or \'text\' to extract productions.';

	my $parses = $parser->productions(@_, parse => 1);
	my @prods = map { bless $_ } @$parses; ## no critic(ProhibitOneArgBless)

	return \@prods;
}

1;

__END__

=head1 TODO

=head2 C<state_name>

Set/get name of matched state

=head2 C<superstate_name>

Set/get name of matched state's superstate

=head2 C<type>

Does this production match a state or an impasse?

=head2 C<validate>

Check this production against a datamap.

=head2 check semantic correctness

Soar::Production::Parser does not check semantic correctness. The following are good things to check:

=over

=item everything matched in RHS must be in LHS

=item no empty RHS

=item Only allowable non-operator preference is REJECT

=item Check for existence of RHS function

=item <s> not connected

=item disconnect from goal or impasses (no 'state' or 'impasse' keyword)

=back

