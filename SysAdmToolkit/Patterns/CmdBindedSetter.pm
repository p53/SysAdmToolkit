package SysAdmToolkit::Patterns::CmdBindedSetter;

use base qw/
				SysAdmToolkit::Patterns::Getter
			/;

use SysAdmToolkit::Term::Shell;

=head1 NAME

SysAdmToolkit::Patterns::CmdBindedSetter - module provides base for creating classes with generic setter and executes command
										   which sets property of real OS object

=head1 SYNOPSIS

	# here lvm is derived from OsFactoryProxy and we derive also from Setter
	my $pv = SysAdmToolkit::Lvm::PhysicalVolume->new('os' => 'HPUX', 'ver' => '1131', 'pv' => '/dev/dsk/disk21');
	# we doesn't care if lvm is for HPUX or Solaris, we just care if they have same property
	$pv->get('status');
	# this changes PV status to unavailable and if change was successful also state of object
	$pv->set('status' => 'n');

=head1 METHODS

=over 12

=item C<set>

Method set is generic setter

param:

	$property string

	$value mixed

return:

	$self object

=back

=cut

our $changeCmd = '';
our $settable = {};

sub set($) {
	
	my $self= shift;
	my %params = @_;
	my $changedProperties = '';
	my $passed = 0;
	
	my $settableStatic = $self->getStatic('settable');
	my $changeCmdStatic = $self->getStatic('changeCmd');
	
	for my $setParam(keys %params) {
		
			if(exists($settableStatic->{$setParam})) {
				
				my $regex = $settableStatic->{$setParam}->{'verify'};
				my $setCmd = $settableStatic->{$setParam}->{'cmd'};
				my $value = $params{$setParam};
				
				if($value =~ /$regex/) {
					$changedProperties .= "$setCmd $value ";
				} else {
					die("You supplied invalid value: $value for the property: $property!\n");
					$passed = 0;
				} # if
			
			} else {
				die "You cannot set non-existent property: $property!\n";
			} # if
			
	} # for
	
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $changeResult = $shell->execCmd('cmd' => "$changeCmdStatic $changedProperties" . $self->{'changedDevice'}, 'cmdsNeeded' => [$changeCmdStatic]);
	my $changedDev = $self->{'changedDevice'};
	
	if($changeResult->{'returnCode'}) {
		my $par = {%$self};
		$self->_init(%$par);
		$self->{'changedDevice'} = $changedDev;
		$passed = 1;
	} else {
		warn("There was problem setting property $property " . $changeResult->{'msg'});
		$passed = 0;
	} # if
			
	return $passed;
	
} # end sub set

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
