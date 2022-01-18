package SysAdmToolkit::Storage::Lun::Admin::HPUX_1123;

use base qw/
				SysAdmToolkit::Storage::Lun::Admin::HPUX_1111
			/;
=head1 NAME

SysAdmToolkit::Storage::Lun::Admin::HPUX_1123 - interface module for getting info about Luns

=head1 SYNOPSIS

	my $lunAdmin = SysAdmToolkit::Storage::Lun::Admin::HPUX_1123->new();
										
	my @luns = $lunAdmin->getLuns('type' => 'emc');

=head1 DEPENDECIES

	SysAdmToolkit::Storage::Lun::Admin::HPUX_1111

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut
	
1;