package SysAdmToolkit::Exception::Base;

=head1 NAME

SysAdmToolkit::Exception::Base - module provides base for creating exceptions

=head1 SYNOPSIS

	my $baseException = SysAdmToolkit::Exception::Base->new('msg' => 'Debugging...');

=cut

use base 'SysAdmToolkit::Patterns::Prototype';
use Term::ReadKey;

=head1 METHODS

=over 12

=item C<suicide>

Method suicide is called after exception is thrown, prints current stack

param:

	$stack hash ref

=cut

sub suicide($) {
	
	my $self = shift;
	my $stack = shift;
	my $exceptionOutput = '';
	
	my $i = 0;
	my $exceptionInfoIndex = undef;
	
	$exceptionOutput .= "\n" . $self->center("#"," Stack ");
	
	foreach my $error(@$stack) {
		
		$exceptionOutput .= $self->center("-"," Stack Level $i ");
		
		foreach my $elements(keys %$error) {
			
			if($error->{$elements}) {
				if($error->{$elements} eq 'Exception::Catcher::throw') {
					$exceptionInfoIndex = $i;
				} # if
				$exceptionOutput .= uc($elements) . ": " . $error->{$elements} ."\n";
			} # if
			
		} # foreach
		
		$exceptionOutput .= $self->center("-"," End Level $i ");
		
		$i++;
		
	} # foreach
	
	$exceptionOutput .= "\n" . $self->center("#"," End Stack ");
	
	print "\n" . $self->center("#"," Exception ");
	print "Thrown exception: " . ref($self) . "\n";
	print "Message: " . $self->{'msg'} . "\n";
	print "Package: " . $stack->[$exceptionInfoIndex]->{'package'} . "\n";
	print "Filename: " . $stack->[$exceptionInfoIndex]->{'filename'} . "\n";
	print "Line: " . $stack->[$exceptionInfoIndex]->{'line'} . "\n";
	print "\n" . $self->center("#"," End Exception ");
	
	print $exceptionOutput;
	
} # end sub suicide

=item C<center>

Method center, centers output on terminal

param:

	$sepChar string

	$caption string

=back

=cut

sub center($$) {
	
	my $self = shift;
	my $sepChar = shift;
	my $caption = shift;
	my $separator = '';

	($wchar, $hchar, $wpixels, $hpixels) = GetTerminalSize();
	my $width = $wchar;
	
	my $modulus = ($width - length($caption)) % 2;
	
	if($modulus > 0) {
		$width = $width - 1;
	} # if
	
	my $sideWidth = ($width - length($caption))/2;
	
	$separator = $sepChar x $sideWidth . $caption . $sepChar x $sideWidth . "\n";
	
	return $separator;
	
} # end sub center

=head1 DEPENDENCIES

	SysAdmToolkit::Patterns::Prototype
	Term::ReadKey

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
