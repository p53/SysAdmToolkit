package SysAdmToolkit::Patterns::OsFactoryProxy;

=head1 NAME

SysAdmToolkit::Patterns::OsFactoryProxy - module provides base for creating proxy factories based on Os type and version

=head1 DESCRIPTION

Proxy factories are classes which are interfaces (that is why proxy) for getting info and internally they get info
by producing specific classes (that is why name factory).

=head1 SYNOPSIS

	# here lvm is derived from OsFactoryProxy
	my $lvm = Storage::Lvm->new('os' => 'HPUX', 'ver' => '1131');
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

Method _init initializies object, produces OS and OS version specific object, stores it and
queries it for property when requested

=back

=cut
		
sub _init() {
	
	my $self = shift;
	my %params = @_;
	
	if(!($params{'os'} && $params{'ver'} && $params{'ver'} =~ /\d+/)) {
		die "You must supply Os name and it's version (version must be only numbers)!\n";
	} # if
	
	my $type = $params{'os'} . '_' . $params{'ver'};
	
	$type = ucfirst($type);
	
	$self->{'proxy'} = $self->produce('type' => $type, %params);
	
} # end sub _init

sub getClass() {
	
	my $self = shift;
	my %params = @_;
	my $class = ref $self || $self;
	
	if(!($params{'os'} && $params{'ver'} && $params{'ver'} =~ /\d+/)) {
		die "You must supply Os name and it's version (version must be only numbers)!\n";
	} # if
	
	my $type = $params{'os'} . '_' . $params{'ver'};
	
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
