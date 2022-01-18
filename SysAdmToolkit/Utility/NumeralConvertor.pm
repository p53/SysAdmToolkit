package SysAdmToolkit::Utility::NumeralConvertor;

=head1 NAME

SysAdmToolkit::Utility::NumeralConvertor - utility module for converting numbers

=head1 SYNOPSIS

	my $convertor = SysAdmToolkit::Utility::NumeralConvertor->new();
	
	my $decimals = [17,18];
	
	# result will contain []11, 12]
	$convertor->decToHex($decimals);
	
=head1 DESCRIPTION

Module serves for converting between numbers

=cut

=head1 METHODS

=over 12

=item C<decToHex>

Method decToHex converts array of decimals to hex

params:

	decNumArray array ref
	
return:

	array ref
	
=cut

sub decToHex() {
	
	my $self = shift;
	my $decNumArray = shift;
	
	my @hexNumArray = map{sprintf("%x", $_)} @$decNumArray;
	return \@hexNumArray;
	
} # end sub decToHex

=item C<hexToDec>

Method hexToDec converts array of decimals to hex

params:

	hexNumArray array ref
	
return:

	array ref
	
=back

=cut

sub hexToDec() {
	
	my $self = shift;
	my $hexNumArray = shift;
	
	my @decNumArray = map{hex($_)} @$hexNumArray;
	
	return \@decNumArray;
	
} # end sub hexToDec

=head1 DEPENDECIES

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;