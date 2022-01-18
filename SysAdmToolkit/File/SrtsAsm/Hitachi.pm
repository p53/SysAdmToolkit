package SysAdmToolkit::File::SrtsAsm::Hitachi;

=head1 NAME

	SysAdmToolkit::File::SrtsAsm::Hitachi - module for extracting data for hitachi from srts
	
=head1 SYNOPSIS

	my $hitachiEx = SysAdmToolkit::File::SrtsAsm::Hitachi->new();
	$hitachiEx->extract($srtsText);
	
=cut

use base qw/
				SysAdmToolkit::File::Srts::Hitachi
			/;

=head1 DEPENDECIES

	SysAdmToolkit::File::Srts::Hitachi

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;