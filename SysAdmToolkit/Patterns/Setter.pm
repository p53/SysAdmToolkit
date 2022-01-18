package SysAdmToolkit::Patterns::Setter;

=head1 NAME

SysAdmToolkit::Patterns::Setter - module provides base for creating classes with generic setter

=head1 SYNOPSIS

	# here lvm is derived from OsFactoryProxy and we derive also from Setter
	my $lvm = Storage::Lvm->new('os' => 'HPUX', 'ver' => '1131');
	# we doesn't care if lvm is for HPUX or Solaris, we just care if they have same property
	$lvm->get('propertyname');
	$lvm->set('version', 2);

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

sub set($$) {
	
	my $self= shift;
	my $property = shift;
	my $value = shift;
	
	if(exists($self->{$property})) {
		$self->{$property} = $value;
	} else {
		die "You cannot set non-existent property: $property!\n";
	} # if

	return $self;
	
} # end sub set

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
