package SysAdmToolkit::Storage::Filesystem;

=head1 NAME

SysAdmToolkit::Storage::Filesystem - module provides basic info and tools about filesystem

=head1 SYNOPSIS

	my $filesys = SysAdmToolkit::Storage::Filesystem->new('fs' => '/var');
	$filesys->{'freesize'};

=cut

use base qw/
				SysAdmToolkit::Patterns::Prototype
				SysAdmToolkit::Patterns::Getter
			/;
			
use SysAdmToolkit::Term::Shell;

=head1 PRIVATE VARIABLES

=over 12

=item fsInfoCmd string

Property stores command for getting basic filesystem data

=cut

my $fsInfoCmd = 'df';

=item fsckCmd string

Property stores command for filesystem checking

=cut

my $fsckCmd = 'fsck';

=item fsTypeCmd string

Property stores command for getting filesystem type info

=back

=cut

my $fsTypeCmd = 'fstyp';

=head1 METHODS

=over 12

=item C<_init>

Method _init initializies object, gets all date it can provide about filesystem

	fs
	volume
	totalsize
	freesize
	usedsize
	usedpercentage

params:

	fs or vol string - volume or filesystem mountpoint

=cut

sub _init() {
	
	my $self = shift;
	my %params = @_;
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $fsParam = '';
	
	if(!$params{'fs'} && !$params{'vol'}) {
		die "You need to supply filesystem name or volume name!\n";	
	} elsif($params{'fs'}) {
		$fsParam = $params{'fs'}; 	
	} elsif($params{'vol'}) {
		$fsParam = $params{'vol'};
	}# if

	my $fsBasicInfo = $shell->execCmd('cmd' => "$fsInfoCmd -k " . $fsParam, 'cmdsNeeded' => [$fsInfoCmd]);
	
	my @fsBasicLines = split("\n", $fsBasicInfo->{'msg'});
	my $firstLine = shift(@fsBasicLines);
	my @firstLineParts = split(':', $firstLine);
	
	$firstLineParts[0] =~ s/^(\/.*?)\s/$1/;
	$self->{'fs'} = $1;
	$firstLineParts[0] =~ s/\((.*?)\s*\)/$1/;
	$self->{'volume'} = $1;
	$firstLine =~ /(\d+)\s/;
	$self->{'totalsize'} = $1;
	$fsBasicLines[0] =~ /(\d+)\s/;
	$self->{'freesize'} = $1;
	$fsBasicLines[1] =~ /(\d+)\s/;
	$self->{'usedsize'} = $1;
	$fsBasicLines[2] =~ /(\d+)\s/;
	$self->{'usedpercentage'} = $1;	
	
} # end sub _init

=item C<fsck>

Method fsck check filesystem consistency

param:

	$lvolName string

return:

	boolean

=back

=cut

sub fsck($) {
	
	my $self = shift;
	my $lvolName = shift;
	my $shell = SysAdmToolkit::Term::Shell->new();
	
	my $fsTypeResult = $shell->execCmd('cmd' => "$fsTypeCmd $lvolName", 'cmdsNeeded' => [$fsTypeCmd]);
	my $fsType = $fsTypeResult->{'msg'};
	my $fsOptions = '';
	
	if($fsType eq 'vxfs') {
		$fsOptions = ' -o full';
	} # if
	
	my $fsckStatus = $shell->execCmd('cmd' => "$fsckCmd -F $fsType $fsOptions -y $lvolName", 'cmdsNeeded' => [$fsckCmd]);
	
	return $fsckStatus->{'returnCode'};
	
} # end sub fsck

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
