package SysAdmToolkit::Lvm::VolumeGroup::HPUX_1131;

=head1 NAME

SysAdmToolkit::Lvm::VolumeGroup::HPUX_1131; - OS and version specific module for getting info aboul LVM volume group

=head1 SYNOPSIS

	my $vg = SysAdmToolkit::Lvm::VolumeGroup::HPUX_1131->new('vg' => 'vgroot');
										
	my $vgInfo = $vg->get('maxpv');

=head1 DESCRIPTION

Module is aimed at getting info about volume group on HP-UX 11.31

=cut

use base qw/
				SysAdmToolkit::Lvm::VolumeGroup::HPUX_1111
				SysAdmToolkit::Patterns::CmdBindedSetter
			/;

=item vgCreateCmd string

	Property stores command for creating volume group

=cut

my $vgCreateCmd = 'vgcreate';

=item vgRemoveCmd string

	Property stores command for removing volume group

=cut

my $vgRemoveCmd = 'vgremove';

=item changeCmd string

	Property stores command for changing Vg, this is needed for setting
	properties
	
=cut

our $changeCmd = 'vgchange';

our $settable = {
					'status' => {'cmd' => "-a", 'verify' => 'y|n|e|s|r'},
					'cluster' => {'cmd' => "-c", 'verify' => 'y|n'},
					'sharable' => {'cmd' => "-S", 'verify' => 'y|n'},
				};
				
our $createParams = {
						'pesize' => '-s',
						'maxlvs' => '-l',
						'maxpvs' => '-p',
						'maxpes' => '-e'
					};

sub vgCreate() {
	
	my $self = shift;
	my %params = @_;
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $pvs = $params{'pvs'};
	my $vgname = $params{'vgname'};
	my $class = ref($self) || $self;
	my $size = @$pvs;
	
	no strict 'refs';
	
	my $variable = $class . '::createParams';
	my $createParams = $$variable;
	my $vgCreateParams = '';
	
	for my $createParam(keys %$createParams) {
		if(exists($params{$createParam})) {
			$vgCreateParams .= $createParams->{$createParam} . ' ' . $params{$createParam} . ' ';
		} # if
	} # for
	
	if(!$vgname) {
		die "You need to provide name fo new VG!\n";
	} # if
	
	if(-d "/dev/$vgname") {
		die "There already exists directory /dev/$vgname !\n";
	} # if
	
	if(!$pvs || ($size == 0)) {
		die "You didn't supply pvs!\n";
	} # if
	
	my $vgPvs = join(' ', @$pvs);
	
	$vgCreateInfo = $shell->execCmd('cmd' => "$vgCreateCmd $vgCreateParams $vgname $vgPvs", 'cmdsNeeded' => [$vgCreateCmd]);
	
	if(!$vgCreateInfo->{'returnCode'}) {
		die("There was some problem while creating VG " . $vgCreateInfo->{'msg'} . "\n");
	} # if
	
	my $register = SysAdmToolkit::Lvm::Register->new();
	$register->{'vgs'}->{"/dev/$vgname"} = 1;
	
	foreach my $pv(@$pvs){
			$register->{'pvs'}->{$pv} = 1;
	} # foreach
		
	return $vgCreateInfo->{'returnCode'};
	
} # end sub vgCreate
					
=head1 DEPENDECIES

	SysAdmToolkit::Lvm::VolumeGroup::HPUX_1111

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
