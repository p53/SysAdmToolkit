package SysAdmToolkit::Lvm::LogicalVolume;

=head1 NAME

SysAdmToolkit::Lvm::LogicalVolume - interface module for getting LVM info about logical volumes

=head1 SYNOPSIS

	my $lvol= SysAdmToolkit::Lvm::LogicalVolume->new('os' => 'HPUX', 'ver' => '1131', 'lv' => '/dev/vgroot/lvol1');
										
	$lvol->get('pecount');

=head1 DESCRIPTION

Module is interface module for OS  + version specific modules
,properties available to get depend on the OS and version specific modules

=cut

use base 'SysAdmToolkit::Patterns::OsFactoryProxy';

=head1 METHODS

=over 12

=item C<isMirrored>

Method isMirrored checks if logical volume is mirrored

return:

	$result boolean

=back

=cut

sub isMirrored() {

	my $self = shift;
	my $result = 0;

	if($self->{'proxy'}->{'mirrors'} > 0) {
		$result = 1;	
	} # if

	return $result;

} # end sub isMirrored

=head1 DEPENDECIES

	SysAdmToolkit::Patterns::OsFactoryProxy

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
