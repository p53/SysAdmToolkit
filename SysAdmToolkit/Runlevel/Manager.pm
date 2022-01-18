package SysAdmToolkit::Runlevel::Manager;

=head1 NAME

SysAdmToolkit::Runlevel::Manager - module helps managing runlevels

=head1 SYNOPSIS

		my $runLevelManager = SysAdmToolkit::Runlevel::Manager->new('runLevels' => {});
		my $addScriptResult = $runLevelManager->addStartScript(
																	'file' => $bootUpParams->{'scriptSource'},
																	'owner' => $bootUpParams->{'owner'},
																	'number' => $bootUpParams->{'number'},
																	'runLevel' => $bootUpParams->{'runLevel'},
																	'perms' => $bootUpParams->{'perms'},
																	'name' => $bootUpParams->{'name'}
																);

=cut

use base 'SysAdmToolkit::Monitor::Subject';

use SysAdmToolkit::Term::Shell;

=head1 PRIVATE VARIABLES

=over 12

=item class string

Variable stores name of the class

=back

=cut

my $class = __PACKAGE__;

=head1 METHODS

=over 12

=item C<_init>

Method _init initializies object, properties

=cut

sub _init() {
	
	my $self = shift;
	$self->SUPER::_init(@_);
	my %params = @_;
	
	$self->{'runLevelStatus'} = 'who';
	$self->{'runLevelUtil'} = 'init';
	$self->{'levelKey'} = 'runlevel';
	$self->{'allowedLevels'} = [0, 1, 2, 3, 'S'];
	$self->{'runLevels'} = $params{'runLevels'};
	$self->{'bootScriptsFolder'} = '/sbin/init.d/';
	
	if(!$params{'runLevels'}) {
		die "You must supply runLevels parameter with runlevels settings!\n";
	} # if
	
} # end sub _init

=item C<changeRunLevel>

Method changeRunLevel should change runlevel of the machine and start/stop processes in the configuration

Note: It is not fully implemented yet

=cut

sub changeRunLevel($) {
	
	my $self = shift;
	my $changeTo = shift;
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $changeResult = 0;
	
	my $runLevelInfo = $self->getCurrentLevelInfo();
	
	my $message = "Changing run level from " . $runLevelInfo->{'current'} . ' to ' . $changeTo . '...';
	
	$self->runMonitor('message' => $message, 'severity' => 4, 'subsystem' => $class, 'status' => 1, 'statusOff' => 1);
	
	if($changeTo == $runLevelInfo->{'current'}) {
		$changeResult = 0;
	} else {
		
		$message = "Starting executing stop items for runlevel " . $runLevelInfo->{'current'} . '...';
		$self->runMonitor('message' => $message, 'severity' => 4, 'subsystem' => $class, 'status' => 1, 'statusOff' => 1);
		
		my $runStops = $self->runItems('operation' => 'stop', 'level' => $runLevelInfo->{'current'});
		
		$message = "Executing stop items for runlevel " . $runLevelInfo->{'current'} . '...';
		$self->runMonitor('message' => $message, 'severity' => 1, 'subsystem' => $class, 'status' => $runStops);
		
		if($runStops) {

			$message = "Executing OS run level command  " . $self->{'runLevelUtil'} . " $changeTo...";
			$self->runMonitor('message' => $message, 'severity' => 4, 'subsystem' => $class, 'status' => 1, 'statusOff' => 1);
			
			my $initResult = $shell->exec($self->{'runLevelUtil'} . " $changeTo");
			
			$message = "Run level change command " . $self->{'runLevelUtil'} . " $changeTo...";
			$self->runMonitor('message' => $message, 'severity' => 1, 'subsystem' => $class, 'status' => $initResult->{'returnCode'});
			
			if($initResult->{'returnCode'}) {
				
				my $changeLevelStatus = $self->checkLevelChange($runLevelInfo);
				
				$message = "Change of runlevel from  " . $runLevelInfo->{'current'} . "  to $changeTo...";
				$self->runMonitor('message' => $message, 'severity' => 1, 'subsystem' => $class, 'status' => $changeLevelStatus);
			
				my $runStarts = 0;
		
				if($runStops && $changeLevelStatus) {
					$message = "Starting executing start items for runlevel " . $changeTo . '...';
					$self->runMonitor('message' => $message, 'severity' => 4, 'subsystem' => $class, 'status' => 1, 'statusOff' => 1);
					
					$runStarts = $self->runItems('operation' => 'start', 'level' => $changeTo);
					
					$message = "Executing start items for runlevel " . $changeTo . '...';
					$self->runMonitor('message' => $message, 'severity' => 1, 'subsystem' => $class, 'status' => $runStarts);
				} # if
				
				$changeResult = $runStops & $runStarts;
				
			} # if
		
		} # if
		
	} # if
	
	return $changeResult;
	
} # end sub changeRunLevel

=item C<getCurrentLevelInfo>

Method getCurrentLevelInfo gets current runlevel, number of previous enterings of this runlevel and previous runlevel

return:

	$runLevelInfo hash ref

=cut

sub getCurrentLevelInfo() {
	
	my $self = shift;
	my $shell = SysAdmToolkit::Term::Shell->new();
	
	my $result = $shell->execCmd('cmd' => 'who -r', 'cmdsNeeded' => ['who']);

	my @whoResult = split(" ", $result->{'msg'});
	my @lastFields = @whoResult[-3..-1];

	my $runLevelInfo = {
							'current' => $lastFields[0],
							'numOfPrevEnterings' => $lastFields[1],
							'previous' => $lastFields[2]
						};
						
	return $runLevelInfo;
	
} # end sub getCurrentLevel

=item C<runItems>

Method runItems should start/stop processes for runlevel

Note: It is not fully implemented yet

=cut

sub runItems($$) {
	
	my $self = shift;
	my %params = @_;
	my $level = $params{'level'};
	my $operation = $params{'operation'};
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $fullLevelKey = $self->{'levelKey'} . $level;
	my $levelItems = $self->{'runLevels'}->{$fullLevelKey}->{$operation}->{'item'};
	my $checkInterval = $self->{'runLevels'}->{'runLevelCheckInterval'};
	my $operCodes = {'stop' => 1, 'start' => 0};
	my @runItemsResults = ();
	my $result = 0;
	
	if($operation ne 'stop' && $operation ne 'start') {
		die "Permitted operations are just stop and start!\n";	
	} # if
	
	my $sortedItemsKeys = $self->sortLevelItems($levelItems);
	
	foreach my $itemName(@$sortedItemsKeys) {
		
		my $itemOperResult = 0;
		my $cmdsNeeded = $levelItems->{$itemName}->{'check'}->{'cmds'};
		my $checkCmd = $levelItems->{$itemName}->{'check'}->{'cmd'};
		my $operationCmd = $levelItems->{$itemName}->{$operation . 'Cmd'};
		my $operationCmds = $levelItems->{$itemName}->{$operation . 'Cmds'};
		my $timeWait = $levelItems->{$itemName}->{'timewait'};
			
		my $checkResult = $shell->execCmd('cmdsNeeded' => $cmdsNeeded, 'cmd' => $checkCmd);
		
		if($checkResult->{'returnCode'} == $operCodes->{$operation}) {
			
			$message = "Starting executing $operation on $itemName...";
			$self->runMonitor('message' => $message, 'severity' => 4, 'subsystem' => $class, 'status' => 1, 'statusOff' => 1);
					
			my $operationResult = $shell->execCmd('cmdsNeeded' => $operationCmds, 'cmd' => $operationCmd);
			
			$message = "Executing $operation on $itemName...";
			$self->runMonitor('message' => $message, 'severity' => 1, 'subsystem' => $class, 'status' => 1, 'statusOff' => 1);
			
			my $stopTime = time() + $timeWait;
			
			if($operationResult) {
				
				while(time() < $stopTime) {
			
					if(!time() % $checkInterval) {
						
						my $checkTimeResult = $shell->execCmd('cmdsNeeded' => $cmdsNeeded, 'cmd' => $checkCmd);
						
						if(!($checkTimeResult->{'returnCode'} == $operCodes->{$operation})) {
							$itemOperResult = 1;
							last;
						} # if
						
						$message = "Waiting to finish $operation $itemName...";
						$self->runMonitor('message' => $message, 'severity' => 5, 'subsystem' => $class, 'status' => 1, 'statusOff' => 1);
					
					} # if
				} # while
				
			} # if
			
			$message = "Final state of $operation on $itemName...";
			$self->runMonitor('message' => $message, 'severity' => 1, 'subsystem' => $class, 'status' => 1, 'statusOff' => 1);
			
			push(@runItemsResults, $itemOperResult);
			
		} else {
			$message = "No need for $operation on $itemName...";
			$self->runMonitor('message' => $message, 'severity' => 1, 'subsystem' => $class, 'status' => 1, 'statusOff' => 1);
			push(@runItemsResults, 1);
		} # if
		
	} # foreach
	
	my %mapped = map { $_ => 1 } @runItemsResult;
	my @uniq = keys %mapped;
	
	if($uniq[0] == 1 && $#uniq == 1) {
		$result = 1;
	} # if
	
	return $result;
	
} # end sub runStopItems

=item C<checkLevelChange>

Method checkLevelChange checks if there was transition of runlevels

params:

	$oldLevelInfo int - old runlevel number

return:

	$levelChangeResult boolean

=cut

sub checkLevelChange($) {
	
	my $self = shift;
	my $oldLevelInfo = shift;
	my $changeTime = $self->{'runLevels'}->{'timewait'};
	my $checkInterval = $self->{'runLevels'}->{'runLevelCheckInterval'};
	my $stopTime = time() + $changeTime;
	my $levelChangeResult = 0;
	
	while(time() < $stopTime) {
		
		if(!time() % $checkInterval) {
			
			my $currentLevelInfo = $self->getCurrentLevelInfo();
			
			if($currentLevelInfo->{'current'} != $oldLevelInfo->{'current'}) {
				$levelChangeResult = 1;
				last;
			} # if
			
			my $message = "Waiting for runlevel change...";
			$self->runMonitor('message' => $message, 'severity' => 5, 'subsystem' => $class, 'status' => 1, 'statusOff' => 1);
			
		} # if
		
	} # while
	
	return $levelChangeResult;
	
} # end sub checkLevelChange

=item C<sortLevelItems>

Method sortLevelItems sorts items keys according their id and returns keys

params:

	$items hash ref

return:

	array ref

=cut

sub sortLevelItems($) {
	my $self = shift;
	my $items = shift;
	my @sortedKeys = sort {$items->{$a}->{'id'} <=> $items->{$b}->{'id'}} keys %$items;
	return \@sortedKeys;
} # end sub sortLevelItems

=item C<addStartScript>

Method addStartScript adds startup script to appropriate runlevel folder,sets permissions makes link

params:

	file string - path from where script should be copied to runlevel folder
	owner - owner of the startup script
	number - it is number of startup script in the runlevel folder
	runLevel - runlevel to which script should be added
	perm - permissions of runlevel script
	name - name under which should be script in ther runlevels folder

return:

	$result boolean

=cut

sub addStartScript($$$) {
	
	my $self = shift;
	my %params = @_;
	my $filePath = $params{'file'};
	my $owner = $params{'owner'};
	my $number = $params{'number'};
	my $runLevel = $params{'runLevel'};
	my $perms = $params{'perms'};
	my $name = $params{'name'};
	my $result = 0;
	
	my $runLevelFolder = "/sbin/rc$runLevel.d/";
	my $bootScriptsFolder = $self->{'bootScriptsFolder'};
	my $runLevelScriptPath = $runLevelFolder . "S$number$name";
	
	my $shell = SysAdmToolkit::Term::Shell->new();
		
	my @pathParts = split('/', $filePath);
	my $fileName = pop(@pathParts);
	my $bootScriptPath = $bootScriptsFolder . $fileName;
	
	my $resultMsg;
	
	if(-f $filePath) {
		
		$result = 1;
		
		# copying script from source file to init scripts location (/sbin/init.d in case of HP-UX)	
		my $copyResult = $shell->execCmd('cmd'=> "cp $filePath $bootScriptPath", 'cmdsNeeded' => ['cp']);
		
		if(!$copyResult->{'returnCode'}) {
			$resultMsg = $copyResult->{'msg'};
			$result = 0;
		} # if
		
		# setting permissions on script
		my $permResult = $shell->execCmd('cmd' => "chmod $perms $bootScriptPath", 'cmdsNeeded' => ['chmod']);
			
		if(!$permResult->{'returnCode'}) {
			$resultMsg = $permResult->{'msg'};
			$result = 0;
		} # if
		
		# setting owner on script
		my $ownerResult = $shell->execCmd('cmd' => "chown $owner $bootScriptPath", 'cmdsNeeded' => ['chown']);
		
		if(!$ownerResult->{'returnCode'}) {
			$resultMsg = $ownerResult->{'msg'};
			$result = 0;
		} # if
				
		if(-f $runLevelScriptPath) {
			$resultMsg = "Start script $runLevelScriptPath already exists!";
			$result = 0;
		} # if
		
		# making link from runlevel folder to init scrip location (/sbin/rc3.d/S32lala -> /sbin/init.d/lalu)
		my $linkResult = $shell->execCmd('cmd' => "ln -s $bootScriptPath $runLevelScriptPath", 'cmdsNeeded' => ['ls']);
		
		if(!$linkResult->{'returnCode'}) {
			$resultMsg = $linkResult->{'msg'};
			$result = 0;
		} # if
		
	} else {
		$resultMsg = "File $filePath does not exist!";
	} # if
	
	$message = "Setting up of $filePath as boot script $bootScriptPath...";
	$self->runMonitor('message' => $message, 'severity' => 2, 'subsystem' => $class, 'status' => $result);

	if(!$result) {
		$message = "Error message is: " . $resultMsg;
		$self->runMonitor('message' => $message, 'severity' => 5, 'subsystem' => $class, 'status' => $result);
	} # if
				
	return $result;
	
} # end sub addScriptFromFile

=item C<isAllowedLevel>

Method isAllowedLevel checks if target level is in allowed levels

params:

	$level int

return:

	$presence int

=back

=cut

sub isAllowedLevel($) {
	my $self = shift;
	my $level = shift;
	my $allowedLevels = $self->{'allowedLevels'};
	my $presence = grep($_ == $level, @$allowedLevels);
	return $presence;
} # end sub isAllowedLevel

=head1 DEPENDENCIES

	SysAdmToolkit::Monitor::Subject
	SysAdmToolkit::Term::Shell

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
