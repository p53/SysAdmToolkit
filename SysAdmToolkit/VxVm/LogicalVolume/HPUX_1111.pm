package SysAdmToolkit::VxVm::LogicalVolume::HPUX_1111;

=head1 NAME

SysAdmToolkit::VxVm::LogicalVolume::HPUX_1111 - HP-UX 11.11 moodule for getting VxVm info about logical volumes

=head1 SYNOPSIS

	my $lvol= SysAdmToolkit::VxVm::LogicalVolume::HPUX_1111->new('lv' => 'lvol1', 'vg' => 'newdg');							

	$lvol->get('pvs');

=head1 DESCRIPTION

Module OS and version specific module for getting info aboul logical volumes for HP-UX 11.11

=cut

use base qw/
				SysAdmToolkit::Patterns::Prototype
				SysAdmToolkit::Patterns::Getter
			/;

use SysAdmToolkit::Term::Shell;
use SysAdmToolkit::VxVm::Register;

=head1 PRIVATE PROPERTIES

=over 12

=item recordCmd string

Private property is holding command for getting info about vx records

=cut

my $recordCmd = 'vxprint';

=item assistCmd string

Private property storing command for managing vx object from higher level

=cut

my $assistCmd = 'vxassist';

=item devBlockBase string

Private property storing directory path for vx block device files

=cut

my $devBlockBase = '/dev/vx/dsk/';

=item recordEditCmd string

Private property storing command for editing names of vx records

=cut

my $recordEditCmd = 'vxedit';

=item makeCmd string

Private property storing command for manipulating vx volumes

=cut

my $makeCmd = 'vxmake';

=item plexCmd string

Private property storing command for manipulating plexes

=cut

my $plexCmd = 'vxplex';

=item basicProperties array

	Property stores basic set of properties available to get from this module:

	lvname
	vgname
	perms
	status
	mirrors
	consist_recovery
	schedule
	size
	lecount
	pecount
	stripecount
	stripesize
	badblock
	allocation
	timeout

=back

=head1 STATIC PROPERTIES

=over 12

=item volCmd string

Property stores command for getting info about volumes

=cut

our $volCmd = 'vxvol';

=item createParams hash ref

Property stores parameter to command options mappings used during create

=cut

our $createParams = {
						'layout' => 'layout=',
						'stripesize' => 'stripewidth=',
						'nstripe' => 'nstripe=',
						'nmirror' => 'nmirror='
					};

=item settable hash ref

Property stores possible action for set method

=back

=cut

our $settable = {
					'start' => {'cmd' => "start"},
					'stop' => {'cmd' => "stop"}
				};
								
=head1 METHODS

=over 12

=item C<_init>

Method _init initializes object with all info about lvol

params:

	vg string - name of the DG of volume
	
	lv string - name of volume
	
=cut

sub _init() {
	
	my $self = shift;
	my %params = @_;
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $lvPath = '';
	my $lvItems = {};
	my %volProps = ();
	
	if(!($params{'vg'} && $params{'lv'})) {
		die "You must specify both vg and lv parameter!";	
	} # if
	
	my $vg = $params{'vg'};
	my $lv = $params{'lv'};
	
	# here we get lvol info and also about pvs in lvol
	my $lvdisplayCmd = "$recordCmd -g $vg -avQqr $lv|" . 'grep -v \'^$\'';
	
	my $lvdisplayInfo = $shell->execCmd('cmd' => $lvdisplayCmd, 'cmdsNeeded' => [$recordCmd, 'grep']);
	
	if(!$lvdisplayInfo->{'returnCode'}) {
		die("There was some problem getting LV info: " . $lvdisplayInfo->{'msg'} . "\n");
	} # if
	
	my @lvInfo = split("\n", $lvdisplayInfo->{'msg'});
	
	# here we parse output to property value mappings
	for my $item(@lvInfo) {
		
		my @itemInfo = split(' ', $item);
		my $recordType = shift(@itemInfo);
		my $recordName = shift(@itemInfo);
		
		if($recordType eq 'vol') {
			
			for my $itemInfoProp(@itemInfo) {
                 
                 if($itemInfoProp !~ /^[a-zA-Z0-9\_]+=$/) {
                    my @pair = split('=', $itemInfoProp);
                 	$volProps{$pair[0]} = $pair[1];
                 } # if
                 
            } # for

			$lvItems->{$recordType}->{$recordName} = \%volProps;
		} else {
			$lvItems->{$recordType}->{$recordName} = \@itemInfo;
		} # if
		
	} # for
	
	my $dms = $lvItems->{'dm'};
	my $sds = $lvItems->{'sd'};
	my $pls = $lvItems->{'plex'};
	my $plexCount = keys(%$pls);
	my $mirrorCount = $plexCount - 1;
	
	%$self = %volProps;
	
	$self->{'vg'} = $params{'vg'};
	$self->{'vgname'} = $params{'vg'};
	$self->{'lvname'} = $devBlockBase . $params{'vg'} . '/' . $params{'lv'};
	$self->{'lv'} = $params{'lv'};
	$self->{'pvs'} = [keys(%$dms)];
	$self->{'sds'} = [keys(%$sds)];
	$self->{'pls'} = [keys(%$pls)];
	$self->{'mirrors'} = $mirrorCount;
	$self->{'splitsuffix'} = 'bkup';
	
} # end sub _init

=item C<lvCreate>

Method lvCreate creates logical volume, this method should not be used, it is helper method
for volume group lvCreate method, it is static method, registers lvol as vgname/lvname in Register

params:

	vgname string - diskgroup name in format vgname not vgname

	lvname string - volume name
	
return:

	boolean

=cut

sub lvCreate() {
	
	my $self = shift;
	my %params = @_;
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $vgname = $params{'vgname'};
	my $lvname = $params{'lvname'};
	my $size = $params{'size'};
	my $class = ref($self) || $self;
	
	if(!exists($params{'vgname'}) or !exists($params{'lvname'}) or !exists($params{'size'})) {
		die("You need to supply VG and LV name!\n");
	} # if
	
	# here we join parameters for create command
	no strict 'refs';
	
	my $variable = $class . '::createParams';
	my $createParams = $$variable;
	my $lvCreateParams = '';
	
	for my $createParam(keys %$createParams) {
		if(exists($params{$createParam})) {
			$lvCreateParams .= $createParams->{$createParam} . $params{$createParam} . ' ';
		} # if
	} # for
	
	$lvCreateInfo = $shell->execCmd('cmd' => "$assistCmd -g $vgname make $lvname $size $lvCreateParams ", 'cmdsNeeded' => [$assistCmd]);
	
	if(!$lvCreateInfo->{'returnCode'}) {
		die("There was some problem while creating LV " . $lvCreateInfo->{'msg'} . "\n");
	} # if
	
	# register new lvol in register
	my $register = SysAdmToolkit::VxVm::Register->new();

	if($params{'lvname'}) {
		$register->{'lvs'}->{"$vgname/$lvname"} = 1;
	} # if
	
	return $lvCreateInfo->{'returnCode'};
	
} # end sub lvCreate

=item C<lvRemove>

Method lvRemove removes logical volume, it is object method

params:

	lvname string - volume name
	
	vgname string - diskgroup name
	
return:

	boolean

=cut

sub lvRemove() {
	
	my $self = shift;
	my $lvname = $self->{'lvname'};
	my $vgname = $self->{'vgname'};
	my $lv = $self->{'lv'};
	
 	my $shell = SysAdmToolkit::Term::Shell->new();
	
	if(!$lv) {
		die "You need to provide LV name!\n";
	} else {
		
		$lvRemoveInfo = $shell->execCmd('cmd' => "$assistCmd -g $vgname remove volume $lv", 'cmdsNeeded' => [$assistCmd]);
		
		if(!$lvRemoveInfo->{'returnCode'}) {
			die("There was some problem while removing LV " . $lvRemoveInfo->{'msg'} . "\n");
		} # if
		
		my $register = SysAdmToolkit::VxVm::Register->new();
		delete $register->{'lvs'}->{"$vgname/$lv"};
		
	} # if
	
	for my $objProp(keys %$self) {
		$self->{$objProp} = undef;
	} # for
	
	return $lvRemoveInfo->{'returnCode'};
	
} # end sub lvRemove

=item C<lvBatchRemove>

Method lvBatchRemove removes several logical volumes, it is static method

params:

	lvs array ref - array of logical volumes

	vg string - vg name
	
return:
	
	boolean

=cut

sub lvBatchRemove() {
	
	my $self = shift;
	my %params = @_;
	my $lvs = $params{'lvs'};
	my $vg = $params{'vg'};
	
	my $shell = SysAdmToolkit::Term::Shell->new();
	
	if(!exists($params{'lvs'}) or !exists($params{'vg'})) {
		die("You need to supply LV's and VG!\n");	
	} # if
	
	my $register = SysAdmToolkit::VxVm::Register->new();
	my $lvRemoveInfo = {};
	
	for my $lvToRemove(@$lvs) {
		
		$lvRemoveInfo = $shell->execCmd('cmd' => "$assistCmd -g $vg remove volume " . $lvToRemove, 'cmdsNeeded' => [$assistCmd]);
		
		if(!$lvRemoveInfo->{'returnCode'}) {
			die("There was some problem while batch removing LV " . $lvRemoveInfo->{'msg'} . "\n");
		} # if
		
		# removing from register vgname/lvname
		delete $register->{'lvs'}->{"$vg/$lvToRemove"};
	
	} # for
	
	return $lvRemoveInfo->{'returnCode'};
		
} # end sub lvBatchRemove		

=item C<splitLvol>

Method splitLvol is used for splitting lvol

params:

	$suffix string - specifies suffix of new splited lvol

return:

	boolean - if operation was successful or not

=cut

sub splitLvol($) {
	
	my $self = shift;
	my $suffix = shift;
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $lv = $self->{'lv'};
	my $vgname = $self->{'vgname'};
	my $lastPlex =  $self->{'pls'}->[0];
	
	if(!$suffix) {
		$suffix = $self->{'splitsuffix'};	
	} #if
	
	# creating names for new lvol
	my $splittedPlexName = $lastPlex . $suffix;
	my $splittedLvName = $lv . $suffix;
	
	# detaching one plex
	my $detachResult = $shell->execCmd('cmd' => "$plexCmd -g $vgname dis $lastPlex", 'cmdsNeeded' => [$plexCmd]);
	
	if(!$detachResult->{'returnCode'}) {
		die("There was some problem during plex detaching: $lastPlex from VG $vgname:" . $detachResult->{'msg'} . "!\n");	
	} # if
	
	# renaming detached plex to splited name
	my $recordEditResult = $shell->execCmd('cmd' => "$recordEditCmd -g $vgname rename $lastPlex $splittedPlexName", 'cmdsNeeded' => [$plexCmd]);
	
	if(!$recordEditResult->{'returnCode'}) {
		die("There was some problem during plex $lastPlex renaming" . $recordEditResult->{'msg'} . "!\n");
	} # if
	
	# creating new volume with detached plex and splitted name
	my $newVolumeResult = $shell->execCmd('cmd' => "$makeCmd -g $vgname vol $splittedLvName plex=$splittedPlexName");
	
	if(!$newVolumeResult->{'returnCode'}) {
		die("There was some problem during making new volume $splittedLvName: " . $newVolumeResult->{'msg'} . "!\n");
	} # if
	
	# registering new volume
	my $register = SysAdmToolkit::VxVm::Register->new();

	$register->{'lvs'}->{"$vgname/$splittedLvName"} = 1;
		
	return $splitResult->{'returnCode'};
	
} # end sub splitLvol

=item C<mergeLvol>

Method mergeLvol merges logical volume which name is passed to it with our lvol

params:

	$copy string - lvol which we want to merge

return:

	boolean - if operation was successful or not

=cut

sub mergeLvol($) {
	
	my $self = shift;
	my $copy = shift;
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $masterLvName = $self->{'lv'};
	my $vgname = $self->{'vgname'};
	
	# removing merged volume
	my $removeCopyResult = $shell->execCmd('cmd' => "$assistCmd -g $vgname remove volume $copy", 'cmdsNeeded' => [$assistCmd]);
	
	if(!$removeCopyResult->{'returnCode'}) {
		die("There was some problem removing volume $copy" . $removeCopyResult->{'msg'} . "!\n");
	} # if
	
	# mirroring master volume
	my $mergeResult = $shell->execCmd('cmd' => "$assistCmd -g $vgname mirror $masterLvName", 'cmdsNeeded' => [$assistCmd]);
	
	if(!$mergeResult->{'returnCode'}) {
		die("There was some problem adding mirror " . $mergeResult->{'msg'} . "!\n");
	} # if
	
	my $register = SysAdmToolkit::VxVm::Register->new();

	# deleting merged volume from register
	delete $register->{'lvs'}->{"$vgname/$copy"};
	
	return $mergeResult->{'returnCode'};
	
} # end sub mergeLvol

=item C<lvsync>

Method lvsync is syncing lvol

return:

	boolean - if operation was successful or not

=cut

sub lvsync() {
	
	my $self = shift;
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $lvname = $self->{'lvname'};
	my $vgname = $self->{'vgname'};
	
	my $lvsyncResult = $shell->execCmd('cmd' => "$volCmd -g $vgname resync $lvname", 'cmdsNeeded' => [$volCmd]);
	
	return $lvsyncResult->{'returnCode'};
	
} # end sub lvsync

=item C<massLvSync>

Method massLvSync is syncing more lvols, passed as params at once, can be also threaded

params:

	lvs array ref

	threaded boolean - syncing we be threaded

return:

	boolean - if operation was successful or not

=cut

sub massLvSync($$) {
	
	my $self = shift;
	my %params = @_;
	my $lvs = $params{'lvs'};
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $lvsString = join(" ", @$lvs);
	
	my $lvsyncResult = $shell->execCmd('cmd' => "$volCmd -g $vgname resync $lvsString", 'cmdsNeeded' => [$volCmd]);
	
	return $lvsyncResult->{'returnCode'};
	
} # end sub massLvSync

=item C<lvExists>

Method lvExists check if lvol with name passed exists

params:

	$lvname string

	$vgname string
	
return:

	boolean - if lvol exists or not

=back

=cut

sub lvExists($$) {
	
	my $self = shift;
	my $lvname = shift;
	my $vgname = shift;
	my $shell = SysAdmToolkit::Term::Shell->new();

	my $lvCmdResult = $shell->execCmd('cmd' => "$recordCmd -g $vgname $lvname", 'cmdsNeeded' => [$recordCmd]);
	
	return $lvCmdResult->{'returnCode'};
	
} # end sub lvExists

=item C<lvExtendBy>

Method lvExtendBy extends logical volume by specified value

params:

	by int - it is size by which to grow logical volume

return:

	boolean

=cut

sub lvExtendBy() {
	
	my $self = shift;
	my %params = @_;
	
	if(exists($params{'by'})) {
		$params{'opsize'} = $params{'by'};
		$params{'operation'} = 'growby';
	} else {
		die("You need to supply value by which grow LV! \n");
	} # if
	
	my $result = $self->lvSize(%params);
	
	return $result;
	
} # end sub lvExtendBy

=item C<lvExtendTo>

Method lvExtendTo extends logical volume to size in MB

param:

	to int - size to which extend logical volume

return:

	boolean

=cut

sub lvExtendTo() {
	
	my $self = shift;
	my %params = @_;
	
	if (exists($params{'to'})) {
		$params{'opsize'} = $params{'to'};
		$params{'operation'} = 'growto';
	} else {
		die("You need to supply value to which grow LV! \n");
	} # if
	
	my $result = $self->lvSize(%params);
	
	return $result;
	
} # end sub lvExtendTo

=item C<lvSize>

Method lvSize extends logical volume and is used by lvExtendBy, lvExtendTo, lvReduceBy, lvExtendTo methods

params:

	pvs array ref - array of pvs to which extend logical volume, should be device file without directory
	
	opsize - size by which grow or shrink
	
	operation - is either growto, growby, shrinkto, shrinkby

return:

	boolean

=cut

sub lvSize() {
	
	my $self = shift;
	my %params = @_;
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $pvs = $params{'pvs'};
	my $lvname = $self->{'lvname'};
	my $vgname = $self->{'vgname'};
	my $opsize = $params{'opsize'};
	my $operation = $params{'operation'};
	my $lvPvs = '';
	my $lv = $self->{'lv'};
	
	if(exists($params{'pvs'})) {
		
		my $pvNum = @$pvs;
			
		if($pvNum > 0) {
			$lvPvs = join(' ', @$pvs);
		} # if
		
	} # if
	
	$lvExtendInfo = $shell->execCmd('cmd' => "$assistCmd -g $vgname $operation $lv $opsize $lvPvs", 'cmdsNeeded' => [$assistCmd]);
	
	if(!$lvExtendInfo->{'returnCode'}) {
		die("There was some problem while extending LV " . $lvExtendInfo->{'msg'} . "\n");
	} # if
	
	$self->_init((%$self));
	
	return $lvExtendInfo->{'returnCode'};
	
} # end sub lvSize

=item C<lvReduceBy>

Method lvReduceBy reduces logical volume by specified size in MB

params:

	by int - size by which reduce logical volume

return:

	boolean

=cut

sub lvReduceBy() {
	
	my $self = shift;
	my %params = @_;
	
	if(exists($params{'by'})) {
		$params{'opsize'} = $params{'by'};
		$params{'operation'} = '-f shrinkby';
	} else {
		die("You need to supply value by which reduce LV! \n");
	} # if
	
	my $result = $self->lvSize(%params);
	
	return $result;
	
} # end sub lvReduceBy

=item C<lvReduceTo>

Method lvReduceTo reduces to size specified in MB

params:

	to int - size to which reduce logical volume

return:

	boolean

=cut

sub lvReduceTo() {
	
	my $self = shift;
	my %params = @_;
	
	if (exists($params{'to'})) {
		$params{'opsize'} = $params{'to'};
		$params{'operation'} = '-f shrinkto';
	} else {
		die("You need to supply value to which shrink LV! \n");
	} # if
	
	my $result = $self->lvSize(%params);
	
	return $result;
	
} # end sub lvReduceTo

=item C<addMirror>

Method addMirror adds another mirror to logical volume

params:

	pvs array ref - array of pvs to which extend logical volume
	
	mirror int - number of mirrors of logical volume

return:

	boolean

=cut

sub addMirror() {

	my $self = shift;
	my %params = @_;
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $pvs = $params{'pvs'};
	my $lvname = $self->{'lvname'};
	my $vgname = $self->{'vgname'};
	my $lvMirrorCount = $params{'mirror'};
	my $lvPvs = '';
	my $lv = $self->{'lv'};
	
	if(exists($params{'pvs'})) {
		
		my $pvNum = @$pvs;
			
		if($pvNum > 0) {
			$lvPvs = join(' ', @$pvs);
		} # if
		
	} # if
	
	if($lvMirrorCount <= 0 || $lvMirrorCount <= $self->{'mirrors'}) {
		die("Mirror count must by greater than 0 and current value!\n");
	} # if
	
	my $index = 1;
	
	while($index <= $lvMirrorCount) {
		
		$lvExtendInfo = $shell->execCmd('cmd' => "$assistCmd -g $vgname mirror $lv $lvPvs", 'cmdsNeeded' => [$assistCmd]);
		
		if(!$lvExtendInfo->{'returnCode'}) {
			die("There was some problem while adding LV mirror " . $lvExtendInfo->{'msg'} . "\n");
		} # if
		
		$index++;
		
	} # while
	
	$self->_init((%$self));
	
	return $lvExtendInfo->{'returnCode'};
	
} # end sub addMirror

=item C<removeMirror>

Method removeMirror removes mirror from logical volume

params:

	pvs array ref - pvs to remove as mirrors
	
	mirror int - number of final count of mirrors
	
return:

	boolean
	
=cut

sub removeMirror() {
	
	my $self = shift;
	my %params = @_;
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $pvs = $params{'pvs'};
	my $lvname = $self->{'lvname'};
	my $vgname = $self->{'vgname'};
	my $lvMirrorCount = $params{'mirror'};
	my $lvPvs = '';
	my $lv = $self->{'lv'};
	
	if(exists($params{'pvs'})) {
		
		my $pvNum = @$pvs;
			
		if($pvNum > 0) {
			$lvPvs = join(' ', @$pvs);
		} # if
		
	} # if
	
	if($lvMirrorCount >= $self->{'mirrors'}) {
		die("Mirror count must by lower than current value!\n");
	} # if
	
	my $index = $self->{'mirrors'};
	
	while($index > $lvMirrorCount) {
		
		$lvReduceInfo = $shell->execCmd('cmd' => "$assistCmd -g $vgname remove mirror $lv $lvPvs", 'cmdsNeeded' => [$assistCmd]);
		
		if(!$lvReduceInfo->{'returnCode'}) {
			die("There was some problem while removing LV mirror " . $lvReduceInfo->{'msg'} . "\n");
		} # if
	
		$index--;
		
	} # while
	
	$self->_init((%$self));
	
	return $lvReduceInfo->{'returnCode'};
	
} # end sub removeMirror

=item C<set>

METHOD set sets allowed properties

params:

	property string
	
	value string
	
return:

	boolean
	
=back

=cut

sub set($$) {
	
	my $self = shift;
	my $property = shift;
	my $value = shift;
	my $vgname = $self->{'vgname'};
	my $lv = $self->{'lv'};
	my $shell = SysAdmToolkit::Term::Shell->new();
	
	if(!exists($settable->{$property})) {
		die("You need to give valid property to set!\n");
	} # if
	
	my $setResult = $shell->execCmd('cmd' => "$volCmd -g $vgname $settable->{$property}->{'cmd'} $value $lv", 'cmdsNeeded' => [$voldCmd]);
	
	if(!$setResult->{'returnCode'}) {
		die("There was some problem running set command" . $setResult->{'msg'} . "\n");	
	} # if
	
	return $setResult->{'returnCode'};
	
} # end sub set

=head1 DEPENDECIES

	SysAdmToolkit::Patterns::Prototype
	SysAdmToolkit::Patterns::Getter
	SysAdmToolkit::Term::Shell
	SysAdmToolkit::VxVm::Register
	
=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
