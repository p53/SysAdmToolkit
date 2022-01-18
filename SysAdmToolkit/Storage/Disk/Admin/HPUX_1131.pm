package SysAdmToolkit::Storage::Disk::Admin::HPUX_1131;

=head1 NAME

SysAdmToolkit::Storage::Disk::Admin::HPUX_1131 - this is HP-UX 11.31 specific module for getting info about disk

=head1 SYNOPSIS

	my $diskAdmin = SysAdmToolkit::Storage::Disk::Admin::HPUX_1131->new();
	my $allDisks = $diskAdmin->getDisks();
	
=cut

use base qw/
				SysAdmToolkit::Patterns::Prototype
				SysAdmToolkit::Patterns::Getter
			/;

use SysAdmToolkit::Term::Shell;
use File::stat;

=head1 PRIVATE PROPERTIES

=over 12

=item scanCmd string

Property stores command for scanning io devices

=cut

my $scanCmd = 'ioscan';

=item devCharBase string

Property stores location of character device files for disks

=cut

my $devCharBase = '/dev/rdisk/';

=item devBlockBase string

Property stores location of block device files for disks

=cut

my $devBlockBase = '/dev/disk/';

=item propertiesList array

Property holds basic properties of disk which module provides

	bustype
	cdio
	is_block
	is_char
	is_pseudo
	blkmajnu
	charmajnu
	minnum
	class
	driver
	hwpath
	identifybytes
	instance
	modpath
	modname
	swstate
	hwtype
	description
	cardinst

=back

=cut

my @propertiesList = qw/
							bustype
							cdio
							is_block
							is_char
							is_pseudo
							blkmajnu
							charmajnu
							minnum
							class
							driver
							hwpath
							identifybytes
							instance
							modpath
							modname
							swstate
							hwtype
							description
							cardinst
						/;

=head1 METHODS

=over 12

=item C<_init>

METHOD _init initializies object and all properties it can provide

params:

	hwPath - string or instance - number or devFile - string

=back

=cut

sub getDisks() {
	
	my $self = shift;
	my %params = @_;
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $scanningOption = 'AeFNC disk';
	my %devMinorMap = ();
	my $scanOption = $params{'scan'};
	my @allDisks = ();
	
	if(!(exists($params{'scan'}))) {
		die("You must supply scan parameter!\n");
	} # if
	
	if($scanOption == 1) {
		$scanningOption = '-' . $scanningOption;
	} elsif ($scanOption == 0) {
		$scanningOption = '-k' . $scanningOption;
	} # if
	
	my $scan = "$scanCmd $scanningOption";
		
	my $generalInfoAll = $shell->execCmd('cmd' => "$scan", 'cmdsNeeded' => [$scanCmd]);
	
	if(!$generalInfoAll->{'msg'}) {
		die("There was some problem running command $scan: " . $generalInfoAll->{'msg'} . "!\n");	
	} # if
	
	my @infoAll = split("\n", $generalInfoAll->{'msg'});
	
	my @devs = glob($devCharBase . '*');
	
	for my $device(@devs) {
		my $st = stat($device);
		my $rdev = $st->rdev;
		my $minorDec = ($rdev << 8) >> 8;
		$devMinorMap{$minorDec} = $device; 
	} # for
	
	for my $oneDev(@infoAll) {
		
		my @generalProperties;
		$generalProperties[$#propertiesList] = undef;
		@generalProperties = split(':', $oneDev);
		my %diskProps = ();

		foreach my $index(0..$#propertiesList) {
			$diskProps{$propertiesList[$index]} = $generalProperties[$index];
		} # foreach
	
		my $charDevFile = $devMinorMap{$diskProps{'minnum'}};
		my $blockDevFile = '';
		
		$charDevFile =~ /^$devCharBase(.*)$/;
		$blockDevFile = $devBlockBase . $1;
		
		$diskProps{'blkdevfile'} = $blockDevFile;
		$diskProps{'chardevfile'} = $charDevFile;
	
		push(@allDisks, \%diskProps);
		
	} # for
	
	return \@allDisks;
	
} # end sub getDisks

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
