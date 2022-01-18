package SysAdmToolkit::VxVm::Admin;

use base 'SysAdmToolkit::Patterns::OsFactoryProxy';

=head1 NAME

SysAdmToolkit::VxVm::Admin - interface module for getting high level info about VxVm on machine

=head1 SYNOPSIS

	my $lvmAdmin = SysAdmToolkit::VxVm::Admin->new('os' => 'HPUX', 'ver' => '1131');
										
	my $vgs = $lvmAdmin->getVgs();

=head1 DESCRIPTION

Module should help in getting higher level info about LVM on the machine
about lvs, pvs, vgs, VGBRA

=cut

=head1 DEPENDECIES

	SysAdmToolkit::Patterns::OsFactoryProxy

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
