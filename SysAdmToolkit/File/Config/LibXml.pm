package SysAdmToolkit::File::Config::LibXml;

=head1 NAME

SysAdmToolkit::File::Config::LibXml - module for manipulating xml configs with LibXml library

=head1 SYNOPSIS

	my $config = SysAdmToolkit::File::Config::LibXml->new(
											'xmlFile' => '/home/user/xmlconfig.xml'
										);
										
	my $val1 = $config->get('/settings/parameter');
	my $val2 = $config->getValue('source' => '/settings/parameter', 'path' => 'param1/value');
	my $val3 = $config->getArray('source' => '/settings/parameters', 'path' => 'params/values');

=head1 DESCRIPTION

Module is used for getting data from xml configs in more straight-forward way

=cut

use base 'SysAdmToolkit::Patterns::Prototype';

use XML::LibXML;

=head2 METHODS

=over 12

=item C<_init>

Method initializies xml object and data

params: 

	xmlFile string - path to xml config

=cut

sub _init() {
	my $self = shift;
	$self->{'xml'} = XML::LibXML->load_xml('location' => $self->{'xmlFile'});
	return $self;
}

=item C<save>

Method saves passed XML DOM to specified file

params:

	doc - XML::LibXML::Document which we want to save
	
	to - file path to which we want to save xml dom
	
=cut

sub save() {
	
	my $self = shift;
	my %params = @_;
	my $to = $params{'to'};
	my $xmlDoc = $params{'doc'};
	
	my $result = $xmlDoc->toFile($to);
	
	return $result;
}

=item C<get>

Method gets value of element specified by path

params:

	path - it is XPath to element
	
=cut

sub get() {
	
	my $self = shift;
	my $path = shift;
	
	my $value = $self->{'xml'}->findvalue($path);
	
	return $value;
}

=item C<getValue>

Method gets value of element specified by XPath path
and from element passed

params:

	path - XPath to the requested element
	
	source - XML::LibXML::Node or Document from which we
	want to search
	
=cut

sub getValue() {

	my $self = shift;
	my %params = @_;
	my $path = $params{'path'};
	my $source = $params{'source'};
	
	my $value = $source->findvalue($path);

	return $value;
}

=item C<getArray>

Method gets array of values of elements specified by XPath path
and from element passed

params:

	path - XPath to the requested elements
	
	source - XML::LibXML::Node or Document from which we
	want to search
	
=cut

sub getArray() {
	
	my $self = shift;
	my %params = @_;
	my $path = $params{'path'};
	my $source = $params{'source'};
	my @values = ();
	
	my $nodes = $source->findnodes($path);

	foreach my $node(@$nodes) {
		push(@values, $node->textContent());
	}
	
	return \@values;
}

=item C<getElement>

Method gets element specified by XPath path
and from element passed

params:

	path - XPath to the requested element
	
	source - XML::LibXML::Node or Document from which we
	want to search
	
=cut

sub getElement() {
	
	my $self = shift;
	my %params = @_;
	my $path = $params{'path'};
	my $source = $params{'source'};
	
	my $el = $source->find($path);
	
	return $el->[0];
}

=item C<getElements>

Method gets elements specified by XPath path
and from element passed

params:

	path - XPath to the requested elements
	
	source - XML::LibXML::Node or Document from which we
	want to search
	
=cut

sub getElements() {
	
	my $self = shift;
	my %params = @_;
	my $path = $params{'path'};
	my $source = $params{'source'};
	
	my @els = $source->findnodes($path);
	
	return \@els;
}

1;