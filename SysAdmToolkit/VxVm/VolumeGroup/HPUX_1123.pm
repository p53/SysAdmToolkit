package SysAdmToolkit::VxVm::VolumeGroup::HPUX_1123;

=head1 NAME

SysAdmToolkit::VxVm::VolumeGroup::HPUX_1123 - OS and version specific module for getting info aboul LVM volume group

=head1 SYNOPSIS

	my $vg = SysAdmToolkit::VxVm::VolumeGroup::HPUX_1123->new('vg' => 'newdg');
										
	my $vgInfo = $vg->get('maxpv');

=head1 DESCRIPTION

Module is aimed at getting info about volume group on HP-UX 11.23

=cut

use base qw/
				SysAdmToolkit::VxVm::VolumeGroup::HPUX_1111
			/;
				
=head1 DEPENDECIES

	SysAdmToolkit::VxVm::VolumeGroup::HPUX_1111

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
