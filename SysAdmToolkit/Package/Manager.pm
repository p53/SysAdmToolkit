package SysAdmToolkit::Package::Manager;

=head1 NAME

SysAdmToolkit::Package::Manager - module helps to check some info about packages, depots, it is HP-UX specific

=head1 SYNOPSIS

	my $packageManager = SysAdmToolkit::Package::Manager->new('type' => 'local', 'path' => '/my/Depots');
	my $depotAvailability = $packageManager->isDepotAvail();
	$packageManager->verifyPkgsState();

=head1 DESCRIPTION

Module is used to check some info about packages, depots

=cut

use base 'SysAdmToolkit::Monitor::Subject';

use SysAdmToolkit::Term::Shell;
use SysAdmToolkit::Nfs::Manager;
use Net::Domain qw(hostname hostfqdn hostdomain);

=head1 PRIVATE VARIABLES

=over 12

=item sourceTypes hash ref

Variable stores available types of package sources

	tape
	local
	nfs
	remote

=cut

my $sourceTypes = {
						'tape' => 'checkTapeAvail',
						'local' => 'checkLocalAvail',
						'nfs' => 'checkNfsAvail',
						'remote' => 'checkRemoteAvail'
					};

=item packageInstallCmd string

Variable stores command for installing packages

=cut

my $packageInstallCmd = 'swinstall';

=item packageListCmd string

Variable stores command for listing packages

=cut

my $packageListCmd = 'swlist';	

=item packageRemoveCmd string

Variable stores command for removing packages

=cut

my $packageRemoveCmd = 'swremove';		

=item sourceType string

Variable stores chosen source type

=cut

my $sourceType = '';

=item path string

Variable stores path to the depot, we are inspecting

=cut

my $path = '';

=item server string

Variable stores server on which depots is available

=cut

my $server = '';

=item file string

Variable is necessary to pass for NFS depots to perform availability check

=cut

my $file = '';

=item class string

Variable stores name of the class

=back

=cut

my $class = __PACKAGE__;

=head1 METHODS

=over 12

=item C<_init>

Method _init initializies object and check if all needed parameters are passed

params:

	type string - is required parameter, sets type of depot (check sourceTypes for available types)
	path - is path to the inspected depot
	server - is server name where depot is located (in case it is local depot it is not required)
	file - is path to the file which is necessary for NFS availability check

=cut

sub _init() {
	
	my $self = shift;
	$self->SUPER::_init(@_);
	my %params = @_;	
	$sourceType = $params{'type'};
	$path = $params{'path'};
	$server = $params{'server'};
	$file = $params{'file'};
	
	if(!$path || !$sourceType) {
		die("You didn't supply path or type!\n");
	} # if
	
	if($sourceType eq 'nfs' && !$file) {
		die "You must supply file parameter for nfs type!\n";
	} # if
	
	if(!$server) {
		$server = hostfqdn();
	} # if
	
} # end sub _init

=item C<isDepotAvail>

Method isDepotAvail check availability of depots

return:

	boolean

=cut

sub isDepotAvail() {
	
	my $self = shift;
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $source = "$server:$path";
	my $sourceTypeAvailability = 0;
	my $packageAvailability = 0;
	my $availMethod = $sourceTypes->{$sourceType};
		
	my $message = "Starting pre-checking $sourceType depot availability...";
	
	$self->runMonitor('message' => $message, 'severity' => 4, 'subsystem' => $class, 'status' => 1, 'statusOff' => 1);

	# first we are doing pre-check, it is dependent on source type, in case of remote network depot it will be ping, in case of
	# nfs it will be ls of nfs depot etc...
	$sourceTypeAvailability = $self->$availMethod();
	
	$message = "Availability pre-checks of $sourceType depot...";
	
	$self->runMonitor('message' => $message, 'severity' => 1, 'subsystem' => $class, 'status' => $sourceTypeAvailability);
	
	# if pre check is successful we are listing content of the depot with package command
	if($sourceTypeAvailability) {
		
		$message = "Starting checking depot availability with install tool...";
		
		$self->runMonitor('message' => $message, 'severity' => 4, 'subsystem' => $class, 'status' => 1, 'statusOff' => 1);
	
		$packageAvailability = $shell->execCmd('cmd' => $packageListCmd . " -s $source", 'cmdsNeeded' => [$packageListCmd]);
		
		my $returnCode = $packageAvailability->{'returnCode'};
		$message = "Availability of depot $source verified with install tool...";
		
		$self->runMonitor('message' => $message, 'severity' => 1, 'subsystem' => $class, 'status' => $returnCode);
		
	} # if
	
	return $packageAvailability->{'returnCode'};
	
} # end sub isAvail

=item C<verifyPkgsState>

Method verifyPkgsState check if all packages are configured, currently works just on localhost

return:

	$packagesState boolean

=cut

sub verifyPkgsState() {
	
	my $self = shift;
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $args = " -a state -l fileset | grep -v " . '^#' . " | grep -Ei 'installed|corrupt|transient'";
	my $packagesState = {};
	
	my $message = "Starting checking filesets state...";
	
	$self->runMonitor('message' => $message, 'severity' => 4, 'subsystem' => $class, 'status' => 1, 'statusOff' => 1);
	
	my $result = $shell->execCmd('cmd' =>  $packageListCmd . $args, 'cmdsNeeded' => [$packageListCmd, 'grep']);

	$packagesState->{'msg'} = $result->{'msg'};
	
	if($result->{'returnCode'}) {
		$packagesState->{'returnCode'} = 0;
	} else {
		$packagesState->{'returnCode'} = 1;	
	} # if
	
	$message = "Checking if all filesets are in configured state...";
	
	$self->runMonitor('message' => $message, 'severity' => 1, 'subsystem' => $class, 'status' => $packagesState->{'returnCode'});
		
	return $packagesState;
	
} # end sub verifyPkgsState

=item C<isPkgAvail>

Method isPkgAvail checks if package passed is available in the depot, currently works on localhost

params:

	$package string

return:

	boolean

=cut

sub isPkgAvail($) {
	
	my $self = shift;
	my $package = shift;
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $args = " $package";
	
	my $message = "Starting checking package $package availability...";
	
	$self->runMonitor('message' => $message, 'severity' => 4, 'subsystem' => $class, 'status' => 1, 'statusOff' => 1);
	
	my $result = $shell->execCmd('cmd' =>  $packageListCmd . $args, 'cmdsNeeded' => [$packageListCmd]);
	
	$message = "Checking availability of package $package...";
	
	$self->runMonitor('message' => $message, 'severity' => 1, 'subsystem' => $class, 'status' => $result->{'returnCode'});
	
	return $result->{'returnCode'};
	
} # end sub checkPkgAvail

=item C<removePkg>

Method removePkg removes pkg from host, currently works on localhost

params:

	package string
	
	options hash ref - you can pass options same as -x options for sw commands

return:

	boolean

=cut

sub removePkg($$) {
	
	my $self = shift;
	my %params = @_;
	my $package = $params{'package'};
	my $options = $params{'options'};
	my %optHash = %$options;
	my $optString = join(" -x ", map { "$_=$optHash{$_}" } keys %optHash);
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $args = "$optString $package";
	
	if(!$package) {
		die "You have to supply at least package name you want to remove!\n";
	} # if
	
	if($optString) {
		$args = '-x ' . $args;
	} # if
	
	my $message = "Starting removing package $package...";
	
	$self->runMonitor('message' => $message, 'severity' => 4, 'subsystem' => $class, 'status' => 1, 'statusOff' => 1);
	
	my $result = $shell->execCmd('cmd' =>  "$packageRemoveCmd $args", 'cmdsNeeded' => [$packageRemoveCmd]);
	
	$message = "Removing of package $package...";
	
	$self->runMonitor('message' => $message, 'severity' => 1, 'subsystem' => $class, 'status' => $result->{'returnCode'});
	
	return $result->{'returnCode'};
	
} # end sub removePkg

=item C<installPkg>

Method installPkg installs package on the host, currently works on the localhost

params:

	package string
	
	options hash ref

	preview - turns on preview

return:

	boolean

=cut

sub installPkg($$$) {
	
	my $self = shift;
	my %params = @_;
	my $package = $params{'package'};
	my $options = $params{'options'};
	my $preview = $params{'preview'};
	my $source = "$server:$path";
	my %optHash = %$options;
	my $mode = '';
	my $shell = SysAdmToolkit::Term::Shell->new();
	
	if(!$package) {
		die "You have to supply at least package name you want to install!\n";
	} elsif($package eq 'auto') {
		$package = '';
	} # if
	
	my $optString = join(" -x ", map { "$_=$optHash{$_}" } keys %optHash);

	my $args = "$optString -s $source $package";
	
	if($optString) {
		$args = '-x ' . $args;
	} # if
	
	if($preview) {
		$args = '-p ' . $args;
		$mode = 'preview mode';
	} # if
	
	my $message = "Starting installing package $package $mode...";
	
	$self->runMonitor('message' => $message, 'severity' => 4, 'subsystem' => $class, 'status' => 1, 'statusOff' => 1);
	
	my $result = $shell->execCmd('cmd' =>  "$packageInstallCmd $args", 'cmdsNeeded' => [$packageInstallCmd]);
	
	$message = "Installing of package $package...";
	
	$self->runMonitor('message' => $message, 'severity' => 1, 'subsystem' => $class, 'status' => $result->{'returnCode'});
	
	return $result->{'returnCode'};
	
} # end sub install

=item C<checkTapeAvail>

Method checkTapeAvail - currently not implemented

=cut

sub checkTapeAvail() {}

=item C<checkLocalAvail>

Method checkLocalAvail - currently not implemented

=cut

sub checkLocalAvail() {}

=item C<checkNfsAvail>

Method checkNfsAvail check availability of NFS depot - with NFS manager

return:

	$checkStatus boolean

=cut

sub checkNfsAvail() {
	
	my $self = shift;
	my @pathParts = split('/', $path);
	pop(@pathParts);
	my $directory = join('/', @pathParts);
	my $nfsManager = SysAdmToolkit::Nfs::Manager->new();
	
	$nfsManager->setMonitor($self->getMonitor());
	my $checkStatus = $nfsManager->checkNfsMount('path' => $directory, 'file' => $file);
	
	return $checkStatus;
	
} # end sub checkNfsAvail

=item C<checkRemoteAvail>

Method checkRemoteAvail check availability of remote depot - remote host is pinged 10 times

return:

	boolean

=back

=cut

sub checkRemoteAvail() {
	
	my $self = shift;
	my $shell = SysAdmToolkit::Term::Shell->new();
	
	my $message = "Starting checking network availability of server $server...";
	
	$self->runMonitor('message' => $message, 'severity' => 5, 'subsystem' => $class, 'status' => 1, 'statusOff' => 1);
	
	my $result = $shell->execCmd('cmd' => "ping $server -n 10", 'cmdsNeeded' => ['ping']);
	
	$message = "Check of network availability of server $server...";
	
	$self->runMonitor('message' => $message, 'severity' => 1, 'subsystem' => $class, 'status' => $result->{'returnCode'});
	
	return $result->{'returnCode'};
	
} # end sub checkRemoteAvail

=head1 DEPENDENCIES

	SysAdmToolkit::Monitor::Subject
	SysAdmToolkit::Term::Shell
	SysAdmToolkit::Nfs::Manager
	Net::Domain

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
