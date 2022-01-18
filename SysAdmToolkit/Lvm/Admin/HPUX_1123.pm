package SysAdmToolkit::Lvm::Admin::HPUX_1123;

=head1 NAME

SysAdmToolkit::Lvm::Admin::HPUX_1123 - HP-UX 11.23 specific module for getting high level info about LVM on machine

=head1 SYNOPSIS

	my $lvmAdmin = SysAdmToolkit::Lvm::Admin::HPUX_1123->new();
										
	my $bootInfo = $lvmAdmin->getBootInfo();

=head1 DESCRIPTION

Module should help in getting higher level info about LVM on the machine
about lvs, pvs, vgs, VGBRA

=cut

use base qw/
				SysAdmToolkit::Lvm::Admin::HPUX_1111
			/;

=head1 DEPENDECIES

	SysAdmToolkit::Lvm::PhysicalVolume::HPUX_1111

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
