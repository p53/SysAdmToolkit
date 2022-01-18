package SysAdmToolkit::Patterns::Factory;

=head1 NAME

SysAdmToolkit::Patterns::Factory - module provides base for creating factories and derive them from this class

=head1 SYNOPSIS

	# lvmFactory is derived from this class
	my $lvmFactory = Storage::Lvm->new();
	# this will produce class Storage::Lvm::HPUX_1131
	my $hpuxLvm = $lvmFactory->produce('type' => 'HPUX_1131');

=cut

use base 'SysAdmToolkit::Patterns::Prototype';

=head1 METHODS

=over 12

=item C<produce>

Method produce generates appropriate class according type we pass to it,
class will be name of current factory plus type passed to method

param:

	type string

return:

	object

=back

=cut

sub produce($) {

	my $self = shift;
	my %params = @_;
	my $type = $params{'type'};
	my $class = ref $self;
	
	$type = ucfirst($type);
	
	my $produceClass = $class . '::' . $type;
	
	my $module = $produceClass ;
	$produceClass  =~ s/\:\:/\//g;
	
	require "$produceClass.pm";
	$module->import();
	
	my $object = $module->new(@_);
	
	return $object;
	
} # end sub produce

sub getClass() {
	
	my $self = shift;
	my %params = @_;
	my $type = $params{'type'};
	my $class = ref $self || $self;
	
	$type = ucfirst($type);
	
	my $produceClass = $class . '::' . $type;
	
	my $module = $produceClass ;
	$produceClass  =~ s/\:\:/\//g;
	
	require "$produceClass.pm";
	$module->import();
	
	return $module;
	
} # end sub getClass

=head1 DEPENDENCIES

	SysAdmToolkit::Patterns::Prototype

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
