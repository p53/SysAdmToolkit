package SysAdmToolkit::VxVm::PhysicalVolume::HPUX_1123;

=head1 NAME

SysAdmToolkit::VxVm::PhysicalVolume::HPUX_1123 - OS and version specific module for getting info about physical volume

=head1 SYNOPSIS

	my $pv= SysAdmToolkit::VxVm::PhysicalVolume::HPUX_1123->new('pv' => 'c5t2d3');
										
	my $pvInfo = $pv->get('status');

=head1 DESCRIPTION

Module is aimed at getting info about physical volume for HP-UX 11.23

=cut

use base qw/
				SysAdmToolkit::VxVm::PhysicalVolume::HPUX_1111
			/;
				
=head1 DEPENDENCIES

	SysAdmToolkit::VxVm::PhysicalVolume::HPUX_1123

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
