package SysAdmToolkit::Log::Rotator;

=head1 NAME

SysAdmToolkit::Log::Rotator - module for rotating logs

=head1 SYNOPSIS

	my $rotator = SysAdmToolkit::Log::Rotator->new();
										
	$rotator->setLevel(3);
	$rotator->rotate('/home/user/app.log');

=head1 DESCRIPTION

Module task is to help handling rotation of files

=cut

use base 'SysAdmToolkit::Patterns::Prototype';
use IO::Dir;
use IO::File;
use SysAdmToolkit::Exception::Directory;
use SysAdmToolkit::Exception::Catcher;

=head2 PRIVATE PROPERTIES

=over 12

=item catcher SysAdmToolkit::Exception::Catcher

	Property is holding Exception handling class

=cut

my $catcher = SysAdmToolkit::Exception::Catcher->new();

=item rotateLevel int

	Property is holding rotation level for rotated file

	default: 3

=cut

my $rotateLevel = 3;

=item dateFields array

	Property is holding shortcuts for fields which are available for date

=cut

my @dateFields = ('sec', 'min', 'hour', 'mday', 'mon', 'year', 'wday', 'yday', 'isdst');

=item dateFieldsIndexes hash ref

	Property is holding shortcuts to available date fields, their position in @dateFields property
	and their length

=cut

my $dateFieldsIndexes = {
						'sec' => {'index' => 0, 'length' => 2},
						'min' => {'index' => 1, 'length' => 2},
						'hour' => {'index' => 2, 'length' => 2},
						'mday' => {'index' => 3, 'length' => 2},
						'mon' => {'index' => 4, 'length' => 2},
						'year' => {'index' => 5, 'length' => 4},
						'wday' => {'index' => 6, 'length' => 2},
						'yday' => {'index' => 7, 'length' => 3},
						'isdst' => {'index' => 8, 'length' => 1}
					};

=item currentTime array

	Property contains data from localtime function

=cut

my @currentTime = localtime(time);

=item format array ref

	Property holds format of suffix used when rotating logs

	default: ['mday', 'mon', 'year']

=cut

my $format = ['mday', 'mon', 'year'];

=item orderableFormat array ref

	Property holds date format by which are files compared to order them

=cut

my $orderableFormat = ['year', 'yday', 'mon', 'mday', 'wday', 'hour', 'min', 'sec'];

=item permissions int

	Property holds permissions which are applied to new file

=back

=cut

my $permissions = 0755;

=head1 METHODS

=over 12

=item C<_init>

Method initializies object

=cut

sub _init() {

	my $self = shift;

	# here we calculate year and convert month form from 0-11 to 1-12
	$currentTime[5] = 1900 + $currentTime[5];
	$currentTime[4] = 1 + $currentTime[4];

	# here we convert week days from 0-6 to 1-7
	if($currentTime[6] == 0) {
		$currentTime[6] = 7;
	} # if

	return $self;

} # end sub _init

=item C<setLevel>

Method setLevel sets the level of file rotation (number of files kept)

params:

	$level int

return:

	$self SysAdmToolkit::Log::Rotator

=cut

sub setLevel($) {
	my $self = shift;
	my $level = shift;
	$rotateLevel =  $level;
	return $self;
} # end sub setLevel

=item C<setFormat>

Method setFormat sets the format of suffix used to keep rotated files

params:

	$format array ref

return:

	$self SysAdmToolkit::Log::Rotator

=cut

sub setFormat($) {
	my $self = shift;
	$format = shift;
	return $self;
} # end sub setFormat

=item C<setPermissions>

Method setPermissions is used for setting permissions which are used
on newly created file

params:

	$perm int

return:

	$self SysAdmToolkit::Log::Rotator

=cut

sub setPermissions($) {

	my $self = shift;
	my $perm = shift;
	$perm = sprintf("%04d", $perm);

	if($perm =~ /[0-7][0-7][0-7][0-7]/) {
		$permissions = "$perm";
	} else {
		my $permissionsException = SysAdmToolkit::Exception::Directory->new('msg' => 'Bad format of file permissions!');
		$catcher->throw($permissionsException);
	} # if

	return $self;

} # end sub setPermissions

=item C<rotate>

Method rotate is used for rotating file

params:

	$filePath string

return:

	$self SysAdmToolkit::Log::Rotator

=cut

sub rotate($) {

	my $self = shift;
	my $filePath = shift;
	$filePath =~ /^(.*)\/(.*)$/;
	my $dir = $1;
	my $file = $2;
	my @toRemove = ();

	if(-e $filePath) {
		# creating date stamp according format and renaming file to file.datestamp
		my $dateStamp = $self->createDateStamp();
		rename($filePath, $filePath . '.' . $dateStamp);
	} # if	

	# get all files in current dir, gets number of rotated files (levels) for rotated file
	my $files = $self->getFileList($dir);
	my $numOfFiles = $self->getNumOfFiles('file' => $file, 'files' => $files);

	# if there are more levels of rotated file, we need to sort it and remove oldest
	if($numOfFiles > 1) {

		# files rotated ordered by age descending
		$orderedFiles = $self->orderByAgeDesc('file' => $file, 'files' => $files);

		if($numOfFiles > $rotateLevel) {

			# levels of rotated file which are oldest will be sliced and then removed
			@toRemove = @$orderedFiles[$rotateLevel..$numOfFiles-1];

			foreach my $fileToRemove(@toRemove) {
				my $fullPathToRemove = $dir . '/' . $fileToRemove;
				unlink $fullPathToRemove or warn "Could not unlink $file: $fullPathToRemove!";
			} # foreach

		} # if

	} # if

	$newFile = IO::File->new($filePath, 'w');
	$newFile->close;

	chmod(oct($permissions), $filePath);

	return $self;

} # end sub rotate

=item C<getFileList>

Method getFileList gets all files in directory of rotated file

params:

	$dir string

return:

	$files array ref

=cut

sub getFileList($) {

	my $self = shift;
	my $dir = shift;

	opendir(my($dh), $dir);

	if(!$dh) {
		my $directoryException = SysAdmToolkit::Exception::Directory->new('msg' => "Could not open directory $dirname!");
		$catcher->throw($directoryException);
	} # if

	my @files = readdir $dh;

	closedir $dh;

	return \@files;

} # end sub getFileList

=item C<getNumOfFiles>

Method getNumOfFiles gets number of rotated files for currently rotated file

params:

	file string

	files array ref

return:

	$numOfMatches int

=cut

sub getNumOfFiles($$) {

	my $self = shift;
	my %params = @_;
	my $file = $params{'file'};
	my $files = $params{'files'};

	@matched = grep(/^$file\.\d+$/, @$files);
	$numOfMatches = @matched;

	return $numOfMatches;

} # end sub getNumOfFiles

=item C<orderByAgeDesc>

Method orderByAgeDesc orders all levels of rotated file by age in descending order

params:

	file string

	files array ref

return:

	$sortedFiles array ref

=cut

sub orderByAgeDesc($) {

	my $self = shift;
	my %params = @_;
	my $file = $params{'file'};
	my $files = $params{'files'};
	my $parsedFileTimes = {};

	my @matched = grep(/^$file\.\d+$/, @$files);

	# we get date stamp hash for each file than convert it to orderable format
	# this is format which when joined to string will create integer number expressing
	# age of file without need to convert it to seconds etc...
	# then we create hash with this integer as key and name of file as value and sort it
	# by this key, which will give us sort by age
	foreach my $matchedFile(@matched) {
		my $fileTimeHash = $self->parseFileTime($matchedFile);
		my $fileTime = $self->convertToOrderableFormat($fileTimeHash);
		$parsedFileTimes->{$fileTime} = $matchedFile;
	} # foreach

	my @sortedTimes = sort { $b <=> $a } keys %$parsedFileTimes;
	my @sortedFiles = ();

	foreach my $key (@sortedTimes) {
		push(@sortedFiles, $parsedFileTimes->{$key});
	} # foreach

	return \@sortedFiles;

} # end sub orderByAge

=item C<parseFileTime>

Method parseFileTime parses suffix stamp of rotated file to hash according format

params:

	$file string

return:

	$parsedHash hash ref

=cut

sub parseFileTime($) {

	my $self = shift;
	my $file = shift;
	my $parsedHash = {};
	my $time = 0;

	$file =~ /^.*\.(\d+)$/;

	$time = $1;

	my $start = 0;

	# we parse date stamp of rotated file to hash containing values 
	# of date fields as values with name of date fields as keys
	foreach my $formatPart(@$format) {

		my $lengthOfFormatPart = $dateFieldsIndexes->{$formatPart}->{'length'};

		$parsedHash->{$formatPart} = substr($time, $start, $lengthOfFormatPart);

		$start = $start + $lengthOfFormatPart;

	} # foreach

	return $parsedHash;

} # end sub parseFileTime

=item C<convertToOrderableFormat>

Method convertToOrderableFormat we create number from date stamp which
express age of file without converting them to seconds etc...

params:

	$parsedTime string

return:

	$orderableTime string

=cut

sub convertToOrderableFormat($) {

	my $self = shift;
	my $parsedTime = shift;
	my $orderableTime = '';

	foreach my $orderablePart(@$orderableFormat) {
		if(defined($parsedTime->{$orderablePart})) {
			$orderableTime .= $parsedTime->{$orderablePart};
		} # if
	} # foreach

	return $orderableTime;

} # end sub convertToOrderableFormat

=item C<createDateStamp>

Creates date stamp according supplied format

return:

	$dateStamp string

=back

=cut

sub createDateStamp() {

	my $self = shift;
	my @dateStampArray = ();

	foreach my $formatPart(@$format) {
		# we need date field length and also index of date field (they are stored in private variable @currentTime)
		# to properly get and format date fields
		my $dateFieldLength = $dateFieldsIndexes->{$formatPart}->{'length'};
		my $dateFieldIndex = $dateFieldsIndexes->{$formatPart}->{'index'};
		my $dateFieldStamp = sprintf("%0" . $dateFieldLength . "d", $currentTime[$dateFieldIndex]);
		push(@dateStampArray, $dateFieldStamp);
	} # foreach

	$dateStamp = join('', @dateStampArray);

	return $dateStamp;

} # end sub createDateStamp

=head1 DEPENDENCIES

	SysAdmToolkit::Patterns::Prototype
	IO::Dir
	IO::File
	SysAdmToolkit::Exception::Directory
	SysAdmToolkit::Exception::Catcher

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
