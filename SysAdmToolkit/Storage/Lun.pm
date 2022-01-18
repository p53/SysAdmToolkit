package SysAdmToolkit::Storage::Lun;

=head1 NAME

SysAdmToolkit::Storage::Lun - this module is interface module for getting info about luns on the UNIX system

=head1 SYNOPSIS

	my $myLun = SysAdmToolkit::Storage::Lun->new('os' => 'HPUX, 'ver' => '1123');
	my $lun = $myLun->get('lunid');

=cut

use base 'SysAdmToolkit::Patterns::OsFactoryProxy';

use SysAdmToolkit::Term::Shell;

=head1 DEPENDENCIES

	SysAdmToolkit::Patterns::OsFactoryProxy
	SysAdmToolkit::Term::Shell

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
