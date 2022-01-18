package SysAdmToolkit::Log::Storage::File;

=head1 NAME

SysAdmToolkit::Log::Storage::File - module for handling file logs

=head1 SYNOPSIS

	my $fileStorage= SysAdmToolkit::Log::Storage::File->new();
										
	$fileStorage->setFile('/home/user/app.log');
	$fileStorage->write(\@lines);

=head1 DESCRIPTION

Module is used for writing to file

=cut

use base 'SysAdmToolkit::Patterns::Prototype';
use IO::File;

=head1 METHODS

=over 12

=item C<new>

Method new initializing object and properties

=cut

sub new() {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	$self->{'file'} = '';
	return $self;
} # end sub new

=item C<setFile>

Method setFile sets path to file where entries will be written

params:

	$file string

return:

	$self SysAdmToolkit::Log::Storage::File

=cut

sub setFile($) {
	my $self = shift;
	my $file = shift;
	$self->{'file'} = $file;
	return $self;
} # end sub setFile

=item C<write>

Method write, writes entries passed to it to file specified in setFile method

params:

	$buffer array ref

=back

=cut

sub write($) {
	
	my $self = shift;
	my $buffer = shift;
	my $file = $self->{'file'};
	my $output = '';
	
	foreach my $line(@$buffer) {
		@messageValues = values(%$line);
		my $logMessage = join("\t", @messageValues);
		$output .= $logMessage . "\n";
	} # foreach
	
	$fh = new IO::File->new(">> $file");
	
	if(!$fh) {
		die("Cannot open file $file for write!");
	} # if

	print $fh $output;
	$fh->close;
	
} # end sub write

=head1 DEPENDENCIES

	SysAdmToolkit::Patterns::Prototype
	IO::File

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
