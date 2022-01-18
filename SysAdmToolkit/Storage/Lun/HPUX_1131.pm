package SysAdmToolkit::Storage::Lun::HPUX_1131;

=head1 NAME

SysAdmToolkit::Storage::Lun::HPUX_1131 - this is HP-UX 11.31 specific module for getting info about lun

=head1 SYNOPSIS

	my $myLun = SysAdmToolkit::Storage::Lun::HPUX_1131->new();
	my $frame = $myLun->get('frame');

=head1 DESCRIPTION

Module should help in getting info about lun

=cut

use base qw/
				SysAdmToolkit::Patterns::Prototype
				SysAdmToolkit::Patterns::Getter
			/;


use SysAdmToolkit::Term::Shell;

=head1 PRIVATE PROPERTIES

=over 12

=item charDevBase string

Private property charDevBase is directory for character device files os version specific

=cut

my $charDevBase = '/dev/rdisk/';

=item blockDevBase string

Private property blockDevBase is directory for character device files os version specific

=cut


my $blockDevBase = '/dev/disk/';

=item diskInfoCmd string

Private property diskInfoCmd stores command for getting some disk info

=cut

my $diskInfoCmd = 'diskinfo';

=item arrayTypesCmd hash

Private property stores commands needed for getting info about storage from several vendors

=cut

my %arrayTypesCmd = (
						'hp' => {'cmd' => 'evainfo', 'options' => '-lpd'},
						'hitachi' => {'cmd' => 'inqraid', 'options' => '-CLIWP -fcx'},
						'emc' => {'cmd' => 'inq.hpux64' , 'options' => '-showvol -nodots -sid -f_emc -dev'},
					);

=item emcProperties array

Private property contains properties valid for EMC storage

=cut

my @emcProperties = qw/
						dev
						vendor
						product
						rev
						serial
						lunid
						size
						frame
					/;

=item hitachiProperties array

Private property contains properties valid for HITACHI storage

=cut

my @hitachiProperties = qw/
							dev
							pwwn
							al
							port
							lun
							frame
							lunid
							product
						/;

=item evaProperties array

Private property contains properties for EVA storage

=back

=cut
						
my @evaProperties = qw/
						dev
						path
						tgt
						lun
						frame
						port
						vendor
						product
						revision
						ctrl
						lunid
						size
						props
					/;

=head1 METHODS

=over 12

=item C<_init>

METHOD _init initializies lun object and lun info

return:

	$self
	
=cut
				
sub _init() {
	
	my $self = shift;
	my %params = @_;
	my $devFile = $params{'devFile'};
	my $lunsProcessed = [];
	my %diskInfoProps = ();
	my $type = '';
	
	if($devFile !~ m#$blockDevBase#) {
		die("You must specify block device file\n!");	
	} # if
	
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $lunAdmin = SysAdmToolkit::Storage::Lun::Admin->new('os' => $self->get('os'), 'ver' => $self->get('ver'));
	
	$devFile =~ s#$blockDevBase#$charDevBase#;
	
	my $diskInfo = $shell->execCmd('cmd' => "$diskInfoCmd $devFile", 'cmdsNeeded' => [$diskInfoCmd, 'grep']);
	
	if(!$diskInfo->{'returnCode'}) {
		die("There was some problem running command $diskInfoCmd: " . $diskInfo->{'msg'} . "!\n");	
	} # if
	
	my @diskInfoLines = split("\n", $diskInfo->{'msg'});
	
	for my $diskInfoLine(@diskInfoLines) {
		my @pair = split(":", $diskInfoLine);
		$pair[0] =~ s/\s+//g;
		$pair[1] =~ s/\s+//g;
		$diskInfoProps{$pair[0]} = $pair[1];
	} # for
	
	$type = lc($diskInfoProps{'vendor'});
	
	if(!(exists($arrayTypesCmd{$type}))) {
		die("Module doesn't work for vendor $type!\n");	
	} # if
	
	my $storageCmd = $arrayTypesCmd{$type}->{'cmd'};
	my $storageOpt = $arrayTypesCmd{$type}->{'options'};
	my $parseMethod = 'parse' . ucfirst($type);
	
	if($shell->isCmdPresent($storageCmd)) {
		
		my $lunsInfoCmd = $shell->execCmd('cmd' => "$storageCmd $storageOpt $devFile|grep -v 'Inquiry utility'|grep -v 'For help'|grep -v 'Copyright'|grep -v ':SER NUM'|grep -v '\\---------------'|grep -v '^$'", 'cmdsNeeded' => [$storageCmd, 'grep']);
		
		if(!$lunsInfoCmd->{'returnCode'}) {
			die("There was some problem getting Lun info: " . $lunsInfoCmd->{'msg'} . "!\n");
		} # end if
	
		my @luns = split("\n", $lunsInfoCmd->{'msg'});
		$lunsProcessed = $lunAdmin->$parseMethod('luns' => \@luns);
	
	} # if
	
	my $lunHash = $lunsProcessed->[0];
	
	%$self = (%$lunHash);
	
	return $self;
	
} # end sub _init

=item C<getLunDisk>

METHOD getLunDisk gets disk object for lun

return:

	SysAdmToolkit::Storage::Disk
	
=back

=cut

sub getLunDisk(){
	
	my $self = shift;

	my $diskClass = SysAdmToolkit::Storage::Disk->getClass('os' => $self->get('os'), 'ver' => $self->get('ver'));
	my $charDev = $diskClass->getCharDev();
	my $diskObj = SysAdmToolkit::Storage::Disk->new('devFile' => $charDev . $self->{'dev'}, 'os' => $self->get('os'), 'ver' => $self->get('ver'));
	
	return $diskObjs;
	
} # end sub getLunDisk

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
