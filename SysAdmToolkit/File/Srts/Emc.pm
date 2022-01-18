package SysAdmToolkit::File::Srts::Emc;

=head1 NAME

	SysAdmToolkit::File::Srts::Emc - module for extracting data for emc from srts
	
=head1 SYNOPSIS

	my $emcEx = SysAdmToolkit::File::Srts::Emc->new();
	$emcEx->extract($srtsText);
	
=cut

use base qw/
				SysAdmToolkit::Patterns::Prototype
			/;

=head1 PRIVATE VARIABLES

=over 12

=item emcPattern string

Private variable emcPattern holds pattern for extracting just EMC entries

=cut

my $emcPattern = '(?x)
                    \s*
                    (
	                    \#{5}\s+[a-zA-Z0-9\_\-]+\s+                               # server name
	                    \d+\_\d+\s+                                                  # item num
	                    \(\s+\w+\s+\w+\:\s+\d+\s+(?:G|T|P|M)\)                         # size
	                    \s*\n                                                          # empty line
	                    \s*\w+\s+\w+\s+[a-zA-Z\#]+\s+\w+\s+[a-zA-Z\#]+\s+[a-zA-Z\#]+\s+\w+ # header
	                    (?:
	                        \s*\d+\s+                                                  # frame
	                        \s*\w+\s+                                                  # port
	                        \s*\w+\s+                                                  # lunid
	                        \s*\-\s+                                                   # target
	                        \s*\d+\s+                                                  # lun num
	                        \s*\d+\s+                                                  # srts num
	                        \s*\d+\_\d+                                                # line item
	                    )+
                	)
                ';


=item emcHead string

Private property emcHead stores pattern for extracting server, item number and size

=cut
                
my $emcHead = '(?x)
                    \s*\#{5}\s+([a-zA-Z0-9\_\-]+)\s+                               # server name
                    (\d+\_\d+)\s+                                                  # item num
                    \(\s+\w+\s+\w+\:\s+(\d+)\s+(G|T|P|M)\)                         # size
                ';
 
=item emcBody string

Private property emcBody stores paters for extracting lun items for each srts item

=back

=cut
               
my $emcBody = '(?x)
					(
                        \s*(\d+)\s+                                                  # frame
                        \s*(\w+)\s+                                                  # port
                        \s*(\w+)\s+                                                  # lunid
                        \s*(\-)\s+                                                   # target
                        \s*(\d+)\s+                                                  # lun num
                        \s*(\d+)\s+                                                  # srts num
                        \s*(\d+\_\d+)                                                # line item
                	)
                ';

=head1 METHODS

=over 12

=item C<extract>

Method extract gathers info from srts text and transforms to array of hashes

params:

	str string - srts text
	
return:

	array ref

=back

=cut
             
sub extract() {
	
	my $self = shift;
	my $str = shift;
	my @emc = ();
	
	if(!$str) {
		die("You must supply string to parse!\n");	
	} # if
	
	my @items = ( $str =~ /$emcPattern/msg );
	
	for my $item(@items) {
		
		$item =~ /$emcHead/;
		
		my $serverName = $1;
		my $size = $3;
		
		while($item =~ /$emcBody/msg) {
			
			my %record = (
				'frame' => $2,
				'port' => $3,
				'lunid' => $4,
				'lunnum' => 6,
				'srts' => $7,
				'item' => $8,
				'size' => $size,
				'server' => $serverName
			);
			
			push(@emc, \%record);
			
		} # while
		
	} # for
	
	return \@emc;
	
} # end sub extract

=head1 DEPENDECIES

	SysAdmToolkit::Patterns::Prototype

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;