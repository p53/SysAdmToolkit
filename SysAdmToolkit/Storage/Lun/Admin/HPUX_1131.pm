package SysAdmToolkit::Storage::Lun::Admin::HPUX_1131;

=head1 NAME

SysAdmToolkit::Storage::Lun::Admin::HPUX_1131 - interface module for getting info about Luns

=head1 SYNOPSIS

	my $lunAdmin = SysAdmToolkit::Storage::Lun::Admin::HPUX_1131->new();
										
	my @luns = $lunAdmin->getLuns('type' => 'emc');

=head1 DESCRIPTION

Module should help in getting info about luns

=cut

use base qw/
				SysAdmToolkit::Patterns::Prototype
				SysAdmToolkit::Patterns::Getter
			/;

use SysAdmToolkit::Term::Shell;

=head1 PRIVATE PROPERTIES

=over 12

=item arrayTypesCmd hash

Private property stores commands needed for getting info about storage from several vendors

=cut

my %arrayTypesCmd = (
						'eva' => {'cmd' => 'evainfo', 'options' => '-alp'},
						'hitachi' => {'cmd' => 'inqraid', 'options' => '-CLIWP -fcx /dev/rd*sk/*'},
						'emc' => {'cmd' => 'inq.hpux64' , 'options' => '-showvol -nodots -sid -f_emc|grep -v "Inquiry utility"|grep -v "For help"|grep -v "Copyright"|grep -v ":SER NUM"|grep -v "\---------------"|grep -v ^$'},
					);

=item emcPropertis array

Private property contains properties valid for EMC storage

=cut

my @emcProperties = qw/
						dev
						vendor
						product
						rev
						serial
						lunid
						size
						frame
					/;

=item hitachiProperties array

Private property contains properties valid for HITACHI storage

=cut

my @hitachiProperties = qw/
							dev
							pwwn
							al
							port
							lun
							frame
							lunid
							product
						/;

=item evaProperties array

Private property contains properties for EVA storage

=back

=cut
					
my @evaProperties = qw/
						dev
						path
						tgt
						lun
						frame
						port
						vendor
						product
						revision
						ctrl
						lunid
						size
						props
					/;

=head1 METHODS

=over 12

=item C<getLuns>

METHOD getLuns gets info about luns for specified storage type

params:

	type string - is vendor name from arrayTypesCmd hash
	
return:

	array ref- array of hash properties for each lun
	
=cut

sub getLuns() {
	
	my $self = shift;
	my %params = @_;
	my $type = $params{'type'};
	my $lunsProcessed = [];
	
	if(!$type) {
		die("You must specify vendor\n!");	
	} # if
	
	my $storageCmd = $arrayTypesCmd{$type}->{'cmd'};
	my $storageOpt = $arrayTypesCmd{$type}->{'options'};
	my $parseMethod = 'parse' . ucfirst($type);
		
	my $shell = SysAdmToolkit::Term::Shell->new();
	
	if($shell->isCmdPresent($storageCmd)) {
		
		my $lunsInfoCmd = $shell->execCmd('cmd' => "$storageCmd $storageOpt", 'cmdsNeeded' => [$storageCmd, 'grep']);
		
		if(!$lunsInfoCmd->{'returnCode'}) {
			die("There was some problem getting Lun info: " . $lunsInfoCmd->{'msg'} . "!\n");
		} # end if
	
		my @luns = split("\n", $lunsInfoCmd->{'msg'});
		$lunsProcessed = $self->$parseMethod('luns' => \@luns);
	
	} # if
	
	return $lunsProcessed;
	
} # end sub getLuns

=item C<getAllLuns>

METHOD getAllLuns gets luns for each vendor from arrayTypesCmd hash

return:

	array ref - array of hash ref for each lun
	
=cut

sub getAllLuns() {
	
	my $self = shift;
	my @allLuns = ();
	
	for my $vendor(keys %arrayTypesCmd) {
	
		my $vendorLuns = $self->getLuns('type' => $vendor);
		@allLuns = (@allLuns, @$vendorLuns);
		
	} # for
	
	return \@allLuns;
	
} # end sub getAllLuns

=item C<checkPathCount>

METHOD checkPathCount check path count for each lun supplied within array and compares to count value supplied

params:

	luns array ref - array of hash ref of luns
	
	count int - number of paths which luns should have
	
return:

	boolean - return true if all luns have path count greater than count value, otherwise false
	
=cut

sub checkPathCount() {
	
	my $self = shift;
	my %params = @_;
	my $luns = $params{'luns'};
	my $threshold = $params{'count'};
	
	for my $lun(@$luns) {
	
		%lookupParams = (
							'dev' => 'c\d{1,3}t\d{1,3}d\d{1,3}', 
							'lunid' => $lun->{'lunid'}, 
							'frame' => $lun->{'frame'}, 
							'luns' => $luns,
							'order' => ['lunid', 'dev', 'frame']
						);
						
		my $paths = $self->findBy(%lookupParams);
								
		my $pathCount = @$paths;
		
		if($pathCount < $threshold) {
			return 0;
		} # if
		
	} # for
	
	return 1;
	
} # end sub checkPathCount

=item C<findBy>

METHOD findBy searches supplied array for values supplied as parameters in order supplied in order parameter

params:

	luns array ref - is array of hash ref
	
	order array ref - array of filters, is used to filter in order of this array
	
	any string - you can supply any parameter by which to filter and this parameter must be present in order array
	
return:

	array ref - returns array of hash refs filtered by supplied criteria
	
=cut

sub findBy() {

	my $self = shift;
	my %params = @_;
	my $filteredRecords = $params{'luns'};
	my $order = $params{'order'};
	
	if(!$params{'order'}) {
		die("You must specify order parameter!\n");	
	} # if
	
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

=item C<findOneBy>

METHOD findOneBy searches supplied array for values supplied as parameters in order supplied in order parameter
doesn't check for all occurrences, just one

params:

	luns array ref - is array of hash ref
	
	order array ref - array of filters, is used to filter in order of this array
	
	any string - you can supply any parameter by which to filter and this parameter must be present in order array
	
return:

	array ref - returns array of hash refs filtered by supplied criteria
	
=cut

sub findOneBy() {
	
	my $self = shift;
	my %params = @_;
	my $filteredRecords = $params{'luns'};
	my $order = $params{'order'};
	delete $params{'order'};

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

=item C<findOsOneBy>

METHOD findOsOneBy searches supplied array for values supplied as parameters in order supplied in order parameter
doesn't check for all occurrences, just one - this method is modified on each version of OS to select one lun

params:

	luns array ref - is array of hash ref
	
	order array ref - array of filters, is used to filter in order of this array
	
	any string - you can supply any parameter by which to filter and this parameter must be present in order array
	
return:

	array ref - returns array of hash refs filtered by supplied criteria
	
=cut

sub findOsOneBy() {
	
	my $self = shift;
	my %params = @_;

	if(exists($params{'dev'})) {
		die("This command doesn't take dev parameter!\n");
	} # if
	
	$params{'dev'} = '^disk.*'; 
		
	my @matched = $self->findOneBy(%params);

	return \@matched;
	
} # end sub findOsOneBy

=item C<parseEva>

METHOD parseEva parses output from eva tool

params:

	luns array ref - lines from eva tool output
	
return:

	array ref - array of hash ref of luns properties
	
=cut

sub parseEva() {
	
	my $self = shift;
	my %params = @_;
	
	my $evaLuns = $params{'luns'};
	my @evaLunsArray = ();
	
	for my $evaLun(@$evaLuns) {
	
		my $lunInfo = {};

		if($evaLun !~ /evainfo/ && $evaLun !~ /Controller#/ && $evaLun !~ /EVA/) {
			
			my @fields = split(' ', $evaLun);
			my $index = 0;
			
			for my $property(@evaProperties) {
				
					if($index == 0) {
						my @devsPath = split('/', $fields[$index]);
						$fields[$index] = $devsPath[3]; 	
					} # if
					
					if($index == 11) {
						$fields[$index] =~ s/MB//;	
					} # if
					
					$fields[$index] =~ s/\s+//g;
					$lunInfo->{$property} = $fields[$index];
					$index++;
					
			} # for
		
			push(@evaLunsArray, $lunInfo);
			
		} # if
		
	} # for
	
	return \@evaLunsArray;
	
} # end sub parseEva

=item C<parseHitachi>

METHOD parseHitachi parses output from hitachi storage tool

params:

	luns array ref - lines from eva tool output
	
return:

	array ref - array of hash ref of luns properties
	
=cut

sub parseHitachi() {
	
	my $self = shift;
	my %params = @_;
	
	my $hitachiLuns = $params{'luns'};
	my @hitachiLunsArray = ();
	
	for my $hitachiLun(@$hitachiLuns) {
	
		my $lunInfo = {};
		my @fields = split(' ', $hitachiLun);
		
		my $substrIndx = index($fields[3], 'CL');
		
		if($substrIndx > -1) {
			
			my $index = 0;
			
			for my $property(@hitachiProperties) {
					$fields[$index] =~ s/\s+//g;
					$lunInfo->{$property} = $fields[$index];
					$index++;
			} # for
		
			push(@hitachiLunsArray, $lunInfo);
		
		} # if
		
	} # for
	
	return \@hitachiLunsArray;
	
} # end sub parseHitachi

=item C<parseEmc>

METHOD parseHitachi parses output from emc storage tool

params:

	luns array ref - lines from emc tool output
	
return:

	array ref - array of hash ref of luns properties
	
=cut

sub parseEmc() {
	
	my $self = shift;
	my %params = @_;
	
	my $emcLuns = $params{'luns'};
	my @emcLunsArray = ();
	
	for my $emcLun(@$emcLuns) {
	
		my $lunInfo = {};
		my @fields = split(':', $emcLun);
		
		my $substrIndx = index($fields[2], 'SYMMETRIX');
		
		if($emcLun =~ /rdsk/ || $emcLun =~ /rdisk/) {
			
			if($substrIndx > -1) {
				
				my $index = 0;
				
				for my $property(@emcProperties) {
						
						$fields[$index] =~ s/\s+//g;
						
						if($index == 0) {
							my @devsPath = split('/', $fields[$index]);
							$fields[$index] = $devsPath[3];
						} # if
						
						if($index == 5) {
							$fields[$index] =~ s/^[0]+//;
						} # if
						
						if($index == 7) {
							$fields[$index] =~ s/^[0]+//;
						} # if
						
						$lunInfo->{$property} = $fields[$index];
						$index++;
						
				} # for
			
				push(@emcLunsArray, $lunInfo);
				
			} # if
		
		} # if
		
	} # for
	
	return \@emcLunsArray;
	
} # end sub parseEmc

=head1 DEPENDENCIES

	SysAdmToolkit::Patterns::Prototype
	SysAdmToolkit::Patterns::Getter
	SysAdmToolkit::Term::Shell

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;