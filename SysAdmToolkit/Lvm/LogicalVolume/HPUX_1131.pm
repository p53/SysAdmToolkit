package SysAdmToolkit::Lvm::LogicalVolume::HPUX_1131;

=head1 NAME

SysAdmToolkit::Lvm::LogicalVolume::HPUX_1131 - HP-UX 11.31 moodule for getting LVM info about logical volumes

=head1 SYNOPSIS

	my $lvol= SysAdmToolkit::Lvm::LogicalVolume::HPUX_1131->new('lv' => '/dev/vgroot/lvol1');

	or

	my $lvol= SysAdmToolkit::Lvm::LogicalVolume::HPUX_1131->new('lv' => 'lvol1', 'vg' => 'vgroot');							

	$lvol->get('lecount');

=head1 DESCRIPTION

Module OS and version specific module for getting info aboul logical volumes for HP-UX 11.31

=cut

use base qw/
				SysAdmToolkit::Lvm::LogicalVolume::HPUX_1111
			/;
		
=item changeCmd string

	Property stores command for changing properties of lvol

=cut

our $changeCmd = 'lvchange';

our $settable = {
					'status' => {'cmd' => "-a", 'verify' => 'y|n|e|s|r'},
					'cluster' => {'cmd' => "-c", 'verify' => 'y|n'},
					'sharable' => {'cmd' => "-S", 'verify' => 'y|n'},
				};
				
our $createParams = {
						'size' => '-L',
						'lecount' => '-l',
						'stripesize' => '-I',
						'stripecount' => '-i',
						'lvname' => '-n',
						'mirrors' => '-m'
					};

=head1 DEPENDECIES

	SysAdmToolkit::Lvm::LogicalVolume::HPUX_1111

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
