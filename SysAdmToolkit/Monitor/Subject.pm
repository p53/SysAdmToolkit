package SysAdmToolkit::Monitor::Subject;

=head1 NAME

SysAdmToolkit::Monitor::Subject - this module should provide means for centralizing logging, error handling of other modules

=head1 SYNOPSIS

	my $logStorage = SysAdmToolkit::Log::Storage::File->new()->setFile($logFile);
	my $logger = SysAdmToolkit::Log::Logger->new()->setStorage($logStorage)->setBufferSize(0)->setSeverities($severities);
	my $mailer = SysAdmToolkit::Mail::Mailer->new()->setTo($mailRecipients)->setSubject($errorMailSubject);
	my $monitor = SysAdmToolkit::Monitor::Type::LogConsoleMonitor->new();
	$monitor->setLogger($logger);
	$monitor->setMailer($mailer);

	my $processManager = SysAdmToolkit::Process::Manager->new('processes' => $checkProcesses)->setMonitor($monitor);


=head1 DESCRIPTION

Module is basic module it should be extended by other classes,
it provides means for centralizing logging, error, message handling of modules

=cut

use base 'SysAdmToolkit::Patterns::Prototype';

use SysAdmToolkit::Monitor::Status;
use Scalar::Util 'blessed';

=head1 METHODS

=over 12

=item C<_init>

Method _init initializies module, monitor status

=cut

sub _init() {
	my $self = shift;
	$self->{'monitorStat'} = SysAdmToolkit::Monitor::Status->new();
	$self->{'monitor'} = '';
} # end sub _init

=item C<setMonitor>

Method setMonitor sets Monitor to monitor subject, there can be different monitor modules

params:

	$monitorPassed SysAdmToolkit::Monitor::Type::Base
	
return:

	SysAdmToolkit::Monitor::Subject

=cut

sub setMonitor($) {
	my $self = shift;
	my $monitorPassed = shift;
	$self->{'monitor'} = $monitorPassed;
	return $self;
} # end sub setMonitor

=item C<unsetMonitor>

Method unsetMonitor unsets Monitor from monitor subject, this can be usefull, if we want to turn it off

return:

	SysAdmToolkit::Monitor::Subject

=cut

sub unsetMonitor() {
	my $self = shift;
	$self->{'monitor'} = '';
	return $self;
} # end sub unsetMonitor

=item C<getMonitor>

Method getMonitor returns monitor of monitor subject

return:

	SysAdmToolkit::Monitor::Type::Base

=cut

sub getMonitor() {
	my $self = shift;
	return $self->{'monitor'};
} # end sub getMonitor

=item C<getStatus>

Method getStatus returns code for status passed from monitor status module

params:

	$stat mixed
	
return:

	mixed

=cut

sub getStatus($) {
	my $self = shift;
	my $stat = shift;
	if(blessed($self->{'monitor'})) {
		if($self->{'monitor'}->isa('SysAdmToolkit::Monitor::Type::Base')) {
			return $self->{'monitorStat'}->getStatus($stat);
		} # if
	} # if
} # end sub getStatus

=item C<runMonitor>

Method runMonitor executes run method of monitor with parameters passed

=back

=cut

sub runMonitor() {
	my $self = shift;
	my %params = @_;
	if(blessed($self->{'monitor'})) {
		if($self->{'monitor'}->isa('SysAdmToolkit::Monitor::Type::Base')) {
			$self->{'monitor'}->run(\%params);
		} # if
	} # if
} # end sub runMonitor

=head1 DEPENDENCIES

	SysAdmToolkit::Patterns::Prototype
	SysAdmToolkit::Monitor::Status
	Scalar::Util

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
