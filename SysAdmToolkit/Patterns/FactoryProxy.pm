package SysAdmToolkit::Patterns::FactoryProxy;

=head1 NAME

SysAdmToolkit::Patterns::FactoryProxy - module provides base for creating proxy factories

=head1 DESCRIPTION

Proxy factories are classes which are interfaces (that is why proxy) for getting info and internally they get info
by producing specific classes (that is why name factory).

=head1 SYNOPSIS

	# here lvm is derived fromFactoryProxy
	my $lvm = Storage::Lvm->new('type' => 'HPUX');
	# we doesn't care if lvm is for HPUX or Solaris, we just care if they have same property
	$lvm->get('propertyname');

=cut

use base qw/
				SysAdmToolkit::Patterns::Factory
				SysAdmToolkit::Patterns::Proxy
			/;

=head1 METHODS

=over 12

=item C<_init>

Method _init initializies object, produces type specific object, stores it and
queries it for property when requested

=back

=cut
		
sub _init() {
	
	my $self = shift;
	my %params = @_;
	
	if( !exists($params{'type'}) ) {
		die "You must supply type for factory!\n";
	} # if
	
	my $type = $params{'type'};
	
	$type = ucfirst($type);
	
	$self->{'proxy'} = $self->produce('type' => $type, %params);
	
} # end sub _init

sub getClass() {
	
	my $self = shift;
	my %params = @_;
	my $class = ref $self || $self;
	
	if( !exists($params{'type'}) ) {
		die "You must supply type for factory!\n";
	} # if
	
	my $type = $params{'type'};
	
	$type = ucfirst($type);
	
	my $module = $class->SUPER::getClass('type' => $type);
	
	return $module;
	
} # end sub getClass

=head1 DEPENDENCIES

	SysAdmToolkit::Patterns::Factory
	SysAdmToolkit::Patterns::Proxy
				
=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
