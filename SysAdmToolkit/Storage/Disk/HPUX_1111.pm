package SysAdmToolkit::Storage::Disk::HPUX_1111;

=head1 NAME

SysAdmToolkit::Storage::Disk::HPUX_1111 - this is HP-UX 11.11 specific module for getting info about disk/lun

=head1 SYNOPSIS

	my $mydisk = SysAdmToolkit::Storage::Disk::HPUX_1111->new('hwPath' => '4/0/1/3/2.1.2');
	my $mydisksecond = SysAdmToolkit::Storage::Disk::HPUX_1111->new('devFile' => '/dev/dsk/c2t1d2');
	$mydisk->{'driver'};
	$mydisksecond->{'hwPath'};

=cut

use base qw/
				SysAdmToolkit::Patterns::Prototype
				SysAdmToolkit::Patterns::Getter
			/;


use SysAdmToolkit::Term::Shell;
use SysAdmToolkit::Storage::Lun;

=head1 PRIVATE PROPERTIES

=over 12

=item scanCmd string

Property stores command for scanning io devices

=cut

my $scanCmd = 'ioscan';

=item devCharBase string

Property stores location of character device files for disks

=cut

my $devCharBase = '/dev/rdsk/';

=item devBlockBase string

Property stores location of block device files for disks

=cut

my $devBlockBase = '/dev/dsk/';

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

=cut

sub _init() {
	
	my $self = shift;
	my %params = @_;
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $scan = "$scanCmd -fk";
	my $identifier = '';
	my $options = '';
	
	if($params{'hwPath'}) {
		$identifier = $params{'hwPath'};
		$options = '-H';
	} elsif($params{'instance'}) {
		$identifier = $params{'instance'};
		$options= '-C disk -I';
	} elsif($params{'devFile'}) {
		$identifier = $params{'devFile'};
	} else {
		die "There must be just one parameter passed: hwPath, instance or devFile!\n";
	} # if
	
	# first we get parsable output it doesn't contain device files, device files are from the second command
	my $generalInfo = $shell->execCmd('cmd' => "$scan -F $options $identifier", 'cmdsNeeded' => [$scanCmd]);
	my $devFileInfo = $shell->execCmd('cmd' => "$scan -n $options $identifier", 'cmdsNeeded' => [$scanCmd]);
	
	# here we are parsing output from ioscan to get device file info
	my @deviceFileInfoMix = split("\n", $devFileInfo->{'msg'});
	my @deviceFiles = grep {$_ =~ '/dev/'} @deviceFileInfoMix;
	my @charDevFiles = ();
	my @blkDevFiles = ();
	
	foreach my $devFilePair(@deviceFiles) {
		my @pair = split(" ", $devFilePair);
		push(@blkDevFiles, $pair[0]);
		push(@charDevFiles, $pair[1]);
	} # foreach
	
	if(!($generalInfo->{'returnCode'} && $devFileInfo->{'returnCode'})) {
		warn("Hw scanning had some issues!\n");	
	} # if
	
	# each property in property list is in the parsable output and for each we assing value
	my @generalProperties;
	$generalProperties[$#propertiesList] = undef;
	@generalProperties = split(':', $generalInfo->{'msg'});
	
	foreach my $index(0..$#propertiesList) {
		$self->{$propertiesList[$index]} = $generalProperties[$index];
	} # foreach
	
	$self->{'blkdevfile'} = \@blkDevFiles;
	$self->{'chardevfile'} = \@charDevFiles;
	
} # end sub _init

=item C<getDiskLun>

METHOD getDiskLun gets lun object tied to disk

return:

	SysAdmToolkit::Storage::Lun
	
=cut

sub getDiskLun(){
	
	my $self = shift;
	
	my $lunObj = SysAdmToolkit::Storage::Lun->new('devFile' => $self->{'blkdevfile'}, 'os' => $self->get('os'), 'ver' => $self->get('ver'));
	
	return $lunObj;
	
} # end sub getDiskLun

=item C<getBlockDev>

METHOD getBlockDev is getter for private property devBlockBase

return:

	$devBlockBase string - returns block device file directory
	
=cut

sub getBlockDev() {
	
	my $self = shift;
	
	return $devBlockBase;
	
} # end sub getBlockDev

=item C<getCharDev>

METHOD getCharkDev is getter for private property devCharBase

return:

	$devCharBase string - returns character device file directory
	
=back

=cut

sub getCharDev() {
	
	my $self = shift;
	
	return $devCharBase;
	
} # end sub getCharDev

=head1 DEPENDENCIES

	SysAdmToolkit::Patterns::Prototype
	SysAdmToolkit::Patterns::Getter
	SysAdmToolkit::Term::Shell
	SysAdmToolkit::Storage::Lun

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
