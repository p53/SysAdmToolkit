package SysAdmToolkit::File::Config::Xml;

=head1 NAME

SysAdmToolkit::File::Config::Xml - module for manipulating xml configs

=head1 SYNOPSIS

	my $xmlConfig = SysAdmToolkit::File::Config::Xml->new(
											'rootName' => 'settings', 
											'xmlFile' => '/home/user/xmlconfig.xml'
										);
										
	my $val1 = $xmlConfig->get('/settings/parameter');
	my $val2 = $xmlConfig->getValue('source' => '/settings/parameter', 'path' => 'param1/value');
	my $val3 = $xmlConfig->getArray('source' => '/settings/parameters', 'path' => 'params/values');

=head1 DESCRIPTION

Module is used for getting data from xml configs in more straight-forward way

=cut

use base 'SysAdmToolkit::Patterns::Prototype';

use XML::Simple;

=head2 METHODS

=over 12

=item C<_init>

Method initializies xml object and data

params: 

	rootName string - name of root element of xml config

	xmlFile string - path to xml config

=cut

sub _init () {
	my $self = shift;
	my $xmlObject = XML::Simple->new(NoAttr=>0,RootName=>$self->{rootName});
	my $xmlData = $xmlObject->XMLin($self->{xmlFile});
	$self->{'xml'} = $xmlObject;
	$self->{'xmlSource'} = $xmlData;
} # end sub _init

=item C<save>

Method save saves data to xml file

params: 

	data hash ref- data which we want to store

	toFile string - path to xml file, where will be xml config written

	rootName string - name of root element of created xml config

return: $success boolean

=cut

sub save($$$) {
	
	my $self = shift;
	my %parms = @_;
	my $data = $parms{'data'};
	my $toFile = $parms{'toFile'};
	my $rootElement = $parms{'rootName'};
	
	my $xmlObject = XML::Simple->new(NoAttr=>0,RootName=>$rootElement);
	my $xmlData = $xmlObject->XMLin($toFile);
	
	open my $filehandler,">:utf8",$toFile or die $!;
	my $success = $xmlObject->XMLout($data,'OutputFile' => $filehandler,XMLDecl => 1);
	close $filehandler;
	
	return $success;
	
} # end sub save

=item C<get>

Method get gets value of element on path specified by parameter
it is getting value by parsing path and cycle through xml until it gets
final element

params: $path string

return: $element mixed

=cut

sub get($) {
	
	my $self = shift;
	my $path = shift;
	my @pathParts = ();
	
	# parsing path
	if(index($path, '/') == -1) {
		$pathParts[0] = $path;
	} else {
		@pathParts = split('/', $path);
	} # if
	
	my $element = $self->{'xmlSource'};
	
	# cycling through path parts to get final element
	foreach my $part(@pathParts) {
		$element = $element->{$part};	
	} # foreach
	
	return $element;
	
} # end sub get

=item C<getValue>

Method getValue gets value of element from hash reference specified and by
path specified

params: 

	source hash ref

	path string

return: $souce mixed

=cut

sub getValue($$) {
	
	my $self = shift;
	my %params = @_;
	my $source = $params{'source'};
	my $path = $params{'path'};
	my @pathParts = ();
	
	if(index($path, '/') == -1) {
		$pathParts[0] = $path;
	} else {
		@pathParts = split('/', $path);
	} # if
	
	foreach my $part(@pathParts) {
		$source = $source->{$part};	
	} # foreach
	
	return $source;
	
} # end sub getValue

=item C<getArray>

Method getArray gets array ref from source and specified on path

params: 

	source hash ref

	path string

return: $result array ref

=cut

sub getArray($$) {
	
	my $self = shift;
	my %params = @_;
	my $source = $params{'source'};
	my $path = $params{'path'};
	my @pathParts = ();
	
	if(index($path, '/') == -1) {
		$pathParts[0] = $path;
	} else {
		@pathParts = split('/', $path);
	} # if

    my $result = [];

	my $size = @pathParts;
	my $index = 0;
	
    foreach my $part(@pathParts) {
    	$index++;
    	if((ref($source->{$part}) eq 'HASH') && ($index == $size)) {
    		$result->[0] = $source->{$part};
    	} elsif (ref($source->{$part}) eq 'HASH') {
			$source = $source->{$part};
		} elsif(ref($source->{$part}) eq 'ARRAY') {
			$result = $source->{$part};
		} elsif(ref($source->{$part}) eq 'SCALAR') {
			$result->[0] = $source->{$part};
		} else {
			$result->[0] = $source->{$part};
		} # if
	} # foreach
	
	return $result;
	
} # end sub getArray

=item C<valToArray>

Method valToArray creates array ref containing value specified as parameter
if supplied parameter is not array ref

params: $val mixed

return: $val array ref

=back

=cut

sub valToArray($) {
	
	my $self = shift;
	my $val = shift;
	my $converted = [];
	
	if(ref($val) ne 'ARRAY') {
		$converted = [$val];
		return $converted;
	} # if
	
	return $val;
	
} # end sub valToArray

=head1 DEPENDENCIES

	SysAdmToolkit::Patterns::Prototype
	XML::Simple

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
