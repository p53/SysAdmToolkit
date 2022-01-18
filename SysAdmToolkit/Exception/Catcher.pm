package SysAdmToolkit::Exception::Catcher;

=head1 NAME

SysAdmToolkit::Exception::Catcher - module for catching exceptions

=head1 SYNOPSIS

	my $catcher = SysAdmToolkit::Exception::Catcher->new();
	$catcher->try(&main());
	
	# in main function code
	my $exception = SysAdmToolkit::Exception::Base->new();
	$catcher->throw($exception);

=cut

use base 'SysAdmToolkit::Patterns::Singleton';

=head1 METHODS

=over 12

=item C<try>

Method try is similar to try block in other languages

param:

	$code sub ref

=cut

sub try($) {
	
	my $self = shift;
	my $code = shift;
	
	eval {
		$code->();
	} # eval
	
} # end sub try

=item C<catch>

Method catch is similar to catch block in other languages

param:

	$code sub ref

=cut

sub catch($) {
	
	my $self = shift;
	my $code = shift;

	$code->($@);
	
} # end sub catch

=item C<throw>

Method throw is method for throwing exceptions

param:

	$exception SysAdmToolkit::Exception::Base

=back

=cut

sub throw($) {
	
	my $self = shift;
	my $exception = shift;
	
	die $exception;
	
} # end sub throw

=head1 DEPENDENCIES

	SysAdmToolkit::Patterns::Singleton

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
