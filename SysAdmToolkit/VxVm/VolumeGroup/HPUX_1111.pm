package SysAdmToolkit::VxVm::VolumeGroup::HPUX_1111;

=head1 NAME

SysAdmToolkit::VxVm::VolumeGroup::HPUX_1111; - OS and version specific module for getting info about VxVm volume group

=head1 SYNOPSIS

	my $vg = SysAdmToolkit::VxVm::VolumeGroup::HPUX_1111->new('vg' => 'newdg');
										
	my $vgInfo = $vg->get('maxpv');

=head1 DESCRIPTION

Module is aimed at getting info about volume group on HP-UX 11.11

=cut

use base qw/
				SysAdmToolkit::Patterns::Prototype
				SysAdmToolkit::Patterns::Getter
			/;

use SysAdmToolkit::VxVm::LogicalVolume;
use SysAdmToolkit::VxVm::PhysicalVolume::HPUX_1111;
use SysAdmToolkit::VxVm::Register;
use SysAdmToolkit::Term::Shell;

=head1 PRIVATE PROPERTIES

=over 12

=item recordCmd string

	Property stores command for displaying info about vx records

=cut

my $recordCmd = 'vxprint';

=item vxVgCmd string

Property stores command for getting overview info about DG's

=cut

my $vxVgCmd = 'vxdg';

=item vxCreateCmd string

Property stores command for creating DG

=cut

my $vxCreateCmd = 'vxdg init';

=item vxRemoveCmd string

Property stores command for removing DG

=back

=cut
			
my $vxRemoveCmd = 'vxdg destroy';
	
=head1 METHODS

=over 12

=item C<_init>

Method _init initializies object and gets all info about volume group

params:

	vg string - vgname

=cut

sub _init() {
	
	my $self = shift;
	my %params = @_;
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $dgItems = {};
	
	if(!($params{'vg'})) {
		die "You must specify vg parameter!";	
	} # if
	
	my $vgPath = $params{'vg'};
	
	# we are getting info about VG, about LVS in VG and about PVS in VG
	my $vgdisplayCmd = "$recordCmd -aqQg $vgPath";
	
	my $vgdisplayInfo = $shell->execCmd('cmd' => $vgdisplayCmd, 'cmdsNeeded' => [$recordCmd]);
	
	if(!$vgdisplayInfo->{'returnCode'}) {
		die("There was some problem getting VG info: " . $vgdisplayInfo->{'msg'} . "\n");
	} # if
	
	my @vxVgInfo = split("\n", $vgdisplayInfo->{'msg'});
	
	for my $item(@vxVgInfo) {
		
		my @itemInfo = split(' ', $item);
		my $recordType = shift(@itemInfo);
		my $recordName = shift(@itemInfo);
		
		if($recordType eq 'dg') {
			
			for my $itemInfoProp(@itemInfo) {
                 
                 if($itemInfoProp !~ /^[a-zA-Z0-9\_]+=$/) {
                    my @pair = split('=', $itemInfoProp);
                 	$dgProps{$pair[0]} = $pair[1];
                 } # if
                 
            } # for
            
			$dgItems->{$recordType}->{$recordName} = \%dgProps;
			
		} else {
			$dgItems->{$recordType}->{$recordName} = \@itemInfo;
		} # if
		
	} # for
	
	my $vols = $dgItems->{'vol'};
	my $dms = $dgItems->{'dm'};
	
	%$self = %dgProps;
	
	$self->{'os'} = $params{'os'};
	$self->{'ver'} = $params{'ver'};
	$self->{'vg'} = $params{'vg'};
	$self->{'vgname'} = $params{'vg'};
	$self->{'pvs'} = [keys(%$dms)];
	$self->{'lvs'} = [keys(%$vols)];
	
	$self->{'changedDevice'} = $self->{'vg'};

} # end sub _init

=item C<vgCreate>

Method vgCreate creates0 volume group, it is static method

params:

	vgname string - is name of new vg in the form namedg

	pvs array ref - is array of volume group pvs

return:

	boolean

=cut

sub vgCreate() {
	
	my $self = shift;
	my %params = @_;
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $pvs = $params{'pvs'};
	my $vgname = $params{'vgname'};
	my $class = ref($self) || $self;
	my $size = keys(%$pvs);
	my $vgPvs = '';
	
	if(!$vgname) {
		die "You need to provide name fo new VG!\n";
	} # if
	
	if(!$pvs || ($size == 0)) {
		die "You didn't supply pvs!\n";
	} # if
	
	foreach my $pvMediaName(keys %$pvs){
			my $pvName = $pvMediaName . '=' . $pvs->{$pvMediaName};
			$vgPvs .=  "$pvName ";
	} # foreach
	
	$vgCreateInfo = $shell->execCmd('cmd' => "$vxCreateCmd $vgname $vgPvs", 'cmdsNeeded' => [$vxVgCmd]);
	
	if(!$vgCreateInfo->{'returnCode'}) {
		die("There was some problem while creating VG " . $vgCreateInfo->{'msg'} . "\n");
	} # if
	
	my $register = SysAdmToolkit::VxVm::Register->new();
	$register->{'vgs'}->{"$vgname"} = 1;
	
	foreach my $pvName(keys %$pvs){
			$register->{'pvs'}->{"$vgname/$pvName"} = $pvs->{$pvName};
	} # foreach
		
	return $vgCreateInfo->{'returnCode'};
	
} # end sub vgCreate

=item C<vgRemove>

Method vgRemove is removing Volume group, object method

return:

	boolean

=cut

sub vgRemove() {
	
	my $self = shift;
	my $vgname = $self->{'vg'};
	my $pvs = $self->{'pvs'};
	my $lvs = $self->{'lvs'};
	my $size = @$pvs;
	my $shell = SysAdmToolkit::Term::Shell->new();
	
	if(!$vgname) {
		die "You need to provide VG name!\n";
	} else {

		$vgRemoveInfo = $shell->execCmd('cmd' => "$vxRemoveCmd " . $vgname, 'cmdsNeeded' => [$vxVgCmd]);
		
		if(!$vgRemoveInfo->{'returnCode'}) {
			die("There was some problem while removing VG " . $vgRemoveInfo->{'msg'} . "\n");
		} # if
		
		my $register = SysAdmToolkit::VxVm::Register->new();
		delete $register->{'vgs'}->{$vgname};

		foreach my $pv(@$pvs){
			delete $register->{'pvs'}->{"$vgname/$pv"};
		} # foreach
		
		foreach my $lv(@$lvs){
			delete $register->{'lvs'}->{"$vgname/$lv"};
		} # foreach
		
	} # if
	
	for my $objProp(keys %$self) {
		$self->{$objProp} = undef;
	} # for
	
	return $vgRemoveInfo->{'returnCode'};
	
} # end sub vgRemove

=item C<vgExtend>

Method vgExtend is extending volume group

params:

	pvs array ref - array of pvs, which are added to volume group, should be full PV device names

return:

	boolean

=cut

sub vgExtend() {
	
	my $self = shift;
	my %params = @_;
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $pvs = $params{'pvs'};
	my $vgname = $self->{'vg'};
	my $vgPvs = '';
	
	foreach my $pvMediaName(keys %$pvs){
			my $pvName = $pvMediaName . '=' . $pvs->{$pvMediaName};
			$vgPvs .= "$pvName ";
	} # foreach
	
	$vgExtendInfo = $shell->execCmd('cmd' => "$vxVgCmd -g $vgname adddisk $vgPvs", 'cmdsNeeded' => [$vxVgCmd]);
	
	if(!$vgExtendInfo->{'returnCode'}) {
		die("There was some problem while extending VG " . $vgExtendInfo->{'msg'} . "\n");
	} # if
	
	my $register = SysAdmToolkit::VxVm::Register->new();

	foreach my $pvName(keys %$pvs){
		$register->{'pvs'}->{"$vgname/$pvName"} = $pvs->{$pvName};
	} # foreach
	
	$self->_init((%$self));
	
	return $vgExtendInfo->{'returnCode'};
	
} # end sub vgExtend

=item C<vgReduce>

Method vgReduce removes pvs from volume group

params:

	pvs array ref - array of pvs to be removed from volume group, should be full PV device files

return:

	boolean

=cut

sub vgReduce() {
	
	my $self = shift;
	my %params = @_;
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $pvs = $params{'pvs'};
	my $size = @$pvs;
	my $vgname = $self->{'vg'};
	
	if(!$vgname) {
		die "You need to provide name fo reduced VG!\n";
	} # if
	
	if(!$pvs || ($size == 0)) {
		die "You didn't supply pvs!\n";
	} # if
	
	my $vgPvs = join(' ', @$pvs);
	
	$vgReduceInfo = $shell->execCmd('cmd' => "$vxVgCmd -g $vgname rmdisk $vgPvs", 'cmdsNeeded' => [$vxVgCmd]);
	
	if(!$vgReduceInfo->{'returnCode'}) {
		die("There was some problem while reducing VG " . $vgReduceInfo->{'msg'} . "\n");
	} # if
	
	my $register = SysAdmToolkit::VxVm::Register->new();

	foreach my $pv(@$pvs){
		delete $register->{'pvs'}->{"$vgname/$pv"};
	} # foreach
	
	$self->_init((%$self));
	
	return $vgReduceInfo->{'returnCode'};
	
} # end sub vgReduce

=item C<lvCreate>

Method lvCreate creates LV in volume group, this method should be used to properly update volume groups lvs

params:

	lvname string - name of new lv
	
return:

	boolean

=cut

sub lvCreate() {
	
	my $self = shift;
	my %params = @_;
	
	$params{'vgname'} = $self->{'vg'};
	$params{'vg'} = $self->{'vg'};
	
	my $lvClass = SysAdmToolkit::VxVm::LogicalVolume->getClass('os' => $self->{'os'}, 'ver' => $self->{'ver'});
	my $lvCreateInfo = $lvClass->lvCreate(%params);
	
	my $lvname = $params{'lvname'};
	my $vgname = $params{'vgname'};
	my $lvs = $self->{'lvs'};
	push(@$lvs, "$lvname");
	
	$self->_init((%$self));	

	return $lvCreateInfo;
	
} # end sub lvCreate

=item C<lvRemove>

METHOD lvRemove removes lv from DG and also rsyncs vg info

params:

	lvObj SysAdmToolkit::VxVm::LogicalVolume
	
=cut

sub lvRemove() {
	
	my $self = shift;
	my %params = @_;
	my $lvObj = $params{'lvObj'};
	
	$lvObj->lvRemove();
	
	$self->_init((%$self));
	
} # end sub lvRemove

=item C<lvBatchRemove>

METHOD lvBatchRemove removes several lvs supplied in array

params:

	lvs array - array of lv names
	
	lvClass SysAdmToolkit::VxVm::LogicalVolume::HPUX* (11_31, 11_11, 11_23)
	
=cut

sub lvBatchRemove() {
	
	my $self = shift;
	my %params = @_;
	$params{'vg'} = $self->{'vg'};
	my $lvClass = $params{'lvClass'};
	
	$lvClass->lvBatchRemove(%params);
	
	$self->_init((%$self));
	
} # end sub lvBatchRemove

=item C<splitLvol>

METHOD splitLvol splits lvol and also resyncs vg info

params:

	lvObj SysAdmToolkit::VxVm::LogicalVolume
	
=cut

sub splitLvol($) {
	
	my $self = shift;
	my %params = @_;
	my $suffix = $params{'suffix'};
	my $lvObj = $params{'lvObj'};
	
	$lvObj->splitLvol($suffix);
	
	$self->_init((%$self));
	
} # end sub splitLvol

=item C<mergeLvol>

METHOD mergeLvol merges lvol to master

params:

	copy string - name of suffix of splited volume
	
	lvObj SysAdmToolkit::VxVm::LogicalVolume - master lvol
	
=cut

sub mergeLvol() {
	
	my $self = shift;
	my %params = @_;
	my $suffix = $params{'copy'};
	my $lvObj = $params{'lvObj'};
	
	$lvObj->mergeLvol($suffix);
	
	$self->_init((%$self));
	
} # end sub mergeLvol

=head1 DEPENDECIES

	SysAdmToolkit::VxVm::PhysicalVolume::HPUX_1111;
	SysAdmToolkit::VxVm::Register;
	SysAdmToolkit::Term::Shell;
	SysAdmToolkit::VxVm::LogicalVolume

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
