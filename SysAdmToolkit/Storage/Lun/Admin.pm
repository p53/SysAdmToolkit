package SysAdmToolkit::Storage::Lun::Admin;

use base 'SysAdmToolkit::Patterns::OsFactoryProxy';

use SysAdmToolkit::Storage::Lun;
use SysAdmToolkit::Storage::Disk;

=head1 NAME

SysAdmToolkit::Storage::Lun::Admin - interface module for getting info about Luns

=head1 SYNOPSIS

	my $lunAdmin = SysAdmToolkit::Storage::Lun::Admin->new('os' => 'HPUX', 'ver' => '1131');
										
	my @luns = $lvmAdmin->getLuns('type' => 'emc');

=head1 DESCRIPTION

Module should help in getting info about luns

=cut

sub getLunObjs() {
	
	my $self = shift;
	my %params = @_;
	
	if(!exists($params{'luns'})) {
		die("You need to supply luns array!\n");
	} # if
	
	my $lunsArray = $params{'luns'};
	my @lunOjbs = ();
	
	for my $lun(@$lunsArray) {
		my $lunClass = SysAdmToolkit::Storage::Lun->getClass('os' => $self->get('os'), 'ver' => $self->get('ver'));
		my $lunObj = $lunClass->getObj(%$lun);
		push(@lunObjs, $lunObj);
	} # for
	
	return \@lunObjs;
	
} # end sub getLunObjs

sub getLunsDisks(){
	
	my $self = shift;
	my %params = @_;
	
	if(!exists($params{'luns'})) {
		die("You need to supply luns array!\n");
	} # if
	
	my $lunsArray = $params{'luns'};
	my @diskOjbs = ();
	
	for my $lun(@$lunsArray) {
		my $diskClass = SysAdmToolkit::Storage::Disk->getClass('os' => $self->get('os'), 'ver' => $self->get('ver'));
		my $charDev = $diskClass->getCharDev();
		my $diskObj = SysAdmToolkit::Storage::Disk->new('devFile' => $charDev . $lun->{'dev'}, 'os' => $self->get('os'), 'ver' => $self->get('ver'));
		push(@diskObjs, $diskObj);
	} # for
	
	return \@diskObjs;
	
} # end sub getLunsDisks

=head1 DEPENDECIES

	SysAdmToolkit::Patterns::OsFactoryProxy

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
