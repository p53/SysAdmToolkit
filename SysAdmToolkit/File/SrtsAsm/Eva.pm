package SysAdmToolkit::File::SrtsAsm::Eva;

=head1 NAME

	SysAdmToolkit::File::SrtsAsm::Eva - module for extracting data for eva from srts
	
=head1 SYNOPSIS

	my $evaEx = SysAdmToolkit::File::SrtsAsm::Eva->new();
	$evaEx->extract($srtsText);
	
=cut

use base qw/
				SysAdmToolkit::File::Srts::Eva
			/;

=head1 DEPENDECIES

	SysAdmToolkit::File::Srts::Eva

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;