package SysAdmToolkit::VxVm::LogicalVolume::HPUX_1123;

=head1 NAME

SysAdmToolkit::VxVm::LogicalVolume::HPUX_1123 - HP-UX 11.23 moodule for getting VxVm info about logical volumes

=head1 SYNOPSIS

	my $lvol= SysAdmToolkit::VxVm::LogicalVolume::HPUX_1123->new('lv' => 'lvol1', 'vg' => 'newdg');							

	$lvol->get('pvs');

=head1 DESCRIPTION

Module OS and version specific module for getting info aboul logical volumes for HP-UX 11.23

=cut

use base qw/
				SysAdmToolkit::VxVm::LogicalVolume::HPUX_1111
			/;
			
=head1 STATIC PROPERTIES

=over 12

=item settable hash ref

Property stores possible action for set method

=cut

our $settable = {
					'start' => {'cmd' => "start"},
					'stop' => {'cmd' => "stop"}
				};

=item createParams hash ref

Property stores parameter to command options mappings used during create

=back

=cut
			
our $createParams = {
						'layout' => 'layout=',
						'stripesize' => 'stripewidth=',
						'nstripe' => 'nstripe=',
						'nmirror' => 'nmirror='
					};
					
=head1 DEPENDECIES

	SysAdmToolkit::VxVm::LogicalVolume::HPUX_1111

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
