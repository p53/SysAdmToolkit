package SysAdmToolkit::Lvm::PhysicalVolume;

use base 'SysAdmToolkit::Patterns::OsFactoryProxy';

=head1 NAME

SysAdmToolkit::Lvm::PhysicalVolume - interface module for getting LVM info about physical volumes

=head1 SYNOPSIS

	my $pv = SysAdmToolkit::Lvm::PhysicalVolume->new('os' => 'HPUX', 'ver' => '1131', 'pv' => '/dev/dsk/disk21');
										
	$pv->get('freepe');

=head1 DESCRIPTION

Module is interface module for OS  + version specific modules
,properties available to get depend on the OS and version specific modules

=cut

=head1 DEPENDECIES

	SysAdmToolkit::Patterns::OsFactoryProxy

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
