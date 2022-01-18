package SysAdmToolkit::Log::Logger;

=head1 NAME

SysAdmToolkit::Log::Logger - module for logging messages to different types of storage

=head1 SYNOPSIS

	my $logger = SysAdmToolkit::Log::Logger->new();
	my $storage = SysAdmToolkit::Log::Storage::File->new()->setFile('/var/log/applog.log');
	$logger->setStorage($storage);
	$logger->log('message' => 'Bye Bye', 'severity' => 1, 'subsystem' => 'Application');

=head1 DESCRIPTION

Module is aimed at logging messages to different type of storage, depending
on storage object passed. Module can be set to buffer messages (delaying write),
filter subsystems to log and also filter severities

=cut

use base 'SysAdmToolkit::Patterns::Prototype';
use POSIX qw/strftime/; 

=head1 METHODS

=over 12

=item C<_init>

Method _init sets default values for bufferSize, filtered subsystems and severities

default:

	bufferSize 10

	subsystem []

	severity [1,2,3,4,5]

=cut

sub _init() {
	
	my $self = shift;

	$self->{'bufferSize'} = 10;
	$self->{'subsystem'} = [];
	$self->{'severity'} = [1,2,3,4,5];
	$self->{'buffer'} = [];
	
} # end sub new

=item C<setSeverities>

Method setSeverities sets severities to log

params:

	$severities array ref

return:

	$self SysAdmToolkit::Log::Logger

=cut

sub setSeverities($) {
	my $self = shift;
	my $severities = shift;
	$self->{'severity'} = $severities;
	return $self;
} # end sub setSeverities

=item C<setSubsystems>

Method setSubsystems sets subsystems which are allowed 
to log if empty all subsystems are logged

params:

	$subsystems array ref

return:

	$self SysAdmToolkit::Log::Logger

=cut

sub setSubsystems($) {
	my $self = shift;
	my $subsystems = shift;
	$self->{'subsystem'} = $subsystems;
	return $self;
} # end sub setSubsystems

=item C<setBufferSize>

Method setBufferSize set buffer size, number of messages that are
buffered before write

params:

	$bufferSize int

return:

	$self SysAdmToolkit::Log::Logger

=cut

sub setBufferSize() {
	my $self = shift;
	my $bufferSize = shift;
	$self->{'bufferSize'} = $bufferSize;
	return $self;	
} # if

=item C<setStorage>

Method setStorage sets the type of storage which logger will use to log messages

params:

	$self->{'storage'} SysAdmToolkit::Log::Storage::*

return:

	$self SysAdmToolkit::Log::Logger

=cut

sub setStorage($) {
	my $self = shift;
	$self->{'storage'} = shift;
	return $self;
} # end sub setStorage

=item C<log>

Method log logs messages accepted as parameters and buffers them if buffer set

params:

	message string

	severity int

	subsystem string

return:

	$self SysAdmToolkit::Log::Logger

=cut

sub log($$$) {
	
	my $self = shift;
	my %params = @_;
	my $message = $params{'message'};
	my $severity = $params{'severity'};
	my $subsystem = $params{'subsystem'};
	my $availSeverity = $self->{'severity'};
	my $availSubsystem = $self->{'subsystem'};
	my $time = strftime('%m-%d-%Y-%H:%M',localtime);
	
	my %logMessage = ('tstamp' => $time, 'severity' => $severity, 'subsystem' => $subsystem, 'message' => $message);
	
	my $severityPresence = grep($_ == $logMessage{'severity'}, @$availSeverity);
	my $subSystemPresence = grep($_ eq $logMessage{'subsystem'}, @$availSubsystem);
	
	# we log messages if severity is in accepted severities and if subsystem 
	# is in accepted subsystems or acceppted subsystems are empty
	if($severityPresence && ($subSystemPresence || !@$availSubsystem)) {
		
		push(@{$self->{'buffer'}}, \%logMessage);
		my $size = @{$self->{'buffer'}};

		if($size > $self->{'bufferSize'}) {
			$self->write();
			$self->{'buffer'} = [];
		} # if
		
	} # if
	
	return $self;
	
} # end sub log

=item C<write>

Method write, writes messages to storage

return:

	$self SysAdmToolkit::Log::Logger

=back

=cut

sub write() {
	
	my $self = shift;
	my $storage = $self->{'storage'};
	my $buffer = $self->{'buffer'};
	
	if(!$storage) {
		die ('msg' => 'You didn\'t set storage of Logger!');
	} # if
	
	$storage->write($buffer);
	
	return $self;
	
} # end sub write

=head1 DEPENDENCIES

	SysAdmToolkit::Patterns::Prototype
	POSIX qw/strftime/

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
