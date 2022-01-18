package SysAdmToolkit::VxVm::Register;

use base qw/
				SysAdmToolkit::Patterns::Singleton
			/;

use SysAdmToolkit::VxVm::Admin;

=head1 NAME

SysAdmToolkit::Lvm::Register - module for tracking VxVm elements

=head1 SYNOPSIS

	SysAdmToolkit::VxVm::Register->new();

=cut

=head1 STATIC PROPERTIES
	
=over 12

=item instance SysAdmToolkit::VxVm::Register

	Class variable holding singleton instance

=cut

our $instance;

=item C<_init>

METHOD _init, initializies register

params:

	os string
	
	ver string
	
=back

=cut

sub _init() {

	my $self = shift;
	my %params = @_;
	
	my $lvmAdm = SysAdmToolkit::VxVm::Admin->new(%params);
	
	my $lvsAdm = $lvmAdm->getLvs();
	my $pvs = $lvmAdm->getPvs();
	my $vgsAdm = $lvmAdm->getVgs();
	
	%vgs = map{$_ => 1} @$vgsAdm;
	%lvs = map{$_ => 1} @$lvsAdm;
	
	$self->{'vgs'} = \%vgs;
	$self->{'lvs'} = \%lvs;
	$self->{'pvs'} = $pvs;
	
} # end sub _init

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;