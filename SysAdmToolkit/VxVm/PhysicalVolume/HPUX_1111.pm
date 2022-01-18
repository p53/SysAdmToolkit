package SysAdmToolkit::VxVm::PhysicalVolume::HPUX_1111;

=head1 NAME

SysAdmToolkit::VxVm::PhysicalVolume::HPUX_1111 - OS and version specific module for getting info about physical volume

=head1 SYNOPSIS

	my $pv= SysAdmToolkit::VxVm::PhysicalVolume::HPUX_1111->new('pv' => 'c5t2d3');
										
	my $pvInfo = $pv->get('status');

=head1 DESCRIPTION

Module is aimed at getting info about physical volume for HP-UX 11.11

=cut

use base qw/
				SysAdmToolkit::Patterns::Prototype
				SysAdmToolkit::Patterns::Getter
			/;

use SysAdmToolkit::Term::Shell;

=head1 PRIVATE PROPERTIES

=over 12

=item pvCmd string

	Property stores command for getting info about PV

=cut

my $pvCmd = 'vxdisk';

=item pvCreateCmd string

	Property stores command for creating PV

=cut

my $pvCreateCmd = '/opt/VRTS/bin/vxdisksetup';

=item pvRmoveCmd string

	Property stores command for removing PV

=cut

my $pvRemoveCmd = '/opt/VRTS/bin/vxdiskunsetup';

=item pvchange string

	Property stores command for changing PV properties

=cut

my $pvchange = 'vxdisk set';

=item recordCmd string

	Private property stores command for getting vx records
	
=cut

my $recordCmd = 'vxprint';

=item availFormats hash ref

	Private property for storing vx formats
	
=back

=cut

my $availFormats = {'hpdisk' => 1, 'cdsdisk' => 1};

=head1 METHODS

=over 12

=item C<_init>

Method _init initializes object and gets all info about PV

params:

	pv string - disk access name, device without device directory
	
=back

=cut

sub _init() {
	
	my $self = shift;
	my %params = @_;
	my $shell = SysAdmToolkit::Term::Shell->new();
	my %dmProps = ();
	
	if(!$params{'pv'}) {
		die "You must specify pv parameter!";	
	} # if
	
	my $pvPath = $params{'pv'};
	
	# first we need group of pv and then with this info we get disk info
	my $pvdisplayCmd = "$pvCmd list $pvPath";
	
	my $pvdisplayInfo = $shell->execCmd('cmd' => $pvdisplayCmd, 'cmdsNeeded' => [$pvCmd]);
	
	if(!$pvdisplayInfo->{'returnCode'}) {
		die("There was some problem getting PV info: " . $pvdisplayInfo->{'msg'} . "\n");
	} # if
	
	my @pvInfo = split('\n', $pvdisplayInfo->{'msg'});
	my %pvInfoMap = map {split /:/} @pvInfo;
	
	my @pvDiskInfo = split(' ', $pvInfoMap{'disk'});
	my @vxDiskName = split('=', $pvDiskInfo[0]);
	my @pvGroupInfo = split(' ', $pvInfoMap{'group'});
	my @vxGroupName = split('=', $pvGroupInfo[0]);
	
	my $pvAllInfo = $shell->execCmd('cmd' => "$recordCmd -g $vxGroupName[1] -adQq $vxDiskName[1]|" . 'grep -v \'^$\'', 'cmdsNeeded' => [$recordCmd, 'grep']);
	
	if(!$pvAllInfo->{'returnCode'}) {
		die("There was some problem getting PV info: " . $pvAllInfo->{'msg'} . "\n");
	} # if

	my @itemInfo = split(' ', $pvAllInfo->{'msg'});
	my $recordType = shift(@itemInfo);
	my $recordName = shift(@itemInfo);
	
	if($recordType eq 'dm') {
		
		for my $itemInfoProp(@itemInfo) {
                 
        	if($itemInfoProp !~ /^[a-zA-Z0-9\_]+=$/) {
                my @pair = split('=', $itemInfoProp);
                $dmProps{$pair[0]} = $pair[1];
         	} # if
                 
         } # for
            
		$pvItems->{$recordType}->{$recordName} = \%dmProps;
		
	} # if
	
	%$self = %dmProps;
	
	$self->{'vgname'} = $vxGroupName[1];
	$self->{'pv'} = $params{'pv'};
	$self->{'pvname'} = $vxDiskName[1]; 
	
	$self->{'changedDevice'} = $self->{'pv'};
	
} # end sub _init

=item C<pvCreate>

METHOD pvCreate creates vx disk with specified format

params:

	disk string - disk device, disk access name
	
	format string - one of two hpdisk cdsdisk
	
return:

	boolean
	
=cut

sub pvCreate($$) {
	
	my $class = shift;
	my %params = @_;
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $disk = $params{'disk'};
	my $format = $params{'format'}; 
	
	if(!$format) {
		$format = 'cdsdisk';	
	} # if
	
	if(!exists($availFormats->{$format})) {
		die("Bad disk format!\n");
	} # if
	
	if(!$disk or !$format) {
		die("You need to provide disk and format!\n");
	} else {
		
		$pvCreateInfo = $shell->execCmd('cmd' => "$pvCreateCmd -i $disk format=$format", 'cmdsNeeded' => [$pvCreateCmd]);
		
		if(!$pvCreateInfo->{'returnCode'}) {
			die("There was some problem while creating PV " . $pvCreateInfo->{'msg'} . "\n");
		} # if
		
	} # if
	
	return $pvCreatInfo->{'returnCode'};
	
} # end sub pvCreate

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
