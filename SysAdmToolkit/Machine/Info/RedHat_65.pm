package SysAdmToolkit::Machine::Info::HPUX_1111;

=head1 NAME

SysAdmToolkit::Machine::Info::HPUX_1111 - HP-UX 11.11 specific module for getting basic info about UNIX machine

=head1 SYNOPSIS

	my $machInfo = SysAdmToolkit::Machine::Info::HPUX_1111->new();
										
	my $ram = $machInfo->get('memory');

=head1 DESCRIPTION

Module is HP-UX 11.11 specific module for getiing basic info about machine, 
like operating system, os version, number of cpu, ram

=cut

use base qw/
				SysAdmToolkit::Patterns::Prototype
				SysAdmToolkit::Patterns::Getter
			/;

use SysAdmToolkit::Term::Shell;
use Sys::Hostname;
use IO::File;

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
	my $memTotal = 0;
	my $kernelBits = 0;
	my $processorsCount = 0;
	my $serial = 0;
	my $machineIdent = 0;
	my $hwBits = 0;
	my $procFreq = 0;
	
	my $moreInfo = $shell->execCmd('cmd' => "$basicInfoCmd -i", 'cmdsNeeded' => [$basicInfoCmd]);
	my $licenseInfo = $shell->execCmd('cmd' => "$basicInfoCmd -o", 'cmdsNeeded' => [$basicInfoCmd]);
	
	my $dmi = SysAdmToolkit::Utility::Dmidecode->new();
	my $processors = $dmi->get(4);
	my $system = $dmi->get(1);
	my $memoryModules = $dmi->get(17);
	
	foreach my $module(@$memoryModules) {
		my $memCapacity = $module->{'MemoryDevice'}->{'Size'};
		$memCapacity =~ s/(\d+)/$1/;
		$memTotal += $memCapacity;
	} # foreach
	
	# getting partition info
	my $partitionInfo = $shell->execCmd('cmd' => "$partitionCmd -w", 'cmdsNeeded' => [$partitionCmd]);
	
	# if hw is partitionable check if there are also vpars
	if($partitionInfo->{'returnCode'}) {
		
		$partition = $partitionInfo->{'msg'};
		$partition =~ s/.*\s+(\d+)\.\s*/$1/;
		
		my $vparInfo = $shell->execCmd('cmd' => "$vparCmd -w", 'cmdsNeeded' => [$vparCmd]);
		if($vparInfo->{'returnCode'}) {
			$vpar = $vparInfo->{'msg'};
			$vpar =~ s/.*\s+(\d+)\.\s*/$1/;
		} # if
		
	} # if
	
	#operating sys bittness
	if( (1<<32) ) {
  		$kernelBits = 64;
	} else {
		$kernelBits = 32;
	} # if

	my @archInfo = split('_', $moreInfo->{'msg'});
	
	# kernel bitness, hw supported bits, machine serial, identification number
	my $hwBits = $archInfo[1];
	my $serial = $system->[0]->{'SerialNumber'};
	my $machineIdent = $system->[0]->{'UUID'};
	
	my $modelInfo = $system->[0]->{'ProductName'};
	my $processorsCount = @$processors;
	
	my $procFreqInfo = $processors->[0]->{'CurrentSpeed'};
	
	$procFreqInfo =~ s/(\d+)\s*$/$1/;
	my $procFreq = $procFreqInfo;

	$fh = IO::File->new();
	
	if($fh->open("< /etc/redhat-release")) {
		my $content = <$fh>;
		$content[0] =~ s/(\d+\.\d+)/$1/;
		$fh->close;
	} # if

	if($fh->open("< /etc/grub.conf")) {
		while(<$fh>) {
			if(/(root=.*?)\s/){
				print $1."\n";
			} # if
		} # while
	} # if
	
	# boot paths - grub
	$self->{'partition'} = $partition;
	$self->{'vpar'} = $vpar;
	$self->{'hwsuppbits'} = $hwBits;
	$self->{'kernelbits'} = $kernelBits;
	$self->{'memory'} = $memTotal;
	$self->{'cpufreq'} = $procFreq;
	$self->{'cpucount'} = $processorsCount;
	$self->{'architecture'} = $archInfo[1];
	$self->{'primbootdev'} = $bootDevs{'Primary_bootpath'};
	$self->{'primboothw'} = $bootDevs{'Primary_bootpathhw'};
	$self->{'altbootdev'} = $bootDevs{'Alternate_bootpath'};
	$self->{'altboothw'} = $bootDevs{'Alternate_bootpathhw'};
	$self->{'model'} = $modelInfo;
	$self->{'nodename'} = hostname;
	$self->{'serial'} = $serial;
	$self->{'idnum'} = '';
	$self->{'machidnum'} = $machineIdent;
	$self->{'license'} = $licenseInfo;
	$self->{'release'} = $content[0];
	
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
