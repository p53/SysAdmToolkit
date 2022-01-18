package SysAdmToolkit::File::Csv;

=head1 NAME

SysAdmToolkit::File::Csv - module for fetching data from csv file

=head1 SYNOPSIS

	my $csv = SysAdmToolkit::File::Csv->new();
	
	# file containing lines
	# name age parent
	# Paul 20 Carol
	# Paul 25 Huge
	# Karin 65 Peter
	# will be converted to
	# [
	#	{'name' => 'Paul', 'age' => '20', 'parent' => 'Carol'},
	#	{'name' => 'Paul', 'age' => '25', 'parent' => 'Huge'},
	#	{'name' => 'Paul', 'age' => '65', 'parent' => 'Peter'}
	# ]						
	my $assoc = $csv->fetchAssoc('file' => '/tmp/csv.file');

=head1 DESCRIPTION

Module should help manipulating csv files

=cut

use base qw/
				SysAdmToolkit::Patterns::Prototype
			/;

use IO::File;
use SysAdmToolkit::Utility::Array;
 	
=head1 METHODS

=over 12

=item C<_init>

Method _init initializies variables fieldSep, fieldEncl, file

params:

	fieldSep string - field separator
	
	file string - location of csv file
	
=cut

sub _init() {
	
	my $self = shift;
	my %params = @_;
	$self->{'fieldSep'} = '\t';
	$self->{'file'} = $params{'file'};
	
	if(!exists($params{'file'})) {
		die("You must supply filename!\n");	
	} # if
	
	if(exists($params{'fieldSep'})) {
		$self->{'fieldSep'} = $params{'fieldSep'};
	} # if
	
	if(exists($params{'fieldEncl'})) {
		$self->{'fieldEncl'} = $params{'fieldEncl'};
	} # if
	
} # end sub _init

=item C<fetchAssoc>

Method fetchAssoc gets data from file and converts them to array of hash items

return:

	array ref
	
=cut

sub fetchAssoc() {
	
	my $self = shift;
	my $records = {};
	
	open(my $fh, '<:encoding(UTF-8)', $self->{'file'}) or die "Could not open file $self->{'file'} $!";
	
	my @rows = <$fh>;
	
	close($fh);
	
	$records = SysAdmToolkit::Utility::Array->arrayToAssoc('array' => \@rows, 'fieldSep' => $self->{'fieldSep'});
	
	return $records;
	
} # end sub fetchAssoc

=item C<fetchArray>

Method fetchArray gets data from file and returns array of lines

return:

	array ref
	
=cut

sub fetchArray() {
	
	my $self = shift;
	my @records = ();
	
	open(my $fh, '<:encoding(UTF-8)', $self->{'file'}) or die "Could not open file $self->{'file'} $!";
	
	@records = <$fh>;
	
	close($fh);
	
	chomp(@records);
	
	return \@records;
	
} # end sub fetchArray

=head1 DEPENDECIES

	SysAdmToolkit::Patterns::Prototype
	IO::File
	SysAdmToolkit::Utility::Array

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;