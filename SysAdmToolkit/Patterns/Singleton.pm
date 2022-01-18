package SysAdmToolkit::Patterns::Singleton;

=head1 NAME

SysAdmToolkit::Patterns::Singleton - module provides base for creating singletons

=head1 SYNOPSIS

	use base 'SysAdmToolkit::Patterns::Singleton';

=head1 METHODS

=over 12

=item C<new>

Method new creates or returns singleton object

return:

	$variable mixed

=back

=cut

sub new() {

	my $class = shift;
	my $variable = $class . '::instance';

	no strict 'refs';
	
	if(!defined $$variable) {
		$$variable = bless({@_}, $class);
		$$variable->_init(@_);
	} # if
	
	return $$variable;
	
}

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
