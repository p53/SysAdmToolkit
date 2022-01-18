package SysAdmToolkit::File::Srts::Eva;

=head1 NAME

	SysAdmToolkit::File::Srts::Eva - module for extracting data for eva from srts
	
=head1 SYNOPSIS

	my $evaEx = SysAdmToolkit::File::Srts::Eva->new();
	$evaEx->extract($srtsText);
	
=cut

use base qw/
				SysAdmToolkit::Patterns::Prototype
			/;

=head1 PRIVATE VARIABLES

=over 12

=item evaPattern string

Private variable vaPattern holds pattern for extracting just Eva entries

=back

=cut

my $evaPattern = '(?x)
                        \s*
                        \w+\:\s+\d+\_\d+                  							# line item
                        \s*\w+\s+\w+\:\s+[a-zA-Z0-9\-]+   							# frame
                        \s*\w+\:\s+[a-zA-Z0-9\_\-]+    								# server nam
                        (?:
                                \s*\w+\:\s+\\\ \w+\s+\w+\\\ [a-zA-Z0-9\-]+\\\ \w+ 	# vdisk
                                \s*\w+\:\s+\:\s+\d+       							# lun number
                                \s*(?:\w+\-){7}\w+                  				# lunid
                                \s*\n
                        )+
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
    my $eva = [];

	if(!$str) {
		die("You must supply string to parse!\n");	
	} # if
	
    my @evaItems = ();

    my @evaItems = ( $str =~ /$evaPattern/msg );

    my $itemNum = @evaItems;

    if( $itemNum > 0 ) {
            my $itemStr = join("", @evaItems);
            $eva = $self->parse($itemStr);
    } # if

    return $eva;

} # end sub extract

=item C<parse>

Method parse parses each srts items extracted to array of hash refs

params:

	linesStr string - srts items
	
return:

	array ref
	
=back

=cut

sub parse() {
	
	my $self = shift;
	my $linesStr = shift;
    my @lines = ();
    my @records = ();

    my @srtsItems = split(/\s*Line:\s/m, $linesStr);

    for my $item(@srtsItems) {

            @srtsItemsLines = split("\n", $item);

            my $itemNum = shift @srtsItemsLines;
            my $itemFrame = shift @srtsItemsLines;
            my $itemHost = shift @srtsItemsLines;

            $itemNum =~ s/\s+//g;
            $itemFrame =~ s/\s*Storage Frame:\s*([a-zA-Z0-9\-]+)/$1/;
            $itemHost =~ s/\s*Host\:\s*([a-zA-Z0-9\_]+)/$1/;

            my $itemLunsStr = join("\n", @srtsItemsLines);

            my @srtsItemLuns = split(/^\s*$/m, $itemLunsStr);

            for my $itemLun(@srtsItemLuns) {
            	
            	    my %props = ();
                    my @lunInfo = split("\n", $itemLun);
                    my @clearLunInfo = grep { $_ !~ /^\s*$/} @lunInfo;
                    
                    my $lunId = pop(@clearLunInfo);
                    $lunId =~ s/\s+//;
                    $clearLunInfo[0] =~ s/\s*Vdisk\:\s*([a-zA-Z0-9\\\s]+)/$1/;
                    $clearLunInfo[1] =~ s/\s*LUN\:\s*\:\s*(\d+)/$1/;
                    
                    $props{'lunid'} = $lunId;
                    $props{'item'} = $itemNum;
                    $props{'frame'} = $itemFrame;
                    $props{'server'} = $itemHost;
                    $props{'vdisk'} = $clearLunInfo[0];
                    $props{'lunnum'} = $clearLunInfo[1];
                    
                    push(@records, \%props);
                    
            } # for

    } # for

	return \@records;
	
} # end sub parse

=head1 DEPENDECIES

	SysAdmToolkit::Patterns::Prototype

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;