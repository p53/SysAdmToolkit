package SysAdmToolkit::Utility::Array;

=head1 NAME

SysAdmToolkit::Utility::Array - utility module for manipulating arrays, hash arrays etc...

=head1 SYNOPSIS

	my $test = ['car', 'bar', 'bike'];
	my $sec = ['car', 'phone'];
	my $ha = [
		{'name'=> 'Paul', 'age'=> 25},
		{'name'=> 'Paul', 'age'=> 20},
		{'name'=> 'Karin', 'age'=> 65}
	];
	
	my $to = [
		'name age parent',
		'paul 25 Carol',
		'paul 20 Martin',
		'paul 65 Olga',
	];
	
	my $arrayUtil = SysAdmToolkit::Utility::Array->new();
										
	# will return true because test array contains car									
	$arrayUtil->hasValue('car', $test);

	# difference between plain arrays
	# difference array will be ['bar', 'bike']
	my $difference = $arrayUtil->diff($test, $sec);
	
	# uniq records by hash property
	# uniqed will contain {'name'=> 'Paul', 'age'=> 25}, {'name'=> 'Karin', 'age'=> 65}
	my $uniqed = $arrayUtil->uniqHashArrayBy('hashArray' => $ha, 'field' => 'name');
	
	# sorted will be {'name'=> 'Karin', 'age'=> 65}, {'name'=> 'Paul', 'age'=> 20}, {'name'=> 'Paul', 'age'=> 25},
	$arrayUtil->sortHashArrayBy('hashArray' => $ha, 'field' => 'name');
	
	# result will contain {'name'=> 'Karin', 'age'=> 65}, order is array according which order parameters will be looked up
	$arrayUtil->findInHashArrayBy('hashArray' => $ha, 'name' => 'Karin', 'order' => ['name']);
	
	# result {'name'=> 'Paul', 'age'=> 25}
	$arrayUtil->findInHashArrayOneBy('hashArray' => $ha, 'name' => 'Karin', 'order' => ['name']);
	
	# result will be
	# {'name'=> 'Paul', 'age'=> 25, 'parent'=> Carol},
	# {'name'=> 'Paul', 'age'=> 20, 'parent'=> Martin},
	# {'name'=> 'Karin', 'age'=> 65, 'parent'=> Olga}
		
	$arrayUtil->arrayToAssoc('array' => $to, 'fieldSep' => '\s+');
	
=head1 DESCRIPTION

Module is utility module for several types of manipulation with arrays

=cut

=head1 METHOD

=over 12

=item C<hasValue>

Method hasValue check if array contains value

params:

	value mixed - we check presence of this item
	
	array array - array where we check
	
return:

	boolean

=cut

sub hasValue($$) {
	
	my $class = shift;
	my $value = shift;
	my $array = shift;
	
	my %testingHash = map { $_ => } @$array;
	
	if(exists($testingHash{$value})) {
		return 1;	
	} # if
	
	return 0;
	
} # end sub hasValue

=item C<diff>

Method diff returns array which contains all entries in main array which are not in substracted array

params:

	mainArray array - this is the main array
	
	substractedArray - this is substracted array
	
return:

	array ref
	
=cut

sub diff($$) {
	
	my $self = shift;
	my $mainArray = shift;
	my $substractedArray = shift;
	my %substractedHash = ();
	
	%substractedHash = map {$_=>1} @$substractedArray;
	@diff = grep(!defined $substractedHash{$_}, @$mainArray);
	
	return \@diff;
	
} # end sub diff

=item C<uniqHashArrayBy>

Method uniqHashArrayBy will uniq from records on supplied property value pair

params:

	hashArray array ref - this is array of hash refs
	
	field - this is field on which do uniq

return:

	array ref - array of uniq hash records
	
=cut

sub uniqHashArrayBy() {

	my $self = shift;
	my %params = @_;
	my $hashArray = $params{'hashArray'};
	my $uniqField = $params{'field'};
	my @uniqRecords = ();
	
	if(!exists($params{'hashArray'})) {
		die("You need to supply hash array!\n");
	} # if
	
	if(!exists($params{'field'})) {
		die("You need to supply field on which do uniq\n!");
	} # if
	
	my $seen = {};
	
	for my $hashRec(@$hashArray) {
		
		my $uniqedItem = $hashRec->{$uniqField};
		
		if(!$seen->{$uniqedItem}) {
			$seen->{$uniqedItem}++;	
			push(@uniqRecords, $hashRec);
		} # if
		
	} # for
	
	return \@uniqRecords;
	
} # end sub uniqRecHashArray

=item C<sortHashArrayBy>

Method sortHashArrayBy sorts hash records in array according supplied field

params:

	hashArray array ref - this is sorted array of hashes
	
	field - we sort by this field
	
return:

	array ref
	
=cut

sub sortHashArrayBy() {
	
	my $self = shift;
	my %params = @_;
	my $hashArray = $params{'hashArray'};
	my $sortField = $params{'field'};
	my %sorted = ();
	my $index = 0;
	my @sortedResult = ();
	
	for my $hashRec(@$hashArray) {
		
		my $sortedItem = $hashRec->{$sortField};

		if(!exists($sorted{$sortedItem})) {
			$sorted{$sortedItem} = [];
		} # if
		
		push(@{$sorted{$sortedItem}}, $index);
		$index++;
		
	} # for
	
	my @sortedKeys = sort { $a cmp $b } keys %sorted;
	
	for my $sortedKey(@sortedKeys) {
		
		for my $position(@{$sorted{$sortedKey}}) {
			
			push(@sortedResult, $hashArray->[$position]);
				
		} # for
		
	} # for
	
	return \@sortedResult;
	
} # end sub sortRecHashArray

=item C<findInHashArrayBy>

Method findInHashArrayBy looks in array of hash refs by properties supplied in order supplied in order param

params:

	hashArray array ref
	
	order array ref - this is list of properties supplied and properties are searched according order of this array

	any string - this are supplied property value pairs by which to search
	
=cut

sub findInHashArrayBy() {

	my $self = shift;
	my %params = @_;
	my $filteredRecords = $params{'hashArray'};
	my $order = $params{'order'};
	delete $params{'order'};
	
	my @matched = ();
	
	for my $record(@$filteredRecords) {
		
		my $pass = 1;
		
		for my $filter(@$order) {
			
			if(!exists($params{"$filter"})) {
				die("You didn't supply filter parameter $filter, which is present in order parameter!\n");	
			} # if
			
			my $filterValRegex = $params{"$filter"};
			
			if($record->{"$filter"} !~ /$filterValRegex/) {
				$pass = 0;
				last;
			} # if
		} # for
		
		if($pass == 1) {
			push(@matched, $record);	
		} # if
		
	} # for
	
	return \@matched;
	
} # end sub findBy

=item C<findInHashArrayOneBy>

Method findInHashArrayOneBy looks in array of hash refs by properties supplied in order supplied in order param and returns just one record
with searched property value pair

params:

	hashArray array ref
	
	order array ref - this is list of properties supplied and properties are searched according order of this array

	any string - this are supplied property value pairs by which to search
	
=cut

sub findInHashArrayOneBy() {
	
	my $self = shift;
	my %params = @_;
	my $filteredRecords = $params{'hashArray'};
	my $order = $params{'order'};
	delete $params{'order'};

	if(!exists($params{'hashArray'})) {
		die("You must supply hashArray parameter!\n");	
	} # if
	
	if(!exists($params{'order'})) {
		die("You must supply order parameter!\n");	
	} # if
	
	my %found = ();
	my @matched = ();
	
	for my $record(@$filteredRecords) {
		
		my $pass = 1;
		my $foundKey = '';
		
		for my $filter(@$order) {
			
			if(!exists($params{"$filter"})) {
				die("You didn't supply filter parameter $filter, which is present in order parameter!\n");	
			} # if
			
			my $filterValRegex = $params{"$filter"};
			
			if($record->{"$filter"} !~ /($filterValRegex)/) {
				$pass = 0;
				$foundKey = '';
				last;
			} else {
				$foundKey .= $1;
			} # if
			
		} # for
		
		if($pass == 1) {
			
			if(!exists($found{$foundKey})) {
				push(@matched, $record);
				$found{$foundKey} = 1;
			} # if
				
		} # if
		
	} # for
	
	return \@matched;
	
} # end sub findOneBy

=item C<arrayToAssoc>

Method arrayToAssoc converts array with first row as properties and others with property values
to array of hash ref

params:

	array array ref
	
	fieldSep string
	
return:

	array ref
	
=back

=cut

sub arrayToAssoc() {
	
	my $self = shift;
	my %params = @_;
	my $array = $params{'array'};
	my $fieldSep = $params{'fieldSep'};
	my @records = ();
	my @header = ();
	
	if(!exists($params{'array'})) {
		die("You must supply array!\n");	
	} # if
	
	if(!exists($params{'fieldSep'})) {
		die("You must supply field separator!\n");
	} # if
	
	my $index = 0;
	
	for my $row (@$array) {
		
		chomp $row;

		my @fields = split(/$fieldSep/, $row);
		
		if($index == 0) {
			for my $clfield(@fields) {
                $clfield =~ s/\s+//g;
                push(@header, $clfield);
            } # for
		} else {
		
			my %record = ();
			
			my $fieldIndex = 0;
			
            for my $field(@header) {
            	$fields[$fieldIndex] =~ s/^\s|\s$//g;
                $record{$field} = $fields[$fieldIndex];
                $fieldIndex++;
            } # for
				
			push(@records, \%record);
		
		} # if
		
		$index++;
		
	} # for
	
	return \@records;
	
} # end sub arrayToAssoc

=head1 DEPENDECIES

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;