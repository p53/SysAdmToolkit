package SysAdmToolkit::Machine::Info::HPUX_1131;

=head1 NAME

SysAdmToolkit::Machine::Info::HPUX_1131 - HP-UX 11.31 specific module for getting basic info about UNIX machine

=head1 SYNOPSIS

	my $machInfo = SysAdmToolkit::Machine::Info::HPUX_1131->new();
										
	my $ram = $machInfo->get('memory');

=head1 DESCRIPTION

Module is HP-UX 11.31 specific module for getiing basic info about machine, 
like operating system, os version, number of cpu, ram

=cut

use base qw/
				SysAdmToolkit::Patterns::Prototype
				SysAdmToolkit::Patterns::Getter
			/;

use SysAdmToolkit::Term::Shell;

=head1 PRIVATE VARIABLES

=over 12

=item machineInfoCmd string

	Property stores command for getting machine info

=cut

my $machineInfoCmd = 'machinfo';

=item confInfoCmd string

	Property stores command for getting configuration info from system

=cut

my $confInfoCmd = 'getconf';

=item bootSettingsCmd string

	Property stores command for getting boot path info from NVRAM persistent storage

=cut

my $bootSettingsCmd = 'setboot';

=item procNumCmd string

	Property stores command for getting info about cpu and cpu cores

=cut

my $procNumCmd = 'mpsched';

=item partitionCmd string

	Property stores command for getting info about npar partitions

=cut

my $partitionCmd = 'parstatus';

=item vparCmd string

	Property stores command for getting info about vpars

=cut

my $vparCmd = 'vparstatus';

=item scanCmd string

	Property stores command for getting info about HW on the machine

=back

=cut

my $scanCmd = 'ioscan';

=head1 METHODS

=over 12

=item C<_init>

Method _init gets and parses all info, module can provide

	maxcores
	mincores
	maxlogicproc
	minlogicproc
	firmwarerev
	fpaswadriverrev
	bmcfirmwarerev
	partition
	vpar
	hwsuppbits
	kernelbits
	memory
	cpufreq
	cpucount
	architecture
	primbootdev
	primbootlunpath
	primboothw
	altbootdev
	altbootlunpath
	altboothw
	model
	nodename
	serial
	idnum
	machidnum
	license
	release

=back

=cut

sub _init() {
	
	my $self = shift;
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $partition = '';
	my $vpar = '';
	
	my $machineInfoString = $shell->execCmd('cmd' => "$machineInfoCmd", 'cmdsNeeded' => [$machineInfoCmd]);
	
	my @machineInfoLines = split("\n", $machineInfoString->{'msg'});
	my @machineInfoLinesClean = @machineInfoLines[0..$#machineInfoLines-2];
	
	my $cpuFrequency = $machineInfoLines[1];
	$cpuFrequency =~ s/.*(\((\d+\.*\d*) (GHz|MHz), \d+\.*\d* MB\))/$2/;
	
	my %machInfo = ();
	
	# parsing output from machinfo command
	foreach my $machineInfoLine(@machineInfoLinesClean) {
		
		if($machineInfoLine =~ /^(.+)\:(.+)$/) {
			
			my $key = $1;
			my $value = $2;
			
			$key =~ s/^\s+//;
			$key =~ s/\s/\_/g;
			$value =~ s/^\s+//;
			$value =~ s/\"//g;
			
			if($key eq 'Memory') {
				$value =~ s/^(\d+).*/$1/;	
			} # if
			
			$machInfo{$key} = $value;
			
		} # if
		
	} # foreach
	
	# checking if hw is partitionable
	my $partitionInfo = $shell->execCmd('cmd' => "$partitionCmd -Mw", 'cmdsNeeded' => [$partitionCmd]);
	
	# if partitionable check if vpars are present
	if($partitionInfo->{'returnCode'}) {
		$partition = $partitionInfo->{'msg'};
		my $vparInfo = $shell->execCmd('cmd' => "$vparCmd -Mw", 'cmdsNeeded' => [$vparCmd]);
		if($vparInfo->{'returnCode'}) {
			$vpar = $vparInfo->{'msg'};
		} # if
	} # if
	
	# getting Os bitness, hw supported bits, cpu count, boot info
	my $kernelBits = $shell->execCmd('cmd' => "$confInfoCmd KERNEL_BITS", 'cmdsNeeded' => [$confInfoCmd]);
	my $hwBits = $shell->execCmd('cmd' => "$confInfoCmd HW_CPU_SUPP_BITS", 'cmdsNeeded' => [$confInfoCmd]);
	my $cpuNumInfo = $shell->execCmd('cmd' => "$procNumCmd -S|grep -i socket", 'cmdsNeeded' => [$procNumCmd, 'grep']);
	my $bootInfo = $shell->execCmd('cmd' => "$bootSettingsCmd|grep ':'", 'cmdsNeeded' => [$bootSettingsCmd, 'grep']);
	
	my @cpuNumLines = split("\n", $cpuNumInfo->{'msg'});
	my $cpuCount = $#cpuNumLines + 1;
	
	my @coresNum = ();
	my @logicalProcNum = ();
	
	foreach my $cpuNumLine(@cpuNumLines) {
		
		my $cores = ($cpuNumLine =~ /(\[)/g);
		my @coreInfo = split(":", $cpuNumLine);
		my $logicalProc = ($coreInfo[1] =~ /(\d+)/g);
		
		push(@coresNum, $cores);
		push(@logicalProcNum, $logicalProc);
		
	} # foreach
	
	my @sortedCoresNum = sort {$a <=> $b} @coresNum;
	my @sortedLogicProcNum = sort{$a <=> $b} @logicalProcNum;
	
	my @bootLines = split("\n", $bootInfo->{'msg'});
	my %bootDevs = ();
	
	foreach my $bootLine(@bootLines) {
		
		$bootLine =~ /(.*)\:(.*)\((.*)\)/;
		my $key = $1;
		my $hwPath = $2;
		my $devPath = $3;
		
		$key =~ s/\s+$//;
		$key =~ s/\s/\_/g;
		$hwPath =~ s/^\s+//;
		$hwPath =~ s/\s+$//;

		$bootDevs{$key . 'hw'} = $hwPath;
		$bootDevs{$key} = $devPath;
		
	} # foreach
	
	my $lunpathPrimInfo;
	my $lunpathAltInfo;
	
	$lunpathPrimInfo = $shell->execCmd('cmd' => "$scanCmd -Nk -m hwpath -H $bootDevs{'Primary_bootpathhw'}|grep 64000", 'cmdsNeeded' => [$scanCmd]);
	
	if($bootDevs{'Alternate_bootpathhw'} ne '') {
		$lunpathAltInfo = $shell->execCmd('cmd' => "$scanCmd -Nk -m hwpath -H $bootDevs{'Alternate_bootpathhw'}|grep 64000", 'cmdsNeeded' => [$scanCmd]);
	} # if
	
	$self->{'maxcores'} = $sortedCoresNum[0];
	$self->{'mincores'} = $sortedCoresNum[$#sortedCoresNum-1];
	$self->{'maxlogicproc'} = $sortedLogicProcNum[0];
	$self->{'minlogicproc'} = $sortedLogicProcNum[$#sortedLogicProcNum-1];
	$self->{'firmwarerev'} = $machInfo{'Firmware_revision'};
	$self->{'fpaswadriverrev'} = $machInfo{'FP_SWA_driver_revision'};
	$self->{'bmcfirmwarerev'} = $machInfo{'BMC_firmware_revision'};
	
	$self->{'partition'} = $partition;
	$self->{'vpar'} = $vpar;
	$self->{'hwsuppbits'} = $hwBits->{'msg'};
	$self->{'kernelbits'} = $kernelBits->{'msg'};
	$self->{'memory'} = $machInfo{'Memory'};
	$self->{'cpufreq'} = $cpuFrequency * 1000;
	$self->{'cpucount'} = $cpuCount;
	$self->{'architecture'} = $machInfo{'Machine'};
	$self->{'primbootdev'} = $bootDevs{'Primary_bootpath'};
	$self->{'primbootlunpath'} = $bootDevs{'Primary_bootpathhw'};
	$self->{'primboothw'} = $lunpathPrimInfo->{'msg'};
	$self->{'altbootdev'} = $bootDevs{'Alternate_bootpath'};
	$self->{'altbootlunpath'} = $bootDevs{'Alternate_bootpathhw'};
	$self->{'altboothw'} = $lunpathAltInfo->{'msg'};
	$self->{'model'} = $machInfo{'Model'};
	$self->{'nodename'} = $machInfo{'Nodename'};
	$self->{'serial'} = $machInfo{'Machine_serial_number'};
	$self->{'idnum'} = $machInfo{'ID_Number'};
	$self->{'machidnum'} = $machInfo{'Machine_ID_number'};
	$self->{'license'} = $machInfo{'Version'};
	$self->{'release'} = $machInfo{'Release'};
	
} # end sub _init

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
