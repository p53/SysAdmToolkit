package SysAdmToolkit::Patterns::Proxy;

=head1 NAME

SysAdmToolkit::Patterns::Proxy - module provides base for creating proxies

=head1 DESCRIPTION

Proxy is class which queries for methods and properties indirectly through other class, i implemented it
through class stored in proxy public property

=head1 SYNOPSIS

	# here lvm is derived from OsFactoryProxy
	my $lvm = Storage::Lvm->new('os' => 'HPUX', 'ver' => '1131');
	# we doesn't care if lvm is for HPUX or Solaris, we just care if they have same property
	$lvm->get('propertyname');
	$lvm->doThis();

=head1 METHODS

=over 12

=item C<AUTOLOAD>

Implementing AUTOLOAD method to be able to call also methods through proxy

=cut

sub AUTOLOAD {
	
	my $self = shift;
	my $method = $AUTOLOAD;
    $method  =~ s/.*:://;
	my $result;
	
	if($method eq 'DESTROY') {
		return;
	} # if
	
	if($self->{'proxy'}->can($method)) {
		$result = $self->{'proxy'}->$method(@_);
	} else {
		die "No such method $method!\n";
	} # if
	
	return $result;
	
} # end sub AUTOLOAD

=item C<get>

Method get gets properties through proxy

param:

	$property string

return:

	mixed

=back

=cut

sub get($) {
	
	my $self= shift;
	my $property = shift;

	if(exists($self->{'proxy'}->{$property})) {
		return $self->{'proxy'}->{$property};
	} else {
		die "Query for non-existent property: $property!\n";
	} # if

} # end sub get

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
