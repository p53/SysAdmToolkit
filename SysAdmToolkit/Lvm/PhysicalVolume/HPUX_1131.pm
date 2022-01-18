package SysAdmToolkit::Lvm::PhysicalVolume::HPUX_1131;

=head1 NAME

SysAdmToolkit::Lvm::PhysicalVolume::HPUX_1131 - OS and version specific module for getting info about physical volume

=head1 SYNOPSIS

	my $pv= SysAdmToolkit::Lvm::PhysicalVolume::HPUX_1131->new('pv' => '/dev/disk/disk12');
										
	my $pvInfo = $pv->get('status');

=head1 DESCRIPTION

Module is aimed at getting info about physical volume for HP-UX 11.31

=cut

use base qw/
				SysAdmToolkit::Patterns::Prototype
				SysAdmToolkit::Patterns::Getter
				SysAdmToolkit::Patterns::CmdBindedSetter
			/;

use SysAdmToolkit::Term::Shell;

=head1 PRIVATE PROPERTIES

=over 12

=item pvCmd string

	Property stores command for getting info about PV

=cut

my $pvCmd = 'pvdisplay';

=item pvCreateCmd string

	Property stores command for creating PV

=cut

my $pvCreateCmd = 'pvcreate';

=item pvRmoveCmd string

	Property stores command for removing PV

=cut

my $pvRemoveCmd = 'pvremove';

=item pvChangeCmd string

	Property stores command for changing PV properties

=cut

my $pvchange = 'pvchange';

=item devCharBase string

	Property stores location of character device files for pv

=cut

my $devCharBase = '/dev/rdisk/';

=item devBlockBase string

	Property stores location of block device files for pv

=cut

my $devBlockBase = '/dev/disk/';

=item basicProperties array

	Property stores basic properties of PV which are available to get

	pvname
	vgname
	status
	allocatable
	vgda
	lvcount
	pesize
	totalpe
	freepe
	allocpe
	stalepe
	timeout
	autoswitch
	polling

=back

=cut

my @basicProperties = qw/
							pvname
							vgname
							status
							allocatable
							vgda
							lvcount
							pesize
							totalpe
							freepe
							allocpe
							stalepe
							timeout
							autoswitch
							polling
						/;

=item changeCmd string

	Property stores command for changing PV, this is needed for setting
	properties
	
=cut

our $changeCmd = 'pvchange';

our $settable = {
					'status' => {'cmd' => "-a", 'verify' => 'y|n|N'},
					'timeout' => {'cmd' => "-t", 'verify' => '\d+'},
					'autoswitch' => {'cmd' => "-S", 'verify' => 'y|n'},
					'polling' => {'cmd' => "-p", 'verify' => 'y|n'}
				};
				
=head1 METHODS

=over 12

=item C<_init>

Method _init initializes object and gets all info about PV

=back

=cut

sub _init() {
	
	my $self = shift;
	my %params = @_;
	my $shell = SysAdmToolkit::Term::Shell->new();
		
	if(!$params{'pv'}) {
		die "You must specify pv parameter!";	
	} # if
	
	my $pvPath = $devBlockBase . $params{'pv'};
	
	# we are getting info about PV and also about LV's on PV
	my $pvdisplayCmd = "$pvCmd $pvPath |grep -v '\\-\\-\\-'|awk '{print \$NF}'";
	my $pvLvInfoCmd = "$pvCmd -v $pvPath |grep -Ev '[0-9]{5}'|grep '/dev/'|grep -vE '^[A-Z]'|awk '{print \$1}'";
	
	my $pvdisplayInfo = $shell->execCmd('cmd' => $pvdisplayCmd, 'cmdsNeeded' => [$pvCmd, 'grep', 'awk']);
	my $pvLvInfo = $shell->execCmd('cmd' => $pvLvInfoCmd, 'cmdsNeeded' => [$pvCmd, 'grep', 'awk']);
	
	if(!$pvdisplayInfo->{'returnCode'}) {
		warn("There was some problem getting PV info: " . $pvdisplayInfo->{'msg'} . "\n");
	} # if
	
	my @pvInfo = split("\n", $pvdisplayInfo->{'msg'});
	my @pvLvs = split("\n", $pvLvInfo->{'msg'});
	
	foreach my $index(0..$#basicProperties) {
		$self->{$basicProperties[$index]} = $pvInfo[$index];
	} # foreach
	
	$self->{'changedDevice'} = $self->{'pvname'};
	$self->{'lvs'} = \@pvLvs;
	
} # end sub _init

sub pvCreate($) {
	
	my $class = shift;
	my %params = @_;
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $disk = $params{'disk'};
	my $diskCharFile = $devCharBase . $disk;
	my $pvname = $devBlockBase . $disk;
	
	if(!$disk) {
		die "You need to provide disk!\n";
	} else {
		
		$pvCreateInfo = $shell->execCmd('cmd' => "$pvCreateCmd " . $diskCharFile, 'cmdsNeeded' => [$pvCreateCmd]);
		
		if(!$pvCreateInfo->{'returnCode'}) {
			die("There was some problem while creating PV " . $pvCreateInfo->{'msg'} . "\n");
		} # if
		
	} # if
	
	return $pvCreatInfo->{'returnCode'};
	
} # end sub pvCreate

sub getBlockDev() {
	
	my $self = shift;
	
	return $devBlockBase;
	
} # end sub getBlockDev

sub getCharDev() {
	
	my $self = shift;
	
	return $devCharBase;
	
} # end sub getCharDev

=head1 DEPENDENCIES

	SysAdmToolkit::Patterns::Prototype
	SysAdmToolkit::Patterns::Getter
	SysAdmToolki::Patterns::CmdBindedSetter
	SysAdmToolkit::Term::Shell

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
