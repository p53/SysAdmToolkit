package SysAdmToolkit::Lvm::Admin::HPUX_1111;

=head1 NAME

SysAdmToolkit::Lvm::Admin::HPUX_1111 - HP-UX 11.11 specific module for getting high level info about LVM on machine

=head1 SYNOPSIS

	my $lvmAdmin = SysAdmToolkit::Lvm::Admin::HPUX_1111->new();
										
	my $bootInfo = $lvmAdmin->getBootInfo();

=head1 DESCRIPTION

Module should help in getting higher level info about LVM on the machine
about lvs, pvs, vgs, VGBRA

=cut

use base qw/
				SysAdmToolkit::Patterns::Prototype
				SysAdmToolkit::Patterns::Getter
			/;

use SysAdmToolkit::Term::Shell;

=head2 PRIVATE PROPERTIES

=over 12

=item lvmBootCmd string

	Property is holding command for getting VGBRA info

=cut

my $lvmBootCmd = 'lvlnboot';

=item vgCmd string

	Property stores command for displaying info about volume group

=cut

my $vgCmd = 'vgdisplay';

=item lvCmd string

	Property stores command for displaying info about logical volume group

=cut

my $lvCmd = 'lvdisplay';

=item pvCmd string

	Property stores command for displaying info about physical volume

=cut

my $pvCmd = 'pvdisplay';

=item pvgFile string

	Property stores file where pvgs are stored
	
=back

=cut

my $pvgFile = '/etc/lvmpvg';

=head1 METHODS

=over 12

=item C<getBootInfo>

Method gets info about lvm configuration for boot, swap, dump space on LVM volumes

return:

	$bootLvmInfo hash ref

	structure is like this:

	{
		'vgname' => {
						boot => {
									lvboot => {
												'primary' => '/dev/dsk/c10t0d1',
												'alternate' => '/dev/dsk/c11t2d3'
												}
								}
					}
		
	}

=back

=cut

sub getBootInfo() {
	
	my $self = shift;
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $bootLvmInfo = {};
	my @bootDisks = ();
	
	my $bootInfo = $shell->execCmd('cmd' => "$lvmBootCmd -v 2>/dev/null|grep /dev", 'cmdsNeeded' => [$lvmBootCmd, 'grep']);
	
	if(!$bootInfo->{'returnCode'}) {
		warn("There are no LVM boot information, LVM can be version 2!\n");	
	} # if
	
	my @bootInfoLines = split("\n", $bootInfo->{'msg'});
	# here we get vgs that have VGBRA, there maybe more than one VG with bootable volumes
	my @bootVgs = ($bootInfo->{'msg'} =~ /Boot Definitions for Volume Group (\/dev\/.*)\:/g);
	# here we get boot disks and rest of lines are boot, swap lvol infos
	my @bootDisksLines = grep {$_ =~ /Boot Disk/} @bootInfoLines;
	my @bootLvsLines = grep {$_ !~ /(Boot Disk)|(Volume Group)/i} @bootInfoLines;
	
	foreach my $line(@bootDisksLines) {
		my @lineParts = split(" ", $line);
		push(@bootDisks, $lineParts[0]);	
	} # foreach
	
	my $index = 0;
	my $currKey = '';
	my $currType = '';
	my $lvolName = '';
	
	foreach my $bootLvsLine(@bootLvsLines) {
		
		my @lineParts = split(" ", $bootLvsLine);
		
		# if there are mirrors for boot volume in lvlnboot they don't have labels, just primary disks have
		# thus in else we are determining mirror disks
		if($bootLvsLine =~ /^(Boot|Root|Swap|Dump):/) {
			
			$currType = lc($1);
			
			# each VG can have just one boot volume so, order of boot, root swap corresponds to order of VG
			if($currType eq 'boot') {
				$currKey = $bootVgs[$index];
				$index++;
			} # if
			
			$bootLvsLine =~ /(\/dev\/d[a-z0-9_\/]+)/;
			$lvolName = $lineParts[1];
			$bootLvmInfo->{$currKey}->{$currType}->{$lvolName}->{'primary'} = $1;
			
		} else {
			
			my $size = 0;
			
			if(defined($bootLvmInfo->{$currKey}->{$currType}->{$lvolName}->{'alt'})) {
				$size = @{$bootLvmInfo->{$currKey}->{$currType}->{$lvolName}->{'alt'}};
			} # if
			
			if(!$size) {
				$bootLvmInfo->{$currKey}->{$currType}->{$lvolName}->{'alt'} = [];
			} # if
			
			if(defined($bootLvmInfo->{$currKey}->{$currType}->{$lvolName}->{'alt'})) {
				$bootLvsLine =~ /(\/dev\/d[a-z0-9_\/]+)/;
				$bootLvmInfo->{$currKey}->{$currType}->{$lvolName}->{'alt'}->[$size] = $1;
			} # if

		} # if

	} # foreach
	
	$bootLvmInfo->{'bootDisks'} = \@bootDisks;
	
	return $bootLvmInfo;
	
} # end sub getBootInfo

sub getVersion() {}
sub getLimits() {}
sub getStatus() {}

sub getVgs() {
	
	my $self = shift;
	my $shell = SysAdmToolkit::Term::Shell->new();
	my @vgs = ();

	my $vgdisplayInfo = $shell->execCmd('cmd' => "$vgCmd|grep -i 'vg name'|awk '{print \$NF}'", 'cmdsNeeded' => [$vgCmd, 'grep', 'awk']);
	
	if(!$vgdisplayInfo->{'returnCode'}) {
		warn("There was some problem getting VG's info: " . $vgdisplayInfo->{'msg'} . "\n");
	} # if
	
	@vgs = split("\n", $vgdisplayInfo->{'msg'});
	
	return \@vgs;
	
} # end sub getVgs

sub getLvs() {
	
	my $self = shift;
	my $shell = SysAdmToolkit::Term::Shell->new();
	my @lvs = ();

	my $lvdisplayInfo = $shell->execCmd('cmd' => "$vgCmd -v|grep -i 'lv name'|awk '{print \$NF}'", 'cmdsNeeded' => [$lvCmd, 'grep', 'awk']);
	
	if(!$lvdisplayInfo->{'returnCode'}) {
		warn("There was some problem getting LV's info: " . $lvdisplayInfo->{'msg'} . "\n");
	} # if
	
	@lvs = split("\n", $lvdisplayInfo->{'msg'});
	
	return \@lvs;
	
} # end sub getLvs

sub getPvs() {
	
	my $self = shift;
	my $shell = SysAdmToolkit::Term::Shell->new();
	my @pvs = ();

	my $pvdisplayInfo = $shell->execCmd('cmd' => "$vgCmd -v|grep -i 'pv name'|awk '{print \$3}'", 'cmdsNeeded' => [$pvCmd, 'grep', 'awk']);
	
	if(!$pvdisplayInfo->{'returnCode'}) {
		warn("There was some problem getting PV's info: " . $pvdisplayInfo->{'msg'} . "\n");
	} # if
	
	@pvs = split("\n", $pvdisplayInfo->{'msg'});
	
	return \@pvs;
	
} # end sub getPvs

sub getPvgs() {
	
	my $self = shift;
	my @pvgs = ();
	my $shell = SysAdmToolkit::Term::Shell->new();
	
	if(-s $pvgFile) {
		my $pvgdisplayInfo = $shell->execCmd('cmd' => "grep '^PVG' $pvgFile|awk '{print \$NF}'", 'cmdsNeeded' => ['grep', 'awk']);
		
		if(!$pvgdisplayInfo->{'returnCode'}) {
			warn("There was some problem getting PVG's info: " . $pvgdisplayInfo->{'msg'} . "\n");
		} # if
		
		@pvgs = split("\n", $pvgdisplayInfo->{'msg'});
		
	} # if
	
	return \@pvgs;
	
} # end sub getPvgs

=head1 DEPENDECIES

	SysAdmToolkit::Patterns::Prototype
	SysAdmToolkit::Patterns::Getter
	SysAdmToolkit::Term::Shell

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
