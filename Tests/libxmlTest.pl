#!/usr/bin/perl -w

use lib 'SysAdmToolkit';

use SysAdmToolkit::File::Config::LibXml;
use Data::Dumper;

print "reading xml file...\n";
$config = SysAdmToolkit::File::Config::LibXml->new('xmlFile' => '/root/SysAdmToolkit/libconfig.xml');

print "One element test...\n";
my $el = $config->getElement('path' => '/libconfig/os[1]/osname', 'source' => $config->{'xml'});

print $config->getValue('path' => 'name', 'source' => $el) . "\n";

print "array values test...\n";

my $elver = $config->getElement('path' => '/libconfig/os[2]/osversion', 'source' => $config->{'xml'});

my $several = $config->getArray('path' => 'cmds', 'source' => $elver);

print Dumper($several);
print "\n";

print "Get several elements and then values...\n";

my $osEls = $config->getElements('path' => '/libconfig/os', 'source' => $config->{'xml'});

foreach my $node(@$osEls) {
        print $config->getValue('path' => 'osname/name', 'source' => $node) . "\n";
}

print "Saving file...\n";

$config->save('doc' => $config->{'xml'}, 'to' => '/tmp/xmlBackup.xml');