package SysAdmToolkit::Lvm::VolumeGroup::HPUX_1123;

=head1 NAME

SysAdmToolkit::Lvm::VolumeGroup::HPUX_1123; - OS and version specific module for getting info aboul LVM volume group

=head1 SYNOPSIS

	my $vg = SysAdmToolkit::Lvm::VolumeGroup::HPUX_1123->new('vg' => 'vgroot');
										
	my $vgInfo = $vg->get('maxpv');

=head1 DESCRIPTION

Module is aimed at getting info about volume group on HP-UX 11.23

=cut

use base qw/
				SysAdmToolkit::Lvm::VolumeGroup::HPUX_1111
				SysAdmToolkit::Patterns::CmdBindedSetter
			/;

=item vgCreateCmd string

	Property stores command for creating volume group

=cut

my $vgCreateCmd = 'vgcreate';

=item vgRemoveCmd string

	Property stores command for removing volume group

=cut

my $vgRemoveCmd = 'vgremove';

=item changeCmd string

	Property stores command for changing Vg, this is needed for setting
	properties
	
=cut

our $changeCmd = 'vgchange';

our $settable = {
					'status' => {'cmd' => "-a", 'verify' => 'y|n|e|s|r'},
					'cluster' => {'cmd' => "-c", 'verify' => 'y|n'},
					'sharable' => {'cmd' => "-S", 'verify' => 'y|n'},
				};
				
our $createParams = {
						'pesize' => '-s',
						'maxlvs' => '-l',
						'maxpvs' => '-p',
						'maxpes' => '-e'
					};
				
=head1 DEPENDECIES

	SysAdmToolkit::Lvm::VolumeGroup::HPUX_1111

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
