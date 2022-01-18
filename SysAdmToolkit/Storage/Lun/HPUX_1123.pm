package SysAdmToolkit::Storage::Lun::HPUX_1123;

=head1 NAME

SysAdmToolkit::Storage::Lun::HPUX_1123 - this is HP-UX 11.23 specific module for getting info about lun

=head1 SYNOPSIS

	my $myLun = SysAdmToolkit::Storage::Lun::HPUX_1123->new();
	my $frame = $myLun->get('frame');

=head1 DESCRIPTION

Module should help in getting info about lun

=cut

use base qw/
				SysAdmToolkit::Storage::Lun::HPUX_1111
			/;

=head1 DEPENDENCIES

	SysAdmToolkit::Storage::Lun::HPUX_1111

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
