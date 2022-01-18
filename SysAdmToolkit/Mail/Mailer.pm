package SysAdmToolkit::Mail::Mailer;

=head1 NAME

SysAdmToolkit::Mail::Mailer - module for sending emails, dependent on mailx utility

=head1 SYNOPSIS

	my $mailer= SysAdmToolkit::Mail::Mailer->new();
										
	$mailer->setSubject('My mail')->setTo('pk234@att.com')->setMessage('Hi this is my mail');
	$mailer->send();

=head1 DESCRIPTION

Module is used for sending emails. NOTE: you can send attachment and message string simultaneously
just in case you set message from file with setFile method, due to limitations of mailx utility

=cut

use base 'SysAdmToolkit::Patterns::Prototype';

use SysAdmToolkit::Term::Shell;
use IO::File;

=head1 METHODS

=over 12

=item C<_init>

Method _init initializies module and used utilities

=cut

sub _init() {
	my $self = shift;
	$self->{'mailUtil'} = 'mailx';
	$self->{'encodingUtil'} = 'uuencode';
} # end sub _init

=item C<setSubject>

Method setSubject sets subject to email

=cut

sub setSubject($) {
	my $self = shift;
	my $subject = shift;
	$self->{'subject'} = $subject;
	return $self;
} # end sub setSubject

=item C<setTo>

Method setTo sets recipient/s of the emails

=cut

sub setTo($) {
	my $self = shift;
	my $to = shift;
	$self->{'to'} = $to;
	return $self;
} # end sub setTo

=item C<setMessage>

Method setMessage sets message for body of the email

=cut

sub setMessage($) {
	my $self = shift;
	my $message = shift;
	$self->{'message'} = $message;
	return $self;
} # end sub setMessage

=item C<setFile>

Method setFile is used for setting file from which body of the email
will be made, it is only possibility when you want ot send message along
with attachment

=cut

sub setFile($) {
	my $self = shift;
	my $messageFile = shift;
	$self->{'messageFile'} = $messageFile;
	return $self;
} # end sub setFile

=item C<setAttachment>

Method setAttachment sets location of file attached

=cut

sub setAttachment($) {
	my $self = shift;
	$self->{'attachment'} = shift;
	return $self;
} # end sub setAttachment

=item C<setStringToAttachment>

Method setStringToAttachment can made attachment from string,
can be used for generating attachments in scripts

=cut

sub setStringToAttachment($$) {
	my $self = shift;
	my %params = @_;
	$self->{'strToAttach'} = $params{'string'};
	$self->{'nameOfAttach'} = $params{'name'};
	return $self;
} # end sub setStringToAttachment

=item C<send>

Method send sends email

=back

=cut

sub send() {
	
	my $self = shift;
	my $messageFile = $self->{'messageFile'};
	my $shell = SysAdmToolkit::Term::Shell->new();
	my $mailUtil = $self->{'mailUtil'};
	my $encodeUtil = $self->{'encodingUtil'};
	my $strToAttach = $self->{'strToAttach'};
	my $nameOfAttach = $self->{'nameOfAttach'};
	my $subject = $self->{'subject'};
	my $to = $self->{'to'};
	my $messageCmd = '';
	my $fileOpt = '';
	my $attachCmds = '';
	my $strToAttachCmds = '';
	
	# here we set the option for reading body messages from file
	if($messageFile) {
		$fileOpt = " -f $messageFile ";
	} # if
	
	# setting commands for reading attachment from file
	if(defined($self->{'attachment'})) {
		if(-s $self->{'attachment'}) {
			$attachCmds = $encodeUtil . " " . $self->{'attachment'} . " " . $self->{'attachment'} . '|';
		} # if
	} # if
	
	# setting commands for making attachment from string
	if($self->{'strToAttach'}) {
		my $string = $self->{'strToAttach'};
		$string =~ s/\'/\\'/g;
		$string =~ s/\"/\\"/g;
		$string =~ s/\n//g;
		$strToAttachCmds = 'perl -we \'my $str=pack("u", "' . $string  . '");print "begin 444 ' . $nameOfAttach . '\n" . $str . "`\nend\n";\'|';
	} # if
	
	$message = $self->{'message'};
	
	if($message) {
		$messageCmd = 'echo \'' . $message . '\'|';
	} # if
	
	my $cmd = $messageCmd . $strToAttachCmds . $attachCmds . $mailUtil . $fileOpt . ' -m -s \'' . $subject  . '\' ' . $to;
	
	my $result = $shell->execCmd('cmd' => "$cmd", 'cmdsNeeded' => ['echo', 'ksh', $mailUtil, $encodeUtil, 'perl']);
	
	$shell->warning($result);
	
	return $result; 
	
} # end sub send

=head1 DEPENDENCIES

	SysAdmToolkit::Patterns::Prototype
	SysAdmToolkit::Term::Shell
	IO::File

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
