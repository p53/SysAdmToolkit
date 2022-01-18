package SysAdmToolkit::Patterns::Getter;

=head1 NAME

SysAdmToolkit::Patterns::Getter - module provides base for creating classes with generic getter

=head1 SYNOPSIS

	# here lvm is derived from OsFactoryProxy and we derive also from Getter
	my $lvm = Storage::Lvm->new('os' => 'HPUX', 'ver' => '1131');
	# we doesn't care if lvm is for HPUX or Solaris, we just care if they have same property
	$lvm->get('propertyname');

=head1 METHODS

=over 12

=item C<get>

Method set is generic getter

param:

	$property string

return:

	mixed

=back

=cut

sub get($) {
	
	my $self= shift;
	my $property = shift;

	if(exists($self->{$property})) {
		return $self->{$property};
	} else {
		die "Query for non-existent property: $property!\n";
	} # if
	
} # end sub get

sub getStatic($) {
	
	my $self = shift;
	my $staticProperty = shift;
	
	my $class = ref($self) || $self;
	my $variable = $class . '::' . $staticProperty;
	
	no strict 'refs';
	
	return $$variable;
	
} # end sub getStatic

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
