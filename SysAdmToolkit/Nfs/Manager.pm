package SysAdmToolkit::Nfs::Manager;

=head1 NAME

SysAdmToolkit::Nfs::Manager - module helps to check some NFS aspects, it is HP-UX specific

=head1 SYNOPSIS

	my $nfsManager = SysAdmToolkit::Nfs::Manager->new();
	my $areExported =$nfsManager->areFsExported();
	my $isNfsMountAvailable = $nfsManager->checkNfsMount('path' => '/nfs/depots', 'file' => '/tmp/nfsCheck');

=head1 DESCRIPTION

Module is used to check some Nfs functions, can be extended in future

=cut

use base 'SysAdmToolkit::Monitor::Subject';

use SysAdmToolkit::Term::Shell;

=head1 PRIVATE VARIABLES

=over 12

=item localhost string

This variable holds host name of localhost

=cut

my $localhost = '';

=item class string

Variable holds name of current class

=cut

my $class = __PACKAGE__;

=item showExportsCmd string

This variables stores command used to check if filesystems are exported

=back

=cut

my $showExportsCmd = 'showmount';

=head1 METHODS

=over 12

=item C<_init>

Method _init initializies object, hostname of localhost

=cut
	
sub _init() {
	my $self = shift;
	$self->SUPER::_init(@_);
	my $hostName = `uname -n`;
	$localhost = chomp($hostName);	
} # end sub _init

=item C<areFsExported>

Method areFsExported checks if localhost exports filesystems

return:

	$result boolean

=cut

sub areFsExported() {
	
	my $self = shift;
	my $shell = SysAdmToolkit::Term::Shell->new();
	
	my $isExported = $shell->execCmd('cmd' => "$showExportsCmd -e|grep -v grep|grep 'no exported file systems'", 'cmdsNeeded' => [$showExportsCmd]);
	
	my $result = (!$isExported->{'returnCode'});
	
	return $result;
	
} # end sub isExported

=item C<checkNfsMount>

Method checkNfsMount checks if passed nfs filesystem is available

To check if NFS filesystem is available we are checking it with ls command 
(which is running in background and detached, in case it will hang)
of NFS directory and outputting it to the file specified by parameter file

params:

	path string - is path to NFS filesystem

	file string - is path to file, which will be used to output ls command of NFS filesystem

return:

	$status boolean

=back

=cut

sub checkNfsMount($$) {
	
	my $self = shift;
	my %params = @_;
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $dirPath = $params{'path'};
	my $file = $params{'file'};
	my $stdOutFile = $file . '.stdout';
	my $stdErrorFile = $file . '.stderr';
	my $status = 0;

	if(-f $stdOutFile || -f $stdErrorFile) {
		unlink $stdErrorFile, $stdOutFile;
	} # if
	
	$self->runMonitor('message' => "Checking NFS mount $dirPath availability...", 'severity' => 4, 'subsystem' => $class, 'status' => 1, 'statusOff' => 1);
	
	my $cmd = "ls -al $dirPath > $stdOutFile 2> $stdErrorFile";
	
	$shell->execCmd('cmd' => $cmd, 'cmdsNeeded' => ['ls'] , 'detach' => 1, 'bg' => 1);
	
	sleep 10;
	
	if(-s $stdOutFile) { 
		$status = 1;	
	} # if
	
	$self->runMonitor('message' => "NFS mount $dirPath availability...", 'severity' => 1, 'subsystem' => $class, 'status' => $status);

	return $status;
	
} # if

=head1 DEPENDENCIES

	SysAdmToolkit::Monitor::Subject
	SysAdmToolkit::Term::Shell

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
