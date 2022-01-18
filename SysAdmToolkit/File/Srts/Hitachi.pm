package SysAdmToolkit::File::Srts::Hitachi;

=head1 NAME

	SysAdmToolkit::File::Srts::Hitachi - module for extracting data for hitachi from srts
	
=head1 SYNOPSIS

	my $hitachiEx = SysAdmToolkit::File::Srts::Hitachi->new();
	$hitachiEx->extract($srtsText);
	
=cut

use base qw/
				SysAdmToolkit::Patterns::Prototype
			/;

=head1 PRIVATE VARIABLES

=over 12

=item hitachi1Pattern string

Private variable hitachi1Pattern holds pattern for extracting just Hitachi srts items

=cut

my $hitachi1Pattern ='(?x)
                        \s*
                        (
                                (\d+)\s+              # frame number
                                (\d+\_\d+)\s+         # line item
                                ([a-zA-Z0-9\_\-]+)\s+ # server name
                                (\w+)\s+              # lunid
                                (CL\d+\-\w+)\s+       # array port
                                (\w+)\s+              # array PWWN
                                (\d+)\s+              # lun number
                                (\d+)                 # size
                                (G|T|P|M)             # unit
                        )
                     ';

=item hitachi2Pattern string

Private variable hitachi2Pattern holds pattern for transforming srts items to array of hash refs

=back

=cut
 
my $hitachi2Pattern = '(?x)
                                \s*(\d+)\s+                  # ticket num
                                (\d+\_\d+)\s+                # item num
                                (\d+)\s+                     # frame
                                [a-zA-Z]+\:\s+               # TYPE:
                                (\w+)\s+                     # storage type
                                ([a-zA-Z0-9\_\-]+)\s+        # server name
                                [a-zA-Z]+\:\s+               # DOM:
                                \d+\s+                       # some DOM number
                                [a-zA-Z]+\:\s+               # DEV:
                                \w+\:(\w+)\:(\w+)\s+         # lunid
                                [a-zA-Z]+\:\s+               # LUN:
                                (\d+)\s+                     # lun number
                                [a-zA-Z]+\:\s+               # PORT:
                                (\w+\-\w+)\s+                # port
                                [a-zA-Z]+\:\s+               # SIZE:
                                (\d+)                        # size
                      ';

=head1 METHODS

=over 12

=item C<extract>

Method extract gathers info from srts text and transforms to array of hashes

params:

	str string - srts text
	
return:

	array ref
	
=cut

sub extract() {
	
	my $self = shift;
	my $str = shift;
	my @hitachi = ();
	my @hitachi1 = ();
	my @hitachi2 = ();
	
	if(!$str) {
		die("You must supply string to parse!\n");	
	} # if
	
	while( $str =~ /$hitachi1Pattern/msg ){
		
	        my %props = (
	                        'server' => $4,
	                        'item' => $3,
	                        'size' => $9,
	                        'pwwn' => $7,
	                        'port' => $6,
	                        'lunid' => $5,
	                        'lunnum' => $8,
	                        'srts' =>  $2
	        );
	        
	        push(@hitachi1, \%props);
	        
	} # while
	
	while( $str =~ /$hitachi2Pattern/g ) {
		
	        my %props = (
	                'server' => $5,
	                'item' => $2,
	                'frame' => $3,
	                'lunid' => "$6$7",
	                'lunnum' => $8,
	                'srts' => $1,
                    'port' => $9,
	                'size' => $10
	        );
	        
	        push(@hitachi2, \%props);
	        
	} # while
	
	@hitachi = (@hitachi1, @hitachi2);
	
	return \@hitachi;
	
} # end sub extract

=head1 DEPENDECIES

	SysAdmToolkit::Patterns::Prototype

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;