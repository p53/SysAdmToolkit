package SysAdmToolkit::Storage::Disk::Admin;

use base 'SysAdmToolkit::Patterns::OsFactoryProxy';

use SysAdmToolkit::Storage::Lun;
use SysAdmToolkit::Storage::Disk;

=head1 NAME

SysAdmToolkit::Storage::Admin - interface module for getting info about Disks on the machine

=head1 SYNOPSIS

	my $diskAdmin = SysAdmToolkit::Storage::Disk::Admin->new('os' => 'HPUX', 'ver' => '1131');
										
	my $disks = $diskAdmin->getDisks();

=head1 DESCRIPTION

Module should help in getting info about disks

=cut

=head1 METHODS

=over 12

=item C<getDiskObjs>

METHOD getDiskObjs transforms array of hash properties for each disk into disk objects

params:

	disks array ref - array of hash references of disk properties
	
return:

	array ref - of disk objects
	
=cut

sub getDiskObjs() {
	
	my $self = shift;
	my %params = @_;
	
	if(!exists($params{'disks'})) {
		die("You need to supply luns array!\n");
	} # if
	
	my $disksArray = $params{'disks'};
	my @diskOjbs = ();
	
	for my $disk(@$disksArray) {
		my $diskClass = SysAdmToolkit::Storage::Disk->getClass('os' => $self->get('os'), 'ver' => $self->get('ver'));
		my $diskObj = $diskClass->getObj(%$disk);
		push(@diskObjs, $diskObj);
	} # for
	
	return \@diskObjs;
	
} # end sub getDiskObjs

=item C<getDisksLuns>

METHOD getDisksLuns gets lun info related to supplied array of disks properties

params:

	disks array ref - array of hash ref of disks properties
	
return:

	array ref - array of lun objects tied to disks
	
=back

=cut

sub getDisksLuns(){
	
	my $self = shift;
	my %params = @_;
	
	if(!exists($params{'disks'})) {
		die("You need to supply disks array!\n");
	} # if
	
	my $disksArray = $params{'disks'};
	my @lunOjbs = ();
	
	for my $disk(@$disksArray) {
		my $lunObj = SysAdmToolkit::Storage::Lun->new('devFile' => $disk->{'blkdevfile'}, 'os' => $self->get('os'), 'ver' => $self->get('ver'));
		push(@lunObjs, $lunObj);
	} # for
	
	return \@lunObjs;
	
} # end sub getDisksLuns

=head1 DEPENDECIES

	SysAdmToolkit::Patterns::OsFactoryProxy
	SysAdmToolkit::Storage::Lun
	SysAdmToolkit::Storage::Disk

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
