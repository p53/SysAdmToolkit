package SysAdmToolkit::Storage::Disk::HPUX_1123;

=head1 NAME

SysAdmToolkit::Storage::Disk::HPUX_1123 - this is HP-UX 11.23 specific module for getting info about disk/lun

=head1 SYNOPSIS

	my $mydisk = SysAdmToolkit::Storage::Disk::HPUX_1123->new('hwPath' => '4/0/1/3/2.1.2');
	my $mydisksecond = SysAdmToolkit::Storage::Disk::HPUX_1123->new('devFile' => '/dev/dsk/c2t1d2');
	$mydisk->{'driver'};
	$mydisksecond->{'hwPath'};

=cut

use base qw/
				SysAdmToolkit::Storage::Disk::HPUX_1111
			/;

=head1 DEPENDENCIES

	SysAdmToolkit::Storage::Disk::HPUX_1111

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
