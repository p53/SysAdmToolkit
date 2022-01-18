package SysAdmToolkit::Lvm::LogicalVolume::HPUX_1111;

=head1 NAME

SysAdmToolkit::Lvm::LogicalVolume::HPUX_1111 - HP-UX 11.11 moodule for getting LVM info about logical volumes

=head1 SYNOPSIS

	my $lvol= SysAdmToolkit::Lvm::LogicalVolume::HPUX_1111->new('lv' => '/dev/vgroot/lvol1');

	or

	my $lvol= SysAdmToolkit::Lvm::LogicalVolume::HPUX_1111->new('lv' => 'lvol1', 'vg' => 'vgroot');							

	$lvol->get('lecount');

=head1 DESCRIPTION

Module OS and version specific module for getting info aboul logical volumes for HP-UX 11.11

=cut

use base qw/
				SysAdmToolkit::Patterns::Prototype
				SysAdmToolkit::Patterns::Getter
				SysAdmToolkit::Patterns::CmdBindedSetter
			/;

use SysAdmToolkit::Term::Shell;

=head1 PRIVATE PROPERTIES

=over 12

=item lvCmd string

	Property is holding command for getting lvol info

=cut

my $lvCmd = 'lvdisplay';

=item lvSplitCmd string

	Property is holding command for splitting lvol

=cut

my $lvSplitCmd = 'lvsplit';

=item lvMergeCmd string

	Property is holding command for merging lvol

=cut

my $lvMergeCmd = 'lvmerge';

=item lvSyncCmd string

	Property stores command for syncing lvol

=cut

my $lvSyncCmd = 'lvsync';

=item lvCreateCmd string

	Property stores command for creating lvol

=cut

my $lvCreateCmd = 'lvcreate';

=item lvRemoveCmd string

	Property stores command for removing lvol

=cut

my $lvRemoveCmd = 'lvremove';

=item lvExtendCmd string

	Property stores command for extending lvol

=cut

my $lvExtendCmd = 'lvextend';

=item lvReduceCmd string

	Property stores command for extending lvol

=cut

my $lvReduceCmd = 'lvreduce';

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

=cut

my @basicProperties = qw/
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
						/;

=item changeCmd string

	Property stores command for changing properties of lvol

=cut

our $changeCmd = 'lvchange';

our $settable = {
					'status' => {'cmd' => "-a", 'verify' => 'y|n|e|s|r'},
					'cluster' => {'cmd' => "-c", 'verify' => 'y|n'},
					'sharable' => {'cmd' => "-S", 'verify' => 'y|n'},
				};
				
our $createParams = {
						'size' => '-L',
						'lecount' => '-l',
						'stripesize' => '-I',
						'stripecount' => '-i',
						'lvname' => '-n',
						'mirrors' => '-m'
					};
						
=head1 METHODS

=over 12

=item C<_init>

Method _init initializes object with all info about lvol

=cut

sub _init() {
	
	my $self = shift;
	my %params = @_;
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $lvPath = '';
	
	# we can initialize object with two types of syntax: with full lvol name or with separate vg and lvol name
	if(!($params{'vg'} && $params{'lv'}) && ($params{'lv'} !~ /\/dev\//)) {
		die "You must specify both vg and lv parameter!";	
	} # if
	
	if(($params{'lv'} =~ /\/dev\//)) {
		$lvPath = $params{'lv'};
	} else {
		$lvPath = '/dev/' . $params{'vg'} . '/' . $params{'lv'};
	} # if
	
	# here we get lvol info and also about pvs in lvol
	my $lvdisplayCmd = "$lvCmd $lvPath|grep -v '\\-\\-\\-'|awk '{print \$NF}'";
	my $lvPvInfoCmd = "$lvCmd -v $lvPath|grep -Ev '[0-9]{5}'|grep '/dev/d'|awk '{print \$1}'";
	
	my $lvdisplayInfo = $shell->execCmd('cmd' => $lvdisplayCmd, 'cmdsNeeded' => [$lvCmd, 'grep', 'awk']);
	my $lvPvInfo = $shell->execCmd('cmd' => $lvPvInfoCmd, 'cmdsNeeded' => [$lvCmd, 'grep', 'awk']);
	
	if(!$lvdisplayInfo->{'returnCode'}) {
		warn("There was some problem getting LV info: " . $lvdisplayInfo->{'msg'} . "\n");
	} # if
	
	my @lvInfo = split("\n", $lvdisplayInfo->{'msg'});
	my @lvPvs = split("\n", $lvPvInfo->{'msg'});
	
	foreach my $index(0..$#basicProperties) {
		$self->{$basicProperties[$index]} = $lvInfo[$index];
	} # foreach
	
	$self->{'pvs'} = \@lvPvs;
	$self->{'splitsuffix'} = 'bkup';
	
} # end sub _init

=item C<lvCreate>

Method lvCreate creates logical volume, this method should not be used, it is helper method
for volume group lvCreate method, it is static method

@param vgname string - volume group name in format vgname not /dev/vgname

@return boolean

=cut

sub lvCreate() {
	
	my $self = shift;
	my %params = @_;
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $vgname = $params{'vgname'};
	my $class = ref($self) || $self;
	
	no strict 'refs';
	
	my $variable = $class . '::createParams';
	my $createParams = $$variable;
	my $lvCreateParams = '';
	
	for my $createParam(keys %$createParams) {
		if(exists($params{$createParam})) {
			$lvCreateParams .= $createParams->{$createParam} . ' ' . $params{$createParam} . ' ';
		} # if
	} # for
	
	$lvCreateInfo = $shell->execCmd('cmd' => "$lvCreateCmd $lvCreateParams $vgname", 'cmdsNeeded' => [$lvCreateCmd]);
	
	if(!$lvCreateInfo->{'returnCode'}) {
		die("There was some problem while creating LV " . $lvCreateInfo->{'msg'} . "\n");
	} # if
	
	my $register = SysAdmToolkit::Lvm::Register->new();

	if($params{'lvname'}) {
		my $lvname = $params{'lvname'};
		$register->{'lvs'}->{"$vgname/$lvname"} = 1;
	} else {
		$register->_init();	
	} # if
	
	return $lvCreateInfo->{'returnCode'};
	
} # end sub lvCreate

=item C<lvRemove>

Method lvRemove removes logical volume, it is object method

@return boolean

=cut

sub lvRemove() {
	
	my $self = shift;
	my $lvname = $self->{'lvname'};
	my $shell = SysAdmToolkit::Term::Shell->new();
	
	if(!$lvname) {
		die "You need to provide LV name!\n";
	} else {
		
		$lvRemoveInfo = $shell->execCmd('cmd' => "$lvRemoveCmd -f " . $lvname, 'cmdsNeeded' => [$lvRemoveCmd]);
		
		if(!$lvRemoveInfo->{'returnCode'}) {
			die("There was some problem while removing LV " . $lvRemoveInfo->{'msg'} . "\n");
		} # if
		
		my $register = SysAdmToolkit::Lvm::Register->new();
		delete $register->{'lvs'}->{$lvname};
		
	} # if
	
	for my $objProp(keys %$self) {
		$self->{$objProp} = undef;
	} # for
	
	return $lvRemoveInfo->{'returnCode'};
	
} # end sub lvRemove

=item C<lvBatchRemove>

Method lvBatchRemove removes several logical volumes, it is static method

@param lvs array ref - array of logical volumes

@return boolean

=cut

sub lvBatchRemove() {
	
	my $self = shift;
	my %params = @_;
	my $lvs = $params{'lvs'};
	my $shell = SysAdmToolkit::Term::Shell->new();
	
	my $lvsString = join(' ', @$lvs);
	
	$lvRemoveInfo = $shell->execCmd('cmd' => "$lvRemoveCmd -f " . $lvsString, 'cmdsNeeded' => [$lvRemoveCmd]);
	
	if(!$lvRemoveInfo->{'returnCode'}) {
		die("There was some problem while batch removing LV " . $lvRemoveInfo->{'msg'} . "\n");
	} # if
	
	my $register = SysAdmToolkit::Lvm::Register->new();
	
	for my $lvname(@$lvs) {
		delete $register->{'lvs'}->{$lvname};
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
	my $lvname = $self->{'lvname'};
	
	if(!$suffix) {
		$suffix = $self->{'splitsuffix'};	
	} #if
	
	my $splitResult = $shell->execCmd('cmd' => "$lvSplitCmd -s $suffix $lvname", 'cmdsNeeded' => [$lvSplitCmd]);
	
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
	my $masterLvName = $self->{'lvname'};
	
	my $mergeResult = $shell->execCmd('cmd' => "$lvMergeCmd $copy $masterLvName", 'cmdsNeeded' => [$lvMergeCmd]);
	
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
	
	my $lvsyncResult = $shell->execCmd('cmd' => "$lvSyncCmd $lvname", 'cmdsNeeded' => [$lvSyncCmd]);
	
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
	my $threaded = $params{'threaded'};
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $lvsString = join(" ", @$lvs);
	my $massLvSyncCmd = $lvSyncCmd;
	
	if($threaded) {
		$massLvSyncCmd .= ' -T';	
	} # if
	
	my $lvsyncResult = $shell->execCmd('cmd' => "$massLvSyncCmd $lvsString", 'cmdsNeeded' => [$lvSyncCmd]);
	
	return $lvsyncResult->{'returnCode'};
	
} # end sub massLvSync

=item C<lvExists>

Method lvExists check if lvol with name passed exists

params:

	$lvname string

return:

	boolean - if lvol exists or not

=back

=cut

sub lvExists($) {
	
	my $self = shift;
	my $lvname = shift;
	my $shell = SysAdmToolkit::Term::Shell->new();

	my $lvCmdResult = $shell->execCmd('cmd' => "$lvCmd  $lvname", 'cmdsNeeded' => [$lvCmd]);
	
	return $lvCmdResult->{'returnCode'};
	
} # end sub lvExists

=item C<lvExtendBy>

Method lvExtendBy extends logical volume by specified value in MB

@param by int - it is size by which to grow logical volume in MB

@return boolean

=cut

sub lvExtendBy() {
	
	my $self = shift;
	my %params = @_;
	
	if(exists($params{'by'})) {
		$params{'final'} = $self->{'size'} + $params{'by'};
	} else {
		die("You need to supply value by which grow LV! \n");
	} # if
	
	my $result = $self->lvExtend(%params);
	
	return $result;
	
} # end sub lvExtendBy

=item C<lvExtendTo>

Method lvExtendTo extends logical volume to size in MB

@param to int - size in MB to which extend logical volume

@param boolean

=cut

sub lvExtendTo() {
	
	my $self = shift;
	my %params = @_;
	
	if (exists($params{'to'})) {
		$params{'final'} = $params{'to'};
	} else {
		die("You need to supply value to which grow LV! \n");
	} # if
	
	my $result = $self->lvExtend(%params);
	
	return $result;
	
} # end sub lvExtendTo

=item C<lvExtend>

Method lvExtend extends logical volume and is used by lvExtendBy and lvExtenTo methods

@param pvs array ref - array of pvs to which extend logical volume, should be full device file 
@param final int - final size to which extend logical volume

@return boolean

=cut

sub lvExtend() {
	
	my $self = shift;
	my %params = @_;
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $pvs = $params{'pvs'};
	my $finalSize = $params{'final'};
	my $lvname = $self->{'lvname'};
	my $lvSize = $self->{'size'};
	my $lvPvs = '';
	
	if(exists($params{'pvs'})) {
		
		my $pvNum = @$pvs;
			
		if($pvNum > 0) {
			$lvPvs = join(' ', @$pvs);
		} # if
		
	} # if
	
	$lvExtendInfo = $shell->execCmd('cmd' => "$lvExtendCmd -L $finalSize $lvname $lvPvs", 'cmdsNeeded' => [$lvExtendCmd]);
	
	if(!$lvExtendInfo->{'returnCode'}) {
		die("There was some problem while extending LV " . $lvExtendInfo->{'msg'} . "\n");
	} # if
	
	$self->_init((%$self));
	
	return $lvExtendInfo->{'returnCode'};
	
} # end sub lvExtend

=item C<lvReduceBy>

Method lvReduceBy reduces logical volume by specified size in MB

@param by int - size by which reduce logical volume

@return boolean

=cut

sub lvReduceBy() {
	
	my $self = shift;
	my %params = @_;
	
	if(exists($params{'by'})) {
		$params{'final'} = $self->{'size'} - $params{'by'};
	} else {
		die("You need to supply value by which reduce LV! \n");
	} # if
	
	my $result = $self->lvReduce(%params);
	
	return $result;
	
} # end sub lvReduceBy

=item C<lvReduceTo>

Method lvReduceTo reduces to size specified in MB

@param to int - size in MB to which reduce logical volume

@return boolean

=cut

sub lvReduceTo() {
	
	my $self = shift;
	my %params = @_;
	
	if (exists($params{'to'})) {
		$params{'final'} = $params{'to'};
	} else {
		die("You need to supply value to which shrink LV! \n");
	} # if
	
	my $result = $self->lvReduce(%params);
	
	return $result;
	
} # end sub lvReduceTo

=item C<lvReduce>

Method which reduces size of logical volume, is used by lvReduceTo and lvReduceBy methods

@param pvs array ref - array of pvs from which we can reduce logical volume
@param final int - final size to which reduce logical volume

@return boolean

=cut

sub lvReduce() {
	
	my $self = shift;
	my %params = @_;
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $pvs = $params{'pvs'};
	my $finalSize = $params{'final'};
	my $lvname = $self->{'lvname'};
	my $lvSize = $self->{'size'};
	my $lvPvs = '';
	
	if(exists($params{'pvs'})) {
		
		my $pvNum = @$pvs;
			
		if($pvNum > 0) {
			$lvPvs = join(' ', @$pvs);
		} # if
		
	} # if
	
	$lvReduceInfo = $shell->execCmd('cmd' => "$lvReduceCmd -f -L $finalSize $lvname $lvPvs", 'cmdsNeeded' => [$lvReduceCmd]);
	
	if(!$lvReduceInfo->{'returnCode'}) {
		die("There was some problem while reducing LV " . $lvReduceInfo->{'msg'} . "\n");
	} # if
	
	$self->_init((%$self));
	
	return $lvReduceInfo->{'returnCode'};
	
} # end sub lvReduce

=item C<addMirror>

Method addMirror adds another mirror to logical volume

@param pvs array ref - array of pvs to which extend logical volume
@param mirror int - number of mirrors of logical volume

@return boolean

=cut

sub addMirror() {

	my $self = shift;
	my %params = @_;
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $pvs = $params{'pvs'};
	my $lvname = $self->{'lvname'};
	my $lvMirrorCount = $params{'mirror'};
	my $lvPvs = '';
	
	if(exists($params{'pvs'})) {
		
		my $pvNum = @$pvs;
			
		if($pvNum > 0) {
			$lvPvs = join(' ', @$pvs);
		} # if
		
	} # if
	
	if($lvMirrorCount <= 0 || $lvMirrorCount <= $self->{'mirrors'}) {
		die("Mirror count must by greater than 0 and current value!\n");
	} # if
	
	$lvExtendInfo = $shell->execCmd('cmd' => "$lvExtendCmd -m $lvMirrorCount $lvname $lvPvs", 'cmdsNeeded' => [$lvExtendCmd]);
	
	if(!$lvExtendInfo->{'returnCode'}) {
		die("There was some problem while adding LV mirror " . $lvExtendInfo->{'msg'} . "\n");
	} # if
	
	$self->_init((%$self));
	
	return $lvExtendInfo->{'returnCode'};
	
} # end sub addMirror

=item C<removeMirror>

Method removeMirror removes mirror from logical volume

@param pvs array ref - pvs to remove as mirrors
@param mirror int - number of final count of mirrors
=cut

sub removeMirror() {
	
	my $self = shift;
	my %params = @_;
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $pvs = $params{'pvs'};
	my $lvname = $self->{'lvname'};
	my $lvMirrorCount = $params{'mirror'};
	my $lvPvs = '';

	if(exists($params{'pvs'})) {
		
		my $pvNum = @$pvs;
			
		if($pvNum > 0) {
			$lvPvs = join(' ', @$pvs);
		} # if
		
	} # if
	
	if($lvMirrorCount >= $self->{'mirrors'}) {
		die("Mirror count must by lower than current value!\n");
	} # if
	
	$lvReduceInfo = $shell->execCmd('cmd' => "$lvReduceCmd -m $lvMirrorCount $lvname $lvPvs", 'cmdsNeeded' => [$lvReduceCmd]);
	
	if(!$lvReduceInfo->{'returnCode'}) {
		die("There was some problem while removing LV mirror " . $lvReduceInfo->{'msg'} . "\n");
	} # if
	
	$self->_init((%$self));
	
	return $lvReduceInfo->{'returnCode'};
	
} # end sub removeMirror

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
