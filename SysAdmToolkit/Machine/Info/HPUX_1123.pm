package SysAdmToolkit::Machine::Info::HPUX_1123;

=head1 NAME

SysAdmToolkit::Machine::Info::HPUX_1123 - HP-UX 11.23 specific module for getting basic info about UNIX machine

=head1 SYNOPSIS

	my $machInfo = SysAdmToolkit::Machine::Info::HPUX_1123->new();
										
	my $ram = $machInfo->get('memory');

=head1 DESCRIPTION

Module is HP-UX 11.23 specific module for getiing basic info about machine, 
like operating system, os version, number of cpu, ram

=cut

use base qw/
				SysAdmToolkit::Patterns::Prototype
				SysAdmToolkit::Patterns::Getter
			/;

use SysAdmToolkit::Term::Shell;

=head1 PRIVATE VARIABLES

=over 12

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

=item modelCmd string

	Property stores command for getting model info

=cut

my $modelCmd = 'model';

=item adb string

	Property stores command for debugger

=cut

my $debugger = 'adb';

=item basicInfoCmd string

	Property stores command for getting os name, version, revision

=cut

my $basicInfoCmd = 'uname';

=item kernelLocation string

	Property stores location of HP-UX kernel

=cut

my $kernelLocation = '/stand/vmunix';

=item memDev string

	Property stores device file for memory access

=cut

my $memDev = '/dev/kmem';

=item partitionCmd string

	Property stores command for getting info about npar partitions

=cut

my $partitionCmd = 'parstatus';

=item vparCmd string

	Property stores command for getting info about vpars

=back

=cut

my $vparCmd = 'vparstatus';

=head1 METHODS

=over 12

=item C<_init>

Method _init gets and parses all info, module can provide

	partition
	vpar
	hwsuppbits
	kernelbits
	memory
	cpufreq
	cpucount
	architecture
	primbootdev
	primboothw
	altbootdev
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
	
	my $moreInfo = $shell->execCmd('cmd' => "$basicInfoCmd -mnrsi", 'cmdsNeeded' => [$basicInfoCmd]);
	my $licenseInfo = $shell->execCmd('cmd' => "$basicInfoCmd -vl", 'cmdsNeeded' => [$basicInfoCmd]);
	
	my @hostInfo = split(" ", $moreInfo->{'msg'});
	
	# getting partition info
	my $partitionInfo = $shell->execCmd('cmd' => "$partitionCmd -Mw", 'cmdsNeeded' => [$partitionCmd]);
	
	# if hw is partitionable check if there are also vpars
	if($partitionInfo->{'returnCode'}) {
		$partition = $partitionInfo->{'msg'};
		my $vparInfo = $shell->execCmd('cmd' => "$vparCmd -Mw", 'cmdsNeeded' => [$vparCmd]);
		if($vparInfo->{'returnCode'}) {
			$vpar = $vparInfo->{'msg'};
		} # if
	} # if
	
	# kernel bitness, hw supported bits, machine serial, identification number
	my $kernelBits = $shell->execCmd('cmd' => "$confInfoCmd KERNEL_BITS", 'cmdsNeeded' => [$confInfoCmd]);
	my $hwBits = $shell->execCmd('cmd' => "$confInfoCmd HW_CPU_SUPP_BITS", 'cmdsNeeded' => [$confInfoCmd]);
	my $serial = $shell->execCmd('cmd' => "$confInfoCmd MACHINE_SERIAL", 'cmdsNeeded' => [$confInfoCmd]);
	my $machineIdent = $shell->execCmd('cmd' => "$confInfoCmd MACHINE_IDENT", 'cmdsNeeded' => [$confInfoCmd]);
	
	my $modelInfo = $shell->execCmd('cmd' => "$modelCmd", 'cmdsNeeded' => [$modelCmd]);
	my $procCountInfo = $shell->execCmd('cmd' => "$procNumCmd -s", 'cmdsNeeded' => [$procNumCmd]);
	
	$procCountInfo->{'msg'} =~ /Processor Count\s*:\s*(\d+)\s*/;
	my $procNum = $1;
	
	my $bootInfo = $shell->execCmd('cmd' => "$bootSettingsCmd|grep ':'", 'cmdsNeeded' => [$bootSettingsCmd, 'grep']);
	
	my @bootLines = split("\n", $bootInfo->{'msg'});
	my %bootDevs = ();
	
	foreach my $bootLine(@bootLines) {
		
		$bootLine =~ /(.*)\:(.*)/;
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
	
	my $debuggerOption = '';
	
	if($hostInfo[3] eq 'ia64') {
		$debuggerOption = '-o';
	} # if
	
	my $procFreqCmd = "echo 'itick_per_tick/D' | $debugger $debuggerOption $kernelLocation $memDev | tail -1";
	my $memoryCmd = "echo 'phys_mem_pages/2D' | $debugger $debuggerOption $kernelLocation $memDev | tail -1";
	
	my $procFreqInfo = $shell->execCmd('cmd' => $procFreqCmd, 'cmdsNeeded' => [$debugger, 'echo', 'tail']);
	my $memInfo = $shell->execCmd('cmd' => $memoryCmd, 'cmdsNeeded' => [$debugger, 'echo', 'tail']);
	
	my $procFreqString = $procFreqInfo->{'msg'};
	$procFreqString =~ s/.*?(\d+)\s+$/$1/;
	my $procFreq = $procFreqString / 10000;
	
	my $memoryString = $memInfo->{'msg'};
	$memoryString =~ s/.*?(\d+)\s+$/$1/;
	$memoryMB = $memoryString/256;
	
	$self->{'partition'} = $partition;
	$self->{'vpar'} = $vpar;
	$self->{'hwsuppbits'} = $hwBits->{'msg'};
	$self->{'kernelbits'} = $kernelBits->{'msg'};
	$self->{'memory'} = $memoryMB;
	$self->{'cpufreq'} = $procFreq;
	$self->{'cpucount'} = $procNum;
	$self->{'architecture'} = $hostInfo[3];
	$self->{'primbootdev'} = $bootDevs{'Primary_bootpath'};
	$self->{'primboothw'} = $bootDevs{'Primary_bootpathhw'};
	$self->{'altbootdev'} = $bootDevs{'Alternate_bootpath'};
	$self->{'altboothw'} = $bootDevs{'Alternate_bootpathhw'};
	$self->{'model'} = $modelInfo->{'msg'};
	$self->{'nodename'} = $hostInfo[1];
	$self->{'serial'} = $serial->{'msg'};
	$self->{'idnum'} = $hostInfo[4];
	$self->{'machidnum'} = $machineIdent->{'msg'};
	$self->{'license'} = $licenseInfo->{'msg'};
	$self->{'release'} = $hostInfo[0] . " " . $hostInfo[2];
	
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
