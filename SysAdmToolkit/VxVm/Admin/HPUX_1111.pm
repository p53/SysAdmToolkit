package SysAdmToolkit::VxVm::Admin::HPUX_1111;

=head1 NAME

SysAdmToolkit::VxVm::Admin::HPUX_1111 - HP-UX 11.11 specific module for getting high level info about VxVm on machine

=head1 SYNOPSIS

	my $lvmAdmin = SysAdmToolkit::VxVm::Admin::HPUX_1111->new();
	$lvmAdmin->getPvs();
	
=head1 DESCRIPTION

Module should help in getting higher level info about VxVm on the machine
about lvs, pvs, vgs

=cut

use base qw/
				SysAdmToolkit::Patterns::Prototype
				SysAdmToolkit::Patterns::Getter
			/;

use SysAdmToolkit::Term::Shell;

=head1 PRIVATE PROPERTIES

=over 12

=item recordCmd string

Private property stores command for getting VxVm records

=cut

my $recordCmd = 'vxprint';

=item vxDiskCmd string

Private property vxDiskCmd stores command for getting VxVm info about Vx disks

=cut

my $vxDiskCmd = 'vxdisk';

=item dgCmd string

Private property dgCmd stores command for getting overview info about DG

=back

=cut

my $dgCmd = 'vxdg';

=head1 METHODS

=over 12

=item C<getVgs>

METHOD getVgs returns array of all DG's (active, disabled not deported)

return:

	array - array of DG's
	
=cut

sub getVgs() {
	
	my $self = shift;
	my $shell = SysAdmToolkit::Term::Shell->new();
	my @vgs = ();

	my $vgdisplayInfo = $shell->execCmd('cmd' => "$dgCmd -q list|awk '{print \$1}'", 'cmdsNeeded' => [$dgCmd, 'awk']);
	
	if(!$vgdisplayInfo->{'returnCode'}) {
		die("There was some problem getting VG's info: " . $vgdisplayInfo->{'msg'} . "\n");
	} # if
	
	@vgs = split("\n", $vgdisplayInfo->{'msg'});
	
	return \@vgs;
	
} # end sub getVgs

=item C<getLvs>

METHOD getLvs returns array of volumes in the form vgname/lvname

return:

	array - array of volumes
	
=cut

sub getLvs() {
	
	my $self = shift;
	my $shell = SysAdmToolkit::Term::Shell->new();
	my @lvs = ();

	my $checkLvNum = $shell->execCmd('cmd' => "$recordCmd -S|awk '{print $1}'", 'cmdsNeeded' => [$recordCmd, 'grep']);
	
	# we need to check if number of volumes is greater than zero otherwise -v option would fail with nonzero code
	if($checkLvNum->{'msg'} && $checkLvNum->{'msg'} > 0) {
		
		my $lvdisplayInfo = $shell->execCmd('cmd' => "$recordCmd -vq|" . 'grep -v \'^$\'', 'cmdsNeeded' => [$recordCmd, 'grep']);
		
		if(!$lvdisplayInfo->{'returnCode'}) {
			die("There was some problem getting LV's info: " . $lvdisplayInfo->{'msg'} . "\n");
		} # if
		
		my @lvInfoByGroup = split("Disk group: ", $lvdisplayInfo->{'msg'});
		
		shift(@lvInfoByGroup);
		
		for my $lvsByGroup(@lvInfoByGroup) {
			
			my @groupedLvs = split("\n", $lvsByGroup);
			my $vgname = shift(@groupedLvs);
			
			for my $lvOfGroup(@groupedLvs) {
				my @lvInfo = split(" ", $lvOfGroup);
				my $lvName = $lvInfo[1];
				push(@lvs, "$vgname/$lvName");
			} # for
			
		} # for
	
	} # if
	
	return \@lvs;
	
} # end sub getLvs

=item C<getPvs>

METHOD getPvs gets all vx disks

return:

	hash ref - hash of vx disks in the form diskaccess name => diskmedia name
	
=cut

sub getPvs() {
	
	my $self = shift;
	my $shell = SysAdmToolkit::Term::Shell->new();
	my %pvs = ();

	my $pvdisplayInfo = $shell->execCmd('cmd' => "$vxDiskCmd -q list|grep -v '-'|" . 'awk \'{print $4"/"$3" "$1}\'', 'cmdsNeeded' => [$vxDiskCmd, 'awk']);
	
	if(!$pvdisplayInfo->{'returnCode'}) {
		die("There was some problem getting PV's info: " . $pvdisplayInfo->{'msg'} . "\n");
	} # if
	
	@pvsInfo = split("\n", $pvdisplayInfo->{'msg'});
	
	for my $pvLine(@pvsInfo) {
		my @pvInfo = split(" ", $pvLine);
		$pvs{$pvInfo[0]} = $pvInfo[1];
	} # for
	
	return \%pvs;
	
} # end sub getPvs

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
