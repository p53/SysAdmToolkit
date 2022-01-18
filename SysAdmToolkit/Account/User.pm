package SysAdmToolkit::Account::User;

=head1 NAME

SysAdmToolkit::Account::User - module to get info about Unix user account

=head1 SYNOPSIS

	use SysAdmToolkit::Account::User;

	This will initialize with currently logged user
	my $user = SysAdmToolkit::Account::User->new();

	This will initiliaze with data for user with id 0
	my $user1 = SysAdmToolkit::Account::User->new('id' => 0);

	This will initialize data for user with name root
	my $user2 = SysAdmToolkit::Account::User->new('userName' => 'root');

	$user->getHome();

=head1 DESCRIPTION

This module gets basic account data for user 
currently logged or specified by id/userName
on Unix systems.

=cut

use base 'SysAdmToolkit::Patterns::Prototype';

use SysAdmToolkit::Term::Shell;

=head1 PRIVATE VARIABLES

=over 12

=item passwdFile string

Stores location of passwd file

=cut

my $passwdFile = '/etc/passwd';

=item user string

Stores user account name

=cut

my $user = '';

=item passwd string

Stores password

=cut

my $passwd = '';

=item userId int

Stores user id

=cut

my $userId = '';

=item groupId int

Stores primary group id of user

=cut

my $groupId = '';

=item comment string

Comment for user

=cut

my $comment = '';

=item homeFolder string

Stores location of home folder of user

=cut

my $homeFolder = '';

=item shell string

Stores shell location for user

=cut

my $shell = '';

=item currentTerm string

Stores info about current terminal under which user is logged

=back

=cut

my $currentTerm = '';


=head2 METHODS

=over 12

=item C<_init>

Method initializies object with user data from passwd file,
for user specified during object creation

=cut

sub _init() {
	
	my $self = shift;
	my %parms = @_;
	my $accountInfoResult = '';
	my $accountArgs = '';
	my $termShell = SysAdmToolkit::Term::Shell->new();
	
	if($parms{'id'} || $parms{'userName'}) {

		if($parms{'id'}) {
			$accountArgs = ':' . $parms{'id'} . ': ' . $passwdFile;
		} elsif($parms{'userName'}) {
			$accountArgs = $parms{'userName'} . ': ' . $passwdFile;
		} # if
	
	} else {
		my $result = $termShell->execCmd('cmd' => 'id -un', 'cmdsNeeded' => ['id']);
		$termShell->warning($result);
		$accountArgs = $result->{'msg'} . ': ' . $passwdFile;
	} # if
	
	$accountInfoResult = $termShell->execCmd('cmd' => 'grep' . ' ' . $accountArgs, 'cmdsNeeded' => ['grep']);
	$termShell->warning($accountInfoResult);
	
	my $terminalResult = $termShell->execCmd('cmd' => 'tty', 'cmdsNeeded' => ['tty']);
	$termShell->warning($terminalResult);
	
	($user, $passwd, $userId, $groupId, $comment, $homeFolder, $shell) = split(':', $accountInfoResult->{'msg'});
	$currentTerm = $terminalResult->{'msg'};
	
} # end sub _init

=item C<getUser>

Method getUser gets user name for user

Return: $user string

=cut

sub getUser() {
	my $self = shift;
	return $user;
} # end sub getUser

=item C<getUserId>

Method getUserId returns user id number for user

Return: $userId int

=cut

sub getUserId() {
	my $self = shift;
	return $userId;
} # end sub getUserId

=item C<getGroupId>

Method getGroupId returns group id of group of user

Return: $groupId int

=cut

sub getGroupId() {
	my $self = shift;
	return $groupId;
} # end sub getGroupId

=item C<getComment>

Method getComment returns comment for user

Return: $comment string

=cut

sub getComment() {
	my $self = shift;
	return $comment;
} # end sub getComment

=item C<getHome>

Method getHome returns home folder for user

Return: $homeFolder string

=cut

sub getHome() {
	my $self = shift;
	return $homeFolder;
} # end sub getHome

=item C<getShell>

Method getShell returns shell for user

Return: $shell string

=cut

sub getShell() {
	my $self = shift;
	return $shell;
} # end sub getShell

=item C<getCurrentTerm>

Method getCurrentTerm return current terminal of user

Return: $currentTerm string

=cut

sub getCurrentTerm() {
	my $self = shift;
	return $currentTerm;
} # end sub getCurrentTerm

=item C<isRoot>

Method isRoot tests if user is root

Return: $result boolean

=back

=cut

sub isRoot() {
	
	my $self = shift;
	my $result = 0;
	
	if($user eq 'root') {
		$result = 1;		
	} # if
	
	return $result;
	
} # end sub isRoot

=head1 DEPENDENCIES

	SysAdmToolkit::Patterns::Prototype
	SysAdmToolkit::Term::Shell

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
