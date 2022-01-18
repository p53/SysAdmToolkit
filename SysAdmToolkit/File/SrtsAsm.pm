package SysAdmToolkit::File::SrtsAsm;

=head1 NAME

SysAdmToolkit::File::SrtsAsm - module for extracting frame, lunid data from asm srts remarks

=head1 SYNOPSIS

	my $srts = SysAdmToolkit::File::SrtsAsm->new();
	
	# result will be array of hashes
	# {'lunid' => '3AD', 'frame' => '1589', 'product' => 'SYMMETRIX'}
	my $srtsInfo = $srts->extractType('type' => 'emc', 'str' => $srtsData);
	

=head1 DESCRIPTION

Module should help extracting frame, lunid data from asm srts remarks text

=cut

use base qw/
				SysAdmToolkit::File::Srts
			/;

=head1 DEPENDECIES

	SysAdmToolkit::File::Srts
	
=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;