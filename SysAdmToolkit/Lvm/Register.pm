package SysAdmToolkit::Lvm::Register;

use base qw/
				SysAdmToolkit::Patterns::Singleton
			/;

use SysAdmToolkit::Lvm::Admin;

=head1 NAME

SysAdmToolkit::Lvm::Register - module for tracking LVM elements

=head1 SYNOPSIS

	SysAdmToolkit::Lvm::Register->vgs{'vg00'}
	SysAdmToolkit::Lvm::Register->pvs{'/dev/dsk/disk12'}
	SysAdmToolkit::Lvm::Register->lvs{'/dev/vg00/root'}

=cut

=head1 CLASS VARIABLES
	
=over 12

=item instance SysAdmToolkit::Lvm::Register

	Class variable holding singleton instance
	
=back

=cut

our $instance;

sub _init() {

	my $self = shift;
	my %params = @_;
	
	my $lvmAdm = SysAdmToolkit::Lvm::Admin->new(%params);
	
	my $lvsAdm = $lvmAdm->getLvs();
	my $pvsAdm = $lvmAdm->getPvs();
	my $vgsAdm = $lvmAdm->getVgs();
	
	%vgs = map{$_ => 1} @$vgsAdm;
	%lvs = map{$_ => 1} @$lvsAdm;
	%pvs = map{$_ => 1} @$pvsAdm;
	
	$self->{'vgs'} = \%vgs;
	$self->{'lvs'} = \%lvs;
	$self->{'pvs'} = \%pvs;
	
} # end sub _init

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;