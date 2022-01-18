package SysAdmToolkit::Storage::Disk;

=head1 NAME

SysAdmToolkit::Storage::Disk - this module is interface module for getting info about disks on the UNIX system

=head1 SYNOPSIS

		SysAdmToolkit::Storage::Disk::sync();
		my $primBootHw = '1/0/2/0/1.3.3';
		my $os = 'HPUX';
		my $osVersion = '1131';
		my $primBootDisk = SysAdmToolkit::Storage::Disk->new('hwPath' => $primBootHw, 'os' => $os, 'ver' => $osVersion);

=cut

use base 'SysAdmToolkit::Patterns::OsFactoryProxy';

use SysAdmToolkit::Term::Shell;

=head1 PRIVATE VARIABLES

=over 12

=item syncDisksCmd string

Variable stores command for syncing disks

=back

=cut

my $syncDisksCmd = 'sync';

=head1 METHODS

=over 12

=item C<sync>

Method sync flushes disk buffers to be written to disk

=back

=cut

sub sync() {
	
	my $self = shift;
	my $shell = SysAdmToolkit::Term::Shell->new();
	
	my $syncStatus = $shell->execCmd('cmd' => $syncDisksCmd, 'cmdsNeeded' => [$syncDisksCmd]);
	
	return $syncStatus->{'returnCode'};
	
} # end sub sync

=head1 DEPENDENCIES

	SysAdmToolkit::Patterns::OsFactoryProxy
	SysAdmToolkit::Term::Shell

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
