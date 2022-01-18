package SysAdmToolkit::Lvm::VolumeGroup::HPUX_1111;

=head1 NAME

SysAdmToolkit::Lvm::VolumeGroup::HPUX_1111; - OS and version specific module for getting info aboul LVM volume group

=head1 SYNOPSIS

	my $vg = SysAdmToolkit::Lvm::VolumeGroup::HPUX_1111->new('vg' => 'vgroot');
										
	my $vgInfo = $vg->get('maxpv');

=head1 DESCRIPTION

Module is aimed at getting info about volume group on HP-UX 11.11

=cut

use base qw/
				SysAdmToolkit::Patterns::Prototype
				SysAdmToolkit::Patterns::Getter
				SysAdmToolkit::Patterns::CmdBindedSetter
			/;

use SysAdmToolkit::Lvm::LogicalVolume;
use SysAdmToolkit::Lvm::PhysicalVolume::HPUX_1111;
use SysAdmToolkit::Lvm::Register;
use SysAdmToolkit::Term::Shell;
use SysAdmToolkit::Utility::Array;
use File::stat;
use File::Path qw(rmtree);

=head1 PRIVATE PROPERTIES

=over 12

=item vgCmd string

	Property stores command for displaying info about volume group

=cut

my $vgCmd = 'vgdisplay';

=item vgCreateCmd string

	Property stores command for creating volume group

=cut

my $vgCreateCmd = 'vgcreate';

=item vgRemoveCmd string

	Property stores command for removing volume group

=cut

my $vgRemoveCmd = 'vgremove';

=item vgReduceCmd string

	Property stores command for reducing volume group

=cut

my $vgReduceCmd = 'vgreduce';

=item vgExtendCmd string

	Property stores command for extending volume group

=cut

my $vgExtendCmd = 'vgextend';

=item vgCreateDevFileCmd string

	Property stores command for creating volume group device file

=cut

my $vgCreateDevFileCmd = 'mknod';

=item basicProperties array

	Property stores properties of volume group which are available to get

	vgname
	access
	status
	maxlv
	curlv
	openlv
	maxpv
	curpv
	actpv
	maxpeperpv
	vgda
	pesize
	totalpe
	allocpe
	freepe
	totalpvg
	sparepvs
	spareusedpvs
	vgversion
	vgmaxsize
	vgmaxextents

=back

=cut

my @basicProperties = qw/
							vgname
							access
							status
							maxlv
							curlv
							openlv
							maxpv
							curpv
							actpv
							maxpeperpv
							vgda
							pesize
							totalpe
							allocpe
							freepe
							totalpvg
							sparepvs
							spareusedpvs
							vgversion
							vgmaxsize
							vgmaxextents
						/;

=item changeCmd string

	Property stores command for changing Vg, this is needed for setting
	properties
	
=cut

our $changeCmd = 'vgchange';

our $settable = {
					'status' => {'cmd' => "-a", 'verify' => 'y|n|e|s|r'},
					'cluster' => {'cmd' => "-c", 'verify' => 'y|n'},
					'sharable' => {'cmd' => "-S", 'verify' => 'y|n'},
				};
				
our $createParams = {
						'pesize' => '-s',
						'maxlvs' => '-l',
						'maxpvs' => '-p',
						'maxpes' => '-e'
					};
				
=head1 METHODS

=over 12

=item C<_init>

Method _init initializies object and gets all info about volume group

=back

=cut

sub _init() {
	
	my $self = shift;
	my %params = @_;
	my $shell = SysAdmToolkit::Term::Shell->new();
		
	if(!($params{'vg'})) {
		die "You must specify vg parameter!";	
	} # if
	
	my $vgPath = $params{'vg'};
	
	# we are getting info about VG, about LVS in VG and about PVS in VG
	my $vgdisplayCmd = "$vgCmd $vgPath|grep -v '\\-\\-\\-'|awk '{print \$NF}'";
	my $vgLvInfoCmd = "$vgCmd -v $vgPath|grep 'LV Name'|awk '{print \$NF}'";
	my $vgPvInfoCmd = "$vgCmd -v $vgPath|grep 'PV Name'|awk '{print \$3}'";
	
	my $vgdisplayInfo = $shell->execCmd('cmd' => $vgdisplayCmd, 'cmdsNeeded' => [$vgCmd, 'grep', 'awk']);
	my $vgLvInfo = $shell->execCmd('cmd' => $vgLvInfoCmd, 'cmdsNeeded' => [$vgCmd, 'grep', 'awk']);
	my $vgPvInfo = $shell->execCmd('cmd' => $vgPvInfoCmd, 'cmdsNeeded' => [$vgCmd, 'grep', 'awk']);
	
	if(!$vgdisplayInfo->{'returnCode'}) {
		warn("There was some problem getting VG info: " . $vgdisplayInfo->{'msg'} . "\n");
	} # if
	
	my @vgInfo = split("\n", $vgdisplayInfo->{'msg'});
	my @vgLvs = split("\n", $vgLvInfo->{'msg'});
	my @vgPvs = split("\n", $vgPvInfo->{'msg'});
	
	foreach my $index(0..$#basicProperties) {
		$self->{$basicProperties[$index]} = $vgInfo[$index];
	} # foreach
	
	$self->{'changedDevice'} = $self->{'vg'};
	$self->{'pvs'} = \@vgPvs;
	$self->{'lvs'} = \@vgLvs;
	
} # end sub _init

sub vgSync() {}


=item C<vgCreate>

Method vgCreate creates volume group, it is static method

@param vgname string - is name of new vg in the form vgempty not /dev/vgempty
@param pvs array ref - is array of volume group pvs

@return boolean

=cut

sub vgCreate() {
	
	my $self = shift;
	my %params = @_;
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $pvs = $params{'pvs'};
	my $vgname = $params{'vgname'};
	my $class = ref($self) || $self;
	my $size = @$pvs;
	
	no strict 'refs';
	
	my $variable = $class . '::createParams';
	my $createParams = $$variable;
	my $vgCreateParams = '';
	
	for my $createParam(keys %$createParams) {
		if(exists($params{$createParam})) {
			$vgCreateParams .= $createParams->{$createParam} . ' ' . $params{$createParam} . ' ';
		} # if
	} # for
	
	if(!$vgname) {
		die "You need to provide name fo new VG!\n";
	} # if
	
	if(-d "/dev/$vgname") {
		die "There already exists directory /dev/$vgname !\n";
	} # if
	
	if(!$pvs || ($size == 0)) {
		die "You didn't supply pvs!\n";
	} # if
	
	my @vgGroupFiles = glob("/dev/*/group");
	
	my @hexMinors = map {$self->getVgMajMin('vggroupfile' => $_)->{'minor'}} @vgGroupFiles;
	my @decCurrentMinors = map{hex($_)} @hexMinors;
	my @possibleMinors = (0..255);
	my $freeDecMinors = SysAdmToolkit::Utility::Array->diff(\@possibleMinors, \@decCurrentMinors);
	my @sortedFreeDecMinors = sort{$a <=> $b} @$freeDecMinors;
	my $firstFreeDecMinor = shift(@sortedFreeDecMinors);
	my $firstFreeHexMinor = sprintf("%x", $firstFreeDecMinor);
	
	my $newHexMinorDev = $self->createVgMinorDev('hexminor' => $firstFreeHexMinor);
	
	mkdir "/dev/$vgname", 0755;
	
	my $vgCreateDevFileInfo = $shell->execCmd('cmd' => "$vgCreateDevFileCmd /dev/$vgname/group c 64 $newHexMinorDev", 'cmdsNeeded' => [$vgCreateDevFileCmd]);
	
	my $vgPvs = join(' ', @$pvs);
	
	$vgCreateInfo = $shell->execCmd('cmd' => "$vgCreateCmd $vgCreateParams $vgname $vgPvs", 'cmdsNeeded' => [$vgCreateCmd]);
	
	if(!$vgCreateInfo->{'returnCode'}) {
		die("There was some problem while creating VG " . $vgCreateInfo->{'msg'} . "\n");
	} # if
	
	my $register = SysAdmToolkit::Lvm::Register->new();
	$register->{'vgs'}->{"/dev/$vgname"} = 1;
	
	foreach my $pv(@$pvs){
			$register->{'pvs'}->{$pv} = 1;
	} # foreach
		
	return $vgCreateInfo->{'returnCode'};
	
} # end sub vgCreate

=item C<vgRemove>

Method vgRemove is removing Volume group, object method

@return boolean

=cut

sub vgRemove() {
	
	my $self = shift;
	my $vgname = $self->{'vgname'};
	my $pvs = $self->{'pvs'};
	my $lvs = $self->{'lvs'};
	my $lastPv = pop(@$pvs);
	my $size = @$pvs;
	my $shell = SysAdmToolkit::Term::Shell->new();
	
	if(!$vgname) {
		die "You need to provide VG name!\n";
	} else {
		
		my $lvClass = SysAdmToolkit::Lvm::LogicalVolume->getClass('os' => $self->{'os'}, 'ver' => $self->{'ver'});
		
		my $lvCount = @$lvs;
		
		if($lvCount > 0) {
			my $lvBatchRemoveInfo = $lvClass->lvBatchRemove('lvs' => $lvs);
		} # if
		
		if($size > 0) {
			$self->vgReduce('pvs' => $pvs);
		} # if
	
		$vgRemoveInfo = $shell->execCmd('cmd' => "$vgRemoveCmd " . $vgname, 'cmdsNeeded' => [$vgRemoveCmd]);
		
		if(!$vgRemoveInfo->{'returnCode'}) {
			die("There was some problem while removing VG " . $vgRemoveInfo->{'msg'} . "\n");
		} # if
		
		if(-d $vgname) {
			rmtree("$vgname") or die "Cannot rmtree $vgname $!";
		} # if
		
		my $register = SysAdmToolkit::Lvm::Register->new();
		delete $register->{'vgs'}->{$vgname};

		foreach my $pv(@$pvs){
			delete $register->{'pvs'}->{$pv};
		} # foreach
		
		delete $register->{'pvs'}->{$lastPv};
	
	} # if
	
	for my $objProp(keys %$self) {
		$self->{$objProp} = undef;
	} # for
	
	return $vgRemoveInfo->{'returnCode'};
	
} # end sub vgRemove

=item C<vgExtend>

Method vgExtend is extending volume group

@param pvs array ref - array of pvs, which are added to volume group, should be full PV device names

@return boolean

=cut

sub vgExtend() {
	
	my $self = shift;
	my %params = @_;
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $pvs = $params{'pvs'};
	my $vgname = $self->{'vgname'};
	
	my $vgPvs = join(' ', @$pvs);
	
	$vgExtendInfo = $shell->execCmd('cmd' => "$vgExtendCmd $vgname $vgPvs", 'cmdsNeeded' => [$vgExtendCmd]);
	
	if(!$vgExtendInfo->{'returnCode'}) {
		die("There was some problem while extending VG " . $vgExtendInfo->{'msg'} . "\n");
	} # if
	
	my $register = SysAdmToolkit::Lvm::Register->new();

	foreach my $pv(@$pvs){
		$register->{'pvs'}->{$pv} = 1;
	} # foreach
	
	$self->_init((%$self));
	
	return $vgExtendInfo->{'returnCode'};
	
} # end sub vgExtend

=item C<vgReduce>

Method vgReduce removes pvs from volume group

@param pvs array ref - array of pvs to be removed from volume group, should be full PV device files

@return boolean

=cut

sub vgReduce() {
	
	my $self = shift;
	my %params = @_;
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $pvs = $params{'pvs'};
	my $size = @$pvs;
	my $vgname = $self->{'vgname'};
	
	if(!$vgname) {
		die "You need to provide name fo new VG!\n";
	} # if
	
	if(!$pvs || ($size == 0)) {
		die "You didn't supply pvs!\n";
	} # if
	
	my $vgPvs = join(' ', @$pvs);
	
	$vgReduceInfo = $shell->execCmd('cmd' => "$vgReduceCmd $vgname $vgPvs", 'cmdsNeeded' => [$vgReduceCmd]);
	
	if(!$vgReduceInfo->{'returnCode'}) {
		die("There was some problem while reducing VG " . $vgReduceInfo->{'msg'} . "\n");
	} # if
	
	my $register = SysAdmToolkit::Lvm::Register->new();

	foreach my $pv(@$pvs){
		delete $register->{'pvs'}->{$pv};
	} # foreach
	
	$self->_init((%$self));
	
	return $vgReduceInfo->{'returnCode'};
	
} # end sub vgReduce

=item C<lvCreate>

Method lvCreate creates LV in volume group, this method should be used to properly update volume groups lvs

@return boolean

=cut

sub lvCreate() {
	
	my $self = shift;
	my %params = @_;
	
	$params{'vgname'} = $self->{'vgname'};
	
	my $lvClass = SysAdmToolkit::Lvm::LogicalVolume->getClass('os' => $self->{'os'}, 'ver' => $self->{'ver'});
	my $lvCreateInfo = $lvClass->lvCreate(%params);
	
	if($params{'lvname'}) {
		my $lvname = $params{'lvname'};
		my $vgname = $params{'vgname'};
		my $lvs = $self->{'lvs'};
		push(@$lvs, "$vgname/$lvname");
	} else {
		$self->_init();	
	} # if
		
	return $lvCreateInfo;
	
} # end sub lvCreate

sub lvRemove() {
	
	my $self = shift;
	my %params = @_;
	my $lvObj = $params{'lvObj'};
	
	$lvObj->lvRemove();
	
	$self->_init((%$self));
	
} # end sub lvRemove

sub lvBatchRemove() {
	
	my $self = shift;
	my %params = @_;
	$params{'vg'} = $self->{'vg'};
	my $lvClass = $params{'lvClass'};
	
	$lvClass->lvBatchRemove(%params);
	
	$self->_init((%$self));
	
} # end sub lvBatchRemove

sub splitLvol($) {
	
	my $self = shift;
	my %params = @_;
	my $suffix = $params{'suffix'};
	my $lvObj = $params{'lvObj'};
	
	$lvObj->splitLvol($suffix);
	
	$self->_init((%$self));
	
} # end sub splitLvol

sub mergeLvol() {
	
	my $self = shift;
	my %params = @_;
	my $suffix = $params{'suffix'};
	my $lvObj = $params{'lvObj'};
	
	$lvObj->mergeLvol($suffix);
	
	$self->_init((%$self));
	
} # end sub mergeLvol

=item C<extractVgMinorFromDev>

Method gets minor hex numbers from OS representation of them

@param devminor string - it is OS represantation of minor number, e.g 0x010000

@return hex - it is hex number, in our case 1

=cut

sub extractVgMinorFromDev() {
	
	my $self = shift;
	my %params = @_;
	my $notExtracted = $params{'devminor'};
	
	$notExtracted =~ /0x([0-9a-zA-Z]{1,2})0000/;
	my $extracted = $1;
	
	return $extracted;
	
} # end sub extractVgMinor

=item C<createVgMinorDev>

Method creates OS representation of minor number from supplied hex number

@param hexminor hex

@return string - from hex number e.g 2 creates OS representation 0x020000

=cut

sub createVgMinorDev() {
	
	my $self = shift;
	my %params = @_;
	my $hex = $params{'hexminor'};
	
	$hex =~ s/^([0-9a-zA-Z]{1})$/0$1/;
	my $hexDev = "0x" . $hex . "0000";
	return $hexDev;
	
} # end sub createVgMinor

=item C<getVgMajMin>

Method gets major and minor version of group file

@param vggroupfile string

@return hash ref - contains major and minor keys

=cut

sub getVgMajMin() {
	
	my $self = shift;
	my %params = @_;
	my $devFile = $params{'vggroupfile'};
	
	my $st = stat($devFile);
	my $rdev = $st->rdev;
	
	my $hexmajor = $rdev >> 24;
	my $hexminor = ($rdev << 7) >> 23;
	
	return {'major' => $hexmajor, 'minor' => $hexminor};
	
} # end sub getVgMinor

=head1 DEPENDECIES

	SysAdmToolkit::Lvm::PhysicalVolume::HPUX_1111;
	SysAdmToolkit::Lvm::Register;
	SysAdmToolkit::Term::Shell;
	SysAdmToolkit::Utility::Array;
	File::stat;
	File::Path qw(rmtree);

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
