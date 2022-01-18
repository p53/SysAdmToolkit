package SysAdmToolkit::Machine::Info;

=head1 NAME

SysAdmToolkit::Machine::Info - interface module for getting basic info about UNIX machine

=head1 SYNOPSIS

	my $machInfo = SysAdmToolkit::Machine::Info->new();
										
	my $os = $machInfo->get('os');

=head1 DESCRIPTION

Module is interface module for getiing basic info about machine, 
like operating system, os version, number of cpu, ram

=cut

use base 'SysAdmToolkit::Patterns::OsFactoryProxy';

use SysAdmToolkit::Term::Shell;
use SysAdmToolkit::File::Config::LibXml;
use Cwd 'abs_path';

=head1 METHODS

=over 12

=item C<_init>

Metdhod _init gets OS name and version and according that chooses proxy
module for getting OS and OS version specific module

=cut

sub _init() {
	
	my $self = shift;
	my $class = ref($self);
	$class =~ /^([a-zA-Z_0-9]+)::.*/;
	my $libDir = $1;
        
    $self->{'xmlConfig'} = SysAdmToolkit::File::Config::LibXml->new(
                                                        'xmlFile' => abs_path() . "/$libDir/libconfig.xml"
                                                );
									
	my $osInfo = $self->checkOs();
		
	# here we get os and os version specific module
	$self->SUPER::_init('os' => $osInfo->{'os'}, 'ver' => $osInfo->{'ver'});

} # end sub _init

=item C<checkOs>

Method checkOs checks for current OS and version by recursing config xml file

return:

	hash ref
	
=back

=cut

sub checkOs() {
	
	my $self = shift;
	my $xmlOs = $self->{'xmlConfig'}->getElements('source' => $self->{'xmlConfig'}->{'xml'}, 'path' => '/libconfig/os');
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $osData = {};

	foreach my $osItem(@$xmlOs) {
		
		my $osName = $self->{'xmlConfig'}->getValue('source' => $osItem, 'path' => 'osname/name');
		my $osGetCmd = $self->{'xmlConfig'}->getValue('source' => $osItem, 'path' => 'osname/cmd');
		my $cmdsOsNeeded = $self->{'xmlConfig'}->getArray('source' => $osItem, 'path' => 'osname/cmds');
		
		my $osNameInfo = $shell->execCmd('cmd' => "$osGetCmd", 'cmdsNeeded' => $cmdsOsNeeded);
		
		if(!$osNameInfo->{'returnCode'}) {
			die("There was some problem getting OS name: " . $osNameInfo->{'msg'} . "!\n");
		} # if
		
		if($osName eq $osNameInfo->{'msg'}) {
			
			my $osVersion = $self->{'xmlConfig'}->getValue('source' => $osItem, 'path' => 'osversion/version');
			my $osVerGetCmd = $self->{'xmlConfig'}->getValue('source' => $osItem, 'path' => 'osversion/cmd');
			my $cmdsVerNeeded = $self->{'xmlConfig'}->getArray('source' => $osItem, 'path' => 'osversion/cmds');
			
			my $osVerInfo = $shell->execCmd('cmd' => "$osVerGetCmd", 'cmdsNeeded' => $cmdsVerNeeded);
			
			if(!$osVerInfo->{'returnCode'}) {
				die("There was some problem getting OS version: " . $osVerInfo->{'msg'} . "!\n");
			} # if	
			
			if($osVersion !~ $osVerInfo->{'msg'}) {
				die("OS or OS version are unsupported by this library!\n");
			} # if
			
			$osVerInfo->{'msg'} =~ s/\.//;
			$osName =~ s/\-|\s+//g;
			
			$osData->{'os'} = $osName;
			$osData->{'ver'} = $osVerInfo->{'msg'};
			
			last;
			
		} # if
		
	} # foreach
	
	return $osData;
	
} # end sub checkOs

=head1 DEPENDECIES

	SysAdmToolkit::Patterns::OsFactoryProxy
	SysAdmToolkit::Term::Shell

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
