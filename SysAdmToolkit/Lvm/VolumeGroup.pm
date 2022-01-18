package SysAdmToolkit::Lvm::VolumeGroup;

=head1 NAME

SysAdmToolkit::Lvm::VolumeGroup - interface module for getting LVM info about volume groups

=head1 SYNOPSIS

	my $vg = SysAdmToolkit::Lvm::VolumeGroup->new('os' => 'HPUX', 'ver' => '1131', 'vg' => 'vg00');
										
	$vg->get('freepe');

=head1 DESCRIPTION

Module is interface module for OS  + version specific modules
,properties available to get depend on the OS and version specific modules

=cut

use base 'SysAdmToolkit::Patterns::OsFactoryProxy';

=head1 METHODS

=over 12

=item C<isAvail>

Method isAvail checks if volume group status is available

return:

	$result boolean

=back

=cut

sub isAvail() {

	my $self = shift;
	my $result = 1;

	if($self->{'proxy'}->{'status'} =~ /stale/) {
		$result = 0;	
	} # if	

	return $result;

} # end sub isAvail

=head1 DEPENDECIES

	SysAdmToolkit::Patterns::OsFactoryProxy

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
