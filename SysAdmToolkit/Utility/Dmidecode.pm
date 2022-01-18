package SysAdmToolkit::Utility::Dmidecode;

=head1 NAME

SysAdmToolkit::Utility::Dmidecode - module for extracting information from dmidecode utility

=head1 SYNOPSIS

	my $dmi = SysAdmToolkit::Utility::Dmidecode->new();
	$info = $dmi->get('4'); # number is number of subsystem according dmidecode man page
	
	foreach my $dmiItem(@$info) {
		print $info->{'ProcessorInformation'}->{'ThreadCount'};
	}
	
	# get all subsystems
	$info = $dmi->get();

=cut

use base qw/
                SysAdmToolkit::Patterns::Prototype
           /;

use SysAdmToolkit::Term::Shell;

=head1  PRIVATE PROPERTIES

=over 12

=item biosDecodeUtil string

=back

=cut

my $biosDecodeUtil = 'dmidecode';

=head1 METHODS

=over 12

=item C<get>

Method get, returns all dmidecode information for specified subsystem or all subs

param:

	$type int - this is number of subsystem we want to get information for

return:

	$result array ref - array of all items for subsystem
	
=cut

sub get() {

        my $self = shift;
        my %params = @_;
        my $shell = SysAdmToolkit::Term::Shell->new();
        my $result = [];
        my $biosInfo = {};

		# checking if we specified type or no and executing command
        if(exists($params{'type'})) {
        	
                if($params{'type'} =~ /\d+/) {
                	$biosInfo = $shell->execCmd('cmd' => "$biosDecodeUtil -qt $params{'type'}", 'cmdsNeeded' => [$biosDecodeUtil]);
                } else{
                        die("You must supply type number!");
                } # if
                
        } else {
            $biosInfo = $shell->execCmd('cmd' => "$biosDecodeUtil -q", 'cmdsNeeded' => [$biosDecodeUtil]);
        } # if

        my $biosInfoText = $biosInfo->{'msg'};
        $biosInfoText .= "\n";
        
        # dividing subsystem output to items
        my @items = $biosInfoText =~ /^(\w+.*?)\n\n/gsm;

		# foreach subsystem item we parse decode output
        foreach $item(@items){

                my @itemProps = split('\n', $item);

                my $itemResult = {};
                push(@$result, $self->_parse(\@itemProps, $itemResult));

        } # foreach

        return $result;

} # end method get

=item C<_parse>

Method _parse, is parsing dmidecode output for each subsystems item

param:

	$item array ref - this is text from dmidecode for one item of subsystem
	
	$parentTree hash ref - this is hash which we will fill with item info
	
return:

	$parentTree hash ref - hash filled with info

=back
	
=cut

sub _parse() {

        my $self = shift;
        my $item = shift;
        my $parentTree = shift;
        my $parent = '';
        my $parentType = 'hash';

        my $previousParent;
        my $previousType = '';
        my $currentParent = $parentTree;

        foreach my $line(@$item){

	        if( $line =~ /^(\w+.*?[^:])$/ ) {
	                $parent = $1;
	                $parent =~ s/\s*//g;
	                $previousParent = $currentParent;
	                $currentParent->{$parent} = {};
	                $currentParent = $currentParent->{$parent};
	                $previousType = 'parent';
	        } elsif( $line =~ /(\w+.*?)(\:)$/ ) {
	
	                $parent = $1;
	
	                $parent =~ s/\s*//g;
	
	                $previousParent = $currentParent;
	                $currentParent->{$parent} = [];
	                $currentParent = $currentParent->{$parent};
	                $previousType = 'parent';
	        } else {
	        	
	                if( $line =~ /(\w+.*?)\:(.+)/ ) {
	                        $type = 'prop';
	                        $propName = $1;
	                        $propVal = $2;
	
	                        if($previousType eq 'attr') {
	                                $currentParent  = $previousParent;
	                        } # if
	
	                        $propName =~ s/\s*//g;
	                        $propVal =~ s/^\s+|\s+$//g;
	                        $currentParent->{$propName} = $propVal;
	                        $previousType = 'prop';
	                } elsif( $line =~ /\s+(\w+.*?[^:])/ ) {
	                        $type = 'attr';
	
	                        if($previousType eq 'prop') {
	                                $currentParent  = $previousParent;
	                        } # if
	
	                        push(@$currentParent, $1);
	                        $previousType = 'attr';
	                } # if
	
	        } # if
	        
        } # foreach

        return $parentTree;

}

=head1 DEPENDENCIES

	SysAdmToolkit::Patterns::Prototype

=head1 AUTHOR

	Pavol Ipoth 2014

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
