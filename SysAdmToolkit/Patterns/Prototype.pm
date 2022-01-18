package SysAdmToolkit::Patterns::Prototype;

=head1 NAME

SysAdmToolkit::Patterns::Prototype - module provides base for creating Prototype classes

=head1 SYNOPSIS

	use base 'SysAdmToolkit::Patterns::Prototype';

=cut

=head1 METHODS

=over 12

=item C<new>

Method new creates object

return:

	object

=cut

sub new() {
	my $class = shift;
	my $self = {@_};
	bless($self, $class);
	$self->_init(@_);
	return $self;
}

=item C<_init>

Method _init servers for custom initialization of object

=back

=cut

sub _init() {} # end sub _init

sub getObj() {
	my $class = shift;
	my $self = {@_};
	bless($self, $class);
	return $self;
}

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
