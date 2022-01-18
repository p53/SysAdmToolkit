package SysAdmToolkit::File::SrtsAsm::Emc;

=head1 NAME

	SysAdmToolkit::File::SrtsAsm::Emc - module for extracting data for emc from asm srts
	
=head1 SYNOPSIS

	my $emcEx = SysAdmToolkit::File::SrtsAsm::Emc->new();
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
	                    \#{5}\s+[a-zA-Z0-9\_\-\:]+\s+                               # server name
	                    \d+\_\d+\s+                                                  # item num
	                    \(\s+\w+\s+\w+\:\s+\d+\s+(?:G|T|P|M)\)                         # size
	                    (\s*\n*)+                                                          # empty line
	                    \s*\w+\s+\w+\s+[a-zA-Z\#]+\s+[a-zA-Z\#]+\s+[a-zA-Z\#]+\s+\w+ # header
	                    (?:
	                        \s*\d+\s+                                                  # frame
	                        \s*\w+\s+                                                  # port
	                        \s*\w+\s+                                                  # lunid
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
                    \s*\#{5}\s+([a-zA-Z0-9\_\-\:]+)\s+                               # server name
                    (\d+\_\d+)\s+                                                  # item num
                    \(\s+\w+\s+\w+\:\s+(\d+)\s+(G|T|P|M)\)                         # size
                ';

=item emcBody string

Private property emcBody stores paters for extracting lun items for each srts item

=cut
                
my $emcBody = '(?x)
					(
                        \s*(\d+)\s+                                                  # frame
                        \s*(\w+)\s+                                                  # port
                        \s*(\w+)\s+                                                  # lunid
                        \s*(\d+)\s+                                                  # lun num
                        \s*(\d+)\s+                                                  # srts num
                        \s*(\d+\_\d+)                                                # line item
                	)
                ';

=item serversPatt string

Private property serversPatt stores patern for matching servers in header of srts item

=cut

my $serversPatt = '(?<!\_)([a-zA-Z0-9\-]+)\_*.*?+';   
     
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
		
		my @serverNames = ( $serverName =~ /$serversPatt/g);
		
		while($item =~ /$emcBody/msg) {
			
			my %record = (
				'frame' => $2,
				'port' => $3,
				'lunid' => $4,
				'lunnum' => $5,
				'srts' => $6,
				'item' => $7,
				'size' => $size,
				'server' => \@serverNames
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