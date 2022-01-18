package SysAdmToolkit::Debug::Base;

=head1 NAME

SysAdmToolkit::Debug::Base - module provides basic tools to debug code

=head1 SYNOPSIS

	my $variable = 'var';
	my $debugger = SysAdmToolkit::Debug::Base->new();
	$debugger->addDebug('variable', 'var');

=cut

use base 'SysAdmToolkit::Patterns::Singleton';

use Data::Dumper;
use SysAdmToolkit::Exception::Debug;
use Scalar::Util 'blessed';
use Scalar::Util 'dualvar';
use Term::ReadKey;

=head1 METHODS

=over 12

=item C<addDebug>

Method addDebug adds variable to debugged variables

param:

	$varName string

	$varValue mixed

return:

	$instance SysAdmToolkit::Debug::Base

=cut

sub addDebug($$) {
	my $self = shift;
	my $varName = shift;
	my $varValue = shift;
	$instance->{'buffer'}->{$varName} = $varValue;
	return $instance;
} # end sub addDebug

=item C<setLogger>

Method setLogger sets logger object

param:

	$logger object

return:

	$instance object

=cut

sub setLogger($) {
	my $self = shift;
	my $logger = shift;
	my $instance->{'logger'} = $logger;
	return $instance; 
} # end sub setLogging

=item C<getBuffer>

Method getBuffer gets buffer with all debugged variables

return:

	hash ref

=cut

sub getBuffer() {
	my $self = shift;
	return $instance->{'buffer'};
} # end sub getBuffer

=item C<debug>

Method debug, prints and logs variable value

=cut

sub debug() {
	
	my $debugException = SysAdmToolkit::Exception::Debug->new('msg' => 'Debugging...');
	my $buffer = $instance->{'buffer'};

	$debugOutput .= "\n" . $instance->center("#"," Debug Output ");
	
	# foreach variable in the buffer we will find its type and according that
	# we will decide how to print and log it
	foreach my $itemKey(keys %$buffer) {
		
		$debugOutput .= $instance->center("-", " Debug Item: $itemKey ");
		
		my $debugItem = $buffer->{$itemKey};
		my $varType = ref($debugItem);
		my $refType = '';

		if($varType ne 'SCALAR' && $varType eq 'REF') {
			$refType = reftype $debugItem;
		} # if
		
		if(defined blessed($debugItem) || $varType eq 'ARRAY' || $varType eq 'HASH') {
			$debugOutput .= Dumper($debugItem);
			$debugOutput .= "\n";
		} else {
			$debugOutput .= "$itemKey: " . $debugItem . "\n";
		} # if
		
		$debugOutput .= $instance->center("-", " End Debug Item: $itemKey ");
		
	} # foreach
	
	$debugOutput .= "\n" . $instance->center("#", " End Debug ");
	
	if(my $logger = $instance->{'logger'}) {
			$logger->log($debugOutput, 5, 'AppSystem');
	} # if
	
	print $debugOutput;
	
	$catcher->throw($debugException);
	
} # end sub write

=item C<center>

Method center centers caption

param:

	$sepChar string

	$caption string

return:

	$separator string

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

	SysAdmToolkit::Patterns::Singleton
	Data::Dumper
	SysAdmToolkit::Exception::Debug
	Scalar::Util
	Scalar::Util
	Term::ReadKey

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
