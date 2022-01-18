package SysAdmToolkit::Monitor::Type::Base;

=head1 NAME

SysAdmToolkit::Monitor::Type::Base - basic interface for all monitor types

=head1 DESCRIPTION

Basic interface for all monitor types

=cut

use base 'SysAdmToolkit::Patterns::Prototype';

=head1 METHODS

=over 12

=item C<run>

Method run is basic interface method, should contain all functions module should provide

=back

=cut

sub run($) {} # end sub run

=head1 DEPENDENCIES

	SysAdmToolkit::Patterns::Prototype

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
