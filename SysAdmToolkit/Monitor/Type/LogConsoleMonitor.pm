package SysAdmToolkit::Monitor::Type::LogConsoleMonitor;

=head1 NAME

SysAdmToolkit::Monitor::Type::LogConsoleMonitor - this module should provide means for centralizing 
logging and printing messages to terminal for other modules

=head1 SYNOPSIS

	my $logStorage = SysAdmToolkit::Log::Storage::File->new()->setFile($logFile);
	my $logger = SysAdmToolkit::Log::Logger->new()->setStorage($logStorage)->setBufferSize(0)->setSeverities($severities);
	my $mailer = SysAdmToolkit::Mail::Mailer->new()->setTo($mailRecipients)->setSubject($errorMailSubject);
	my $monitor = SysAdmToolkit::Monitor::Type::LogConsoleMonitor->new();
	$monitor->setLogger($logger);
	$monitor->setMailer($mailer);

	$monitor->run({'message' => 'Starting backing up info...', 'severity' => 5, 'subsystem' => __PACKAGE__, 'status' => 1, 'statusOff' => 1});

=head1 DESCRIPTION

Module should be passed to setMonitor method of monitor subject, provides means for centralizing logging
and printing messages on terminal

=cut

use base 'SysAdmToolkit::Monitor::Type::Base';

use SysAdmToolkit::Log::Logger;
use SysAdmToolkit::Mail::Mailer;
use SysAdmToolkit::Monitor::Status;
use SysAdmToolkit::Term::Text;
use Term::ReadKey;
use IO::File;
use POSIX qw/strftime/; 

=head1 PRIVATE VARIABLES

=over 12

=item logger object

	Property should store logger object

=cut

my $logger = '';

=item file IO::File

	Property stores IO::File object

=cut

my $file = '';

=item console string

	Property stores device file location for console

=cut

my $console = '/dev/console';

=item status string

	Property stores default status

=cut

my $status = 1;

=item mailer object

	Property should store mailer object

=back

=cut

my $mailer = '';

=head1 METHODS

=over 12

=item C<_init>

Method _init initializies basic status object, mailing severities

=cut

sub _init() {
	my $self = shift;
	$file = IO::File->new();
	$self->{'termText'} = SysAdmToolkit::Term::Text->new();
	$self->{'statuser'} = SysAdmToolkit::Monitor::Status->new();
	$self->{'mailingSeverities'} = [1, 2, 3, 4, 5];
	return $self;
} # end sub _init

=item C<setLogger>

Method setLogger sets logger object for monitor

params:

	$loggerPassed object

return:

	SysAdmToolkit::Monitor::Type::LogConsoleMonitor

=cut

sub setLogger($) {
	my $self = shift;
	my $loggerPassed = shift;
	$logger = $loggerPassed;
	return $self;
} # end sub setLogger

=item C<setMailer>

Method setMailer sets mailing object for monitor, mailer must have setMessage and send mehotds to work

params:

	$mailerPassed object

return:

	SysAdmToolkit::Monitor::Type::LogConsoleMonitor

=cut

sub setMailer($) {
	my $self = shift;
	my $mailerPassed = shift;
	$mailer = $mailerPassed;
	return $self;	
} # end sub setMailer

=item C<setMailingSeverities>

Method setMailingSeverities sets severities for which mail should be sent

params:

	array ref

return:

	SysAdmToolkit::Monitor::Type::LogConsoleMonitor

=cut

sub setMailingSeverities($) {
	my $self = shift;
	$self->{'mailingSeverities'} = shift;
	return $self;
} # end usb setMailSeveritiesToSend

=item C<run>

Method run, runs logging printing messages by severity, status
message, severity, subsystem must be always set, status should be always set,
statusOff is optional and it won't print status part of the message when true

params:

	$params hash ref

return:

	SysAdmToolkit::Monitor::Type::LogConsoleMonitor

=back

=cut

sub run($) {
	
	my $self = shift;
	my $params = shift;
	my $message = $params->{'message'};
	my $severity = $params->{'severity'};
	my $subsystem = $params->{'subsystem'};
	my $status = $params->{'status'};
	my $statusOff = $params->{'statusOff'};
	my $mailSever = $self->{'mailingSeverities'};
	my $outMsg = '';
	my $outLogMsg = '';
	my $time = strftime('%m-%d-%Y-%H:%M',localtime);
	my $outputMsg = "$time  $severity  $subsystem  $message";
	
	if(!($params->{'message'} && $params->{'severity'} && $params->{'subsystem'})) {
		warn('Msg, severity or subsystem not set!');
	} # if
	
	my $coloredStatusText = $self->{'statuser'}->getColoredStatus($status);
	my $statusText = $self->{'statuser'}->getStatus($status);
	
	# if we passed statusOff parameter true we won't print status message to logs and terminal
	if(!$statusOff) {
		$outMsg = "$outputMsg $coloredStatusText\n";
		$outLogMsg = "$outputMsg $statusText";
	} else {
		$outMsg = "$outputMsg\n";
		$outLogMsg = "$outputMsg";
	} # if
	
	# printing to console
	if ($file->open("> $console")) {
		print $file "$outMsg";
		$file->close;
	} # if
	
	# logging message
	if($logger) {
		$logger->log('message' => $outLogMsg, 'severity' => $severity, 'subsystem' => $subsystem);
	} # if
	
	my $sendMail = grep($_ == $severity, @$mailSever);
	
	# mail will be sent always when there is failure
	if($mailer && $sendMail && $status == 0) {
		$mailer->setMessage($outLogMsg . ', severity ' . $severity . ', subsystem ' . $subsystem)->send();
	} # if
	
	print "$outMsg";
	
	return $self;
	
} # end sub run

=head1 DEPENDENCIES

	SysAdmToolkit::Patterns::Prototype

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
