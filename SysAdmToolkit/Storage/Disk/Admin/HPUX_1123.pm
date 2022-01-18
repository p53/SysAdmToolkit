package SysAdmToolkit::Storage::Disk::Admin::HPUX_1123;

=head1 NAME

SysAdmToolkit::Storage::Disk::Admin::HPUX_1123 - this is HP-UX 11.23 specific module for getting info about disk

=head1 SYNOPSIS

	my $diskAdmin = SysAdmToolkit::Storage::Disk::Admin::HPUX_1123->new();
	my $allDisks = $diskAdmin->getDisks();
	
=cut

use base qw/
				SysAdmToolkit::Storage::Disk::Admin::HPUX_1111
			/;

=head1 DEPENDENCIES

	SysAdmToolkit::Patterns::Prototype
	SysAdmToolkit::Patterns::Getter
	SysAdmToolkit::Term::Shell

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
