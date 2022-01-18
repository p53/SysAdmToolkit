package SysAdmToolkit::Monitor::Status;

=head1 NAME

SysAdmToolkit::Monitor::Status - this module should provide means for centralizing status handling for monitor subjects

=head1 SYNOPSIS

	my $logStorage = SysAdmToolkit::Log::Storage::File->new()->setFile($logFile);
	my $logger = SysAdmToolkit::Log::Logger->new()->setStorage($logStorage)->setBufferSize(0)->setSeverities($severities);
	my $mailer = SysAdmToolkit::Mail::Mailer->new()->setTo($mailRecipients)->setSubject($errorMailSubject);
	my $monitor = SysAdmToolkit::Monitor::Type::LogConsoleMonitor->new();
	$monitor->setLogger($logger);
	$monitor->setMailer($mailer);

	my $processManager = SysAdmToolkit::Process::Manager->new('processes' => $checkProcesses)->setMonitor($monitor);


=head1 DESCRIPTION

Module is basic module and it is used for transforming statuses to meaningful form and in centralized manner

=cut

use base 'SysAdmToolkit::Patterns::Prototype';

=head1 PRIVATE VARIABLES

=over 12

=item codes hash ref

	Property stores pairs of statuses vs. their meaningful form

=cut

my $codes = {
				'1' => '[OK]',
				'0' => '[FAIL]'
			};

=item colors hash ref

	Property stores color pairs of statuses and their color on terminal

=cut

my $colors = {
				'1' => '32;40',
				'0' => '31;40'
			};
		
=item returnStatus string

	This is returned when non-valid status is passed

=back

=cut
	
my $returnStatus = '[IGNORE]';

=head1 METHODS

=over 12

=item C<addStatus>

Method addStatus can add pair of status, message

params:

	code mixed

	return mixed
	
return:

	SysAdmToolkit::Monitor::Status

=cut

sub addStatus($$) {
	
	my $self = shift;
	my %params = @_;
	
	if(!$params{'return'}) {
		die "You must set return code!\n";
	} # if
	
	$codes->{$params{'code'}} = $params{'return'};
	
	return $self;
	
} # and sub addStatus

=item C<getStatus>

Method getStatus get respective message for passed status

params:

	$status mixed
	
return:

	$returnStatus mixed

=cut

sub getStatus($) {
	
	my $self = shift;
	my $status = shift;

	if($codes->{$status}) {
		$returnStatus = $codes->{$status};
	} # if
	
	return $returnStatus;
	
} # end sub getStatus

=item C<getColoredStatus>

Method getColoredStatus gets respective message in color for passed status

params:

	$status mixed

return:

	$returnStatus mixed

=back

=cut

sub getColoredStatus($) {
	
	my $self = shift;
	my $status = shift;

	if($codes->{$status}) {
		$returnStatus = "\033[" . $colors->{$status} ."m" . $codes->{$status} . "\033[0m";
	} # if
	
	return $returnStatus;
	
} # end sub getStatus

=head1 DEPENDENCIES

	SysAdmToolkit::Patterns::Prototype

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
