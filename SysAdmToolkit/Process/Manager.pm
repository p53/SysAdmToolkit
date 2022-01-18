package SysAdmToolkit::Process::Manager;

=head1 NAME

SysAdmToolkit::Process::Manager - module helps to manage processes, early version

=head1 SYNOPSIS

	my $processConfig = {
			'checkInterval' => '5',
			'start' => {
					'item' => {
						'lpscheduler'=> {
											'id' => 1,
											'check' => {
															'cmds' => [ps, grep],
															'cmd' => 'ps -ef|grep lpsched|grep -v grep'
														},
											'startCmd' => '/sbin/init.d/lpsched start',
											'startCmds' => '',
											'timewait' => 300
										}
						'secondItem' => {
											'id' => 0,
											'check => {
															'cmds' => [ps, grep],
															'cmd' => 'ps -ef|grep swagent|grep -v grep'
														},
											'startCmd' => 'swagent -r',
											'startCmds' => 'swagent',
											timewait' => 500
										}
					}
			}
	}
	
	my $packageManager = SysAdmToolkit::Process::Manager->new('processes' => $processConfig);
	$packageManager->runItems();

=head1 DESCRIPTION

Module is used to manage processes, currently helps starting and stopping processes according passed configuration

=cut

use base 'SysAdmToolkit::Monitor::Subject';

use SysAdmToolkit::Term::Shell;
use SysAdmToolkit::File::Config::Xml;

=head1 PRIVATE VARIABLES

=over 12

=item class string

Variables stores name of the class

=back

=cut

my $class = __PACKAGE__;

=head1 METHODS

=over 12

=item C<_init>

Method _init initializies object

params:

	processes hash ref - contains configuration of which processes and how needs to be started/stopped

=cut

sub _init() {
	
	my $self = shift;
	$self->SUPER::_init(@_);
	my %params = @_;
	$self->{'processes'} = $params{'processes'};
	$self->{'config'} = 'SysAdmToolkit::File::Config::Xml';
	$self->{'operCodes'} =  {'stop' => 1, 'start' => 0};
	
	if(!$params{'processes'}) {
		die "You must supply processes parameter with settings!\n";
	} # if
	
} # end sub _init

=item C<runItems>

Method runItems runs stopping and starting processes according configuration passed during initialization

params:

	$operation start/stop

return:

	$result boolean

=cut

sub runItems($) {
	
	my $self = shift;
	my $operation = shift;
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $processesSettings = $self->{'processes'}->{$operation}->{'item'};
	my $config = $self->{'config'};
	my $checkInterval = $self->{'processes'}->{'checkInterval'};
	my $operCodes = $self->{'operCodes'};
	my @runItemsResults = ();
	my $result = 0;
	my $items = {};
		
	if($operation ne 'stop' && $operation ne 'start') {
		die "Permitted operations are just stop and start!\n";	
	} # if
	
	if($processesSettings->{'name'}) {
		my $itemName = $processesSettings->{'name'};
		$items->{$itemName} = $processesSettings;
	} else {
		$items = $processesSettings;
	} # if
	
	if($items) {
		
		# here we are sorting item keys according id which expresses order of execution
		my $sortedItemsKeys = $self->sortLevelItems($items);
		
		foreach my $itemName(@$sortedItemsKeys) {
			
			# here we initializing operation result, command by which we are checking if proccess started/stopped
			# command to start/stop process, time which we will be waiting for start/stop of process
			my $itemOperResult = 0;
			my $checkCmd = $items->{$itemName}->{'check'}->{'cmd'};
			my $operationCmd = $items->{$itemName}->{$operation . 'Cmd'};
			my $timeWait = $items->{$itemName}->{'timewait'};
			
			# to have absolute paths to commands we need check/cmds, operation/cmds, we also need dependencies
			# of item on other items
			my $cmdsNeeded = $config->getArray('source' => $items, 'path' => "$itemName/check/cmds");
			my $operationCmds = $config->getArray('source' => $items, 'path' => "$itemName/${operation}Cmds");
			my $dependencies = $config->getArray('source' => $items, 'path' => "$itemName/dependencies");
			
			# here we are checking if process is started/stopped
			my $checkResult = $shell->execCmd('cmdsNeeded' => $cmdsNeeded, 'cmd' => $checkCmd);
			
			# if current status is opposite of status we want to reach we continue
			if($checkResult->{'returnCode'} == $operCodes->{$operation}) {
				
				$message = "Starting executing $operation on $itemName...";
				$self->runMonitor('message' => $message, 'severity' => 4, 'subsystem' => $class, 'status' => 1, 'statusOff' => 1);
				
				$message = "Starting checking dependencies for $itemName...";
				$self->runMonitor('message' => $message, 'severity' => 5, 'subsystem' => $class, 'status' => 1, 'statusOff' => 1);
			
				# here we are checking if all dependencies are satisfied
				my $dependencyCheck = $self->checkDependencies('items' => $items, 'dependencies' => $dependencies, 'operation' => $operation);
			
				$message = "Dependecy check for $itemName...";
				$self->runMonitor('message' => $message, 'severity' => 4, 'subsystem' => $class, 'status' => $dependencyCheck);
					
				if(!$dependencyCheck) {
					push(@runItemsResults, $dependencyCheck);
					last;
				} # if
				
				# if dependency check successful we are executing operation
				my $operationResult = $shell->execCmd('cmdsNeeded' => $operationCmds, 'cmd' => $operationCmd);
				
				$message = "Executing $operation on $itemName...";
				$self->runMonitor('message' => $message, 'severity' => 5, 'subsystem' => $class, 'status' => $operationResult->{'returnCode'});
				
				# we need to check if process was started and have window of timewait for it, regularly checking in checkIntervals
				my $stopTime = time() + $timeWait;
				
				if($operationResult->{'returnCode'}) {
	
					while(time() < $stopTime) {
						
						my $modulus = time() % $checkInterval;

						if(!$modulus) {
							
							my $checkTimeResult = $shell->execCmd('cmdsNeeded' => $cmdsNeeded, 'cmd' => $checkCmd);
							
							if(!($checkTimeResult->{'returnCode'} == $operCodes->{$operation})) {
								$itemOperResult = 1;
								last;
							} # if
							
							$message = "Waiting to finish $operation $itemName...";
							$self->runMonitor('message' => $message, 'severity' => 4, 'subsystem' => $class, 'status' => 1, 'statusOff' => 1);
						
							sleep $checkInterval;
							
						} # if
						
					} # while
					
				} # if
				
				$message = "Final state of $operation on $itemName...";
				$self->runMonitor('message' => $message, 'severity' => 2, 'subsystem' => $class, 'status' => $itemOperResult);
				
				push(@runItemsResults, $itemOperResult);
				
			} else {
				$message = "No need for $operation on $itemName...";
				$self->runMonitor('message' => $message, 'severity' => 4, 'subsystem' => $class, 'status' => 1, 'statusOff' => 1);
				push(@runItemsResults, 1);
			} # if
			
		} # foreach
		
		# here we are checking if all items were successfuly started
		my %mapped = map { $_ => 1 } @runItemsResults;
		my @uniq = keys %mapped;
		my $size = @uniq;
		
		if($uniq[0] == 1 && $size == 1) {
			$result = 1;
		} # if
		
	} else {
		$result = 1;
	} # if
	
	return $result;
	
} # end sub runStopItems

=item C<sortLevelItems>

Method sortLevelItems sorts items keys according their id, id expresses order in which they should be started

=cut

sub sortLevelItems($) {
	my $self = shift;
	my $items = shift;
	my @sortedKeys = sort {$items->{$a}->{'id'} <=> $items->{$b}->{'id'}} keys %$items;
	return \@sortedKeys;
} # end sub sortLevelItems

=item C<checkDependencies>

Method checkDependencies checks dependencies state for operation and process we want to start/stop (it doesn't start dependencies!)

params:

	dependencies hash ref

	operation (start/stop)
	
	items hash ref - dependencies are normal items in process config, therefore dependencies should be started before dependent process

params:

	$result boolean

=back

=cut

sub checkDependencies($$$) {
	
	my $self = shift;
	my %params = @_;
	my $dependencies = $params{'dependencies'};
	my $operation = $params{'operation'};
	my $items = $params{'items'};
	my $operCodes = $self->{'operCodes'};
	my $config = $self->{'config'};
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $dependencyResults = ();
	my $result = 0;

	# here we are checking if there are some dependencies
	if($dependencies->[0]) {
		
		# foreach dependency we are checking it with check cmd
		foreach my $dependencyName(@$dependencies) {
			
			my $depCheckResultCode = 0;
				
			my $depCheckCmd = $items->{$dependencyName}->{'check'}->{'cmd'};
			my $depCheckCmds = $config->getArray('source' => $items, 'path' => "$dependencyName/check/cmds");
			
			my $depCheckResult = $shell->execCmd('cmdsNeeded' => $depCheckCmds, 'cmd' => $depCheckCmd);
			
			if($depCheckResult->{'returnCode'} != $operCodes->{$operation}) {
				$depCheckResultCode = 1;
			} # if

			# we are pushing result of dependency check to array
			push(@dependencyResults, $depCheckResultCode);

			$message = "Checking of dependency $dependencyName...";
			$self->runMonitor('message' => $message, 'severity' => 5, 'subsystem' => $class, 'status' => $depCheckResultCode);
				
		} # foreach

		# here we are looking if all dependency check were successful
		my %mapped = map { $_ => 1 } @dependencyResults;
		my @uniq = keys %mapped;
		my $size = @uniq;

		if($uniq[0] == 1 && $size == 1) {
			$result = 1;
		} # if
	
	} else {
		$message = "There are no dependencies...";
		$self->runMonitor('message' => $message, 'severity' => 4, 'subsystem' => $class, 'status' => 1, 'statusOff' => 1);
		$result = 1;
	} # if
	
	return $result;
	
} # end sub checkDependencies

=head1 DEPENDENCIES

	SysAdmToolkit::Monitor::Subject
	SysAdmToolkit::Term::Shell
	SysAdmToolkit::File::Config::Xml

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
