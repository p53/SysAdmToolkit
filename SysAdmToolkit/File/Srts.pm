package SysAdmToolkit::File::Srts;

=head1 NAME

SysAdmToolkit::File::Srts - module for extracting frame, lunid data from srts remarks

=head1 SYNOPSIS

	my $srts = SysAdmToolkit::File::Srts->new();
	
	# result will be array of hashes
	# {'lunid' => '3AD', 'frame' => '1589', 'product' => 'SYMMETRIX'}
	my $srtsInfo = $srts->extractType('type' => 'emc', 'str' => $srtsData);
	

=head1 DESCRIPTION

Module should help extracting frame, lunid data from srts remarks text

=cut

use base qw/
				SysAdmToolkit::Patterns::Factory
			/;

=head1 PRIVATE VARIABLES

=over 12

=item arrayTypes hash

Private property holds allowed vendors

=back

=cut

my %arrayTypes = (
						'eva' => 1,
						'hitachi' => 1,
						'emc' => 1
					);

=head1 METHODS

=over 12

=item C<extract>

Mehod extract gathers info from srts text and transforms it to array of hashes for each lun

params:

	str string - is text from srts
	
return:

	array ref
	
=cut
					
sub extract() {
	
	my $self = shift;
	my %params = @_;
	my @allRecs = ();
	
	if( !exists($params{'str'}) ) {
		die("You must supply string from which to extract!\n");	
	} # if
	
	for my $storType(keys %arrayTypes) {
		
		my $type = ucfirst($storType);
	
		my $typeObj = $self->produce('type' => $type);
		
		my $items = $typeObj->extract($params{'str'});
		
		my $itemSize = @$items;
		
		if( $itemSize > 0) {
			@allRecs = (@allRecs, @$items);
		} # if
		
	} # for
	
	return \@allRecs;
	
} # end sub extract

=item C<extractType>

Method extractType gathers info from srts text just for type supplied and transforms it to array of hashes

params:

	type string - one of vendors from arrayTypes
	
	str string - text with lun info from srts
	
return:

	array ref
	
=back

=cut

sub extractType() {
	
	my $self = shift;
	my %params = @_;
	my $str = $params{'str'};
	
	if( !exists($params{'type'}) && !exists($arrayTypes{$params{'type'}}) ) {
		die("You must supply supported array type!\n");
	} # if
	
	if( !exists($params{'str'}) ) {
		die("You must supply string from which to extract!\n");	
	} # if
	
	my $type = ucfirst($params{'type'});
	
	my $typeObj = $self->produce('type' => $type);
	
	my $records = $typeObj->extract($params{'str'});
	
	return $records;
	
} # end sub extractType

=head1 DEPENDECIES

	SysAdmToolkit::Patterns::Factory
	
=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;