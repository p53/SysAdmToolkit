package SysAdmToolkit::VxVm::Admin::HPUX_1131;

=head1 NAME

SysAdmToolkit::VxVm::Admin::HPUX_1131 - HP-UX 11.31 specific module for getting high level info about LVM on machine

=head1 SYNOPSIS

	my $lvmAdmin = SysAdmToolkit::VxVm::Admin::HPUX_1131->new();
	$lvmAdmin->getPvs();
	
=head1 DESCRIPTION

Module should help in getting higher level info about VxVm on the machine
about lvs, pvs, vgs

=cut

use base qw/
				SysAdmToolkit::VxVm::Admin::HPUX_1111
			/;

=head1 DEPENDECIES

	SysAdmToolkit::VxVm::Admin::HPUX_1111

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
