package SysAdmToolkit::Lvm::Splitter;

=head1 NAME

SysAdmToolkit::Lvm::Splitter - module which splits and merges passed filesystems lvols

=head1 SYNOPSIS

	my $splitter = SysAdmToolkit::Lvm::Splitter->new();

	$splitter->split('filesystems' => ['/var', '/tmp'], 'os' => 'HPUX', 'ver' => '1131');

=head1 DESCRIPTION

Module splits or merges lvols of specified filesystems

=cut

use base 'SysAdmToolkit::Monitor::Subject';

use SysAdmToolkit::Term::Shell;
use SysAdmToolkit::Storage::Filesystem;
use SysAdmToolkit::Lvm::LogicalVolume;

=head1 METHODS

=over 12

=item C<split>

Method split splits logical volume of specified filesystems if it is mirrored

params:

	filesystems array ref

	os string

	ver string

=cut

sub split($$$) {
	
	my $self = shift;
	my %params = @_;
	my $filesystems = $params{'filesystems'};
	my $os = $params{'os'};
	my $osVersion = $params{'ver'};
	
	# for each filesystems we get it's volume, split suffix, than we make sure
	# lvol is mirrored, if it is we are splitting lvol and then fsck filesystem on splited lvol
	foreach my $fs(@$filesystems) {
		
		my $patchedFilesys = SysAdmToolkit::Storage::Filesystem->new('fs' => $fs);
		my $patchedVolName = $patchedFilesys->get('volume');
		my $patchedVol = SysAdmToolkit::Lvm::LogicalVolume->new('lv' => $patchedVolName, 'os' => $os, 'ver' => $osVersion);
		my $splitSuffix = $patchedVol->get('splitsuffix');
		my $splitedVolName = $patchedVolName . $splitSuffix;
		
		my $mirrorStat = $patchedVol->isMirrored();
		
		$self->runMonitor('message' => "Checking if Logical Volume $patchedVolName is mirrored...", 'severity' => 2, 'subsystem' => __PACKAGE__, 'status' => $mirrorStat);
		
		if($mirrorStat) {
			
			$self->runMonitor('message' => "Starting spliting $patchedVolName, new Lvol will be $splitedVolName...", 'severity' => 2, 'subsystem' => __PACKAGE__, 'status' => 1, 'statusOff' => 1);
			
			my $splitStatus = $patchedVol->splitLvol();
			
			$self->runMonitor('message' => "Splitting of $patchedVolName...", 'severity' => 2, 'subsystem' => __PACKAGE__, 'status' => $splitStatus);
		
			if(!$splitStatus) {
				die("Splitting of $patchedVolName unsuccessfull! Aborting!");
			} # if
			
			sleep 3;
			
			$self->runMonitor('message' => "Checking fileystem consistency of new Lvol $splitedVolName...", 'severity' => 2, 'subsystem' => __PACKAGE__, 'status' => 1, 'statusOff' => 1);
			
			my $fsckStatus = $patchedFilesys->fsck($splitedVolName);
			
			$self->runMonitor('message' => "Filesystem check on Lvol $splitedVolName...", 'severity' => 2, 'subsystem' => __PACKAGE__, 'status' => $fsckStatus);
			
			if(!$fsckStatus) {
				die("Filesystem check of $splitedVolName unsuccessfull! Aborting!");
			} # if
			
		} else {
			die "Logical Volume $patchedVolName is not mirrored! Aborting!";
		} # if
			
	} # foreach
	
} # end sub split

=item C<merge>

Method merge merges lvol of specified filesystems with lvol + suffix

params:

	filesystems array ref

	os string

	ver string

=back

=cut

sub merge($$$) {
	
	my $self = shift;
	my %params = @_;
	my $filesystems = $params{'filesystems'};
	my $os = $params{'os'};
	my $osVersion = $params{'ver'};
	
	# for each filesystem we get it's volume, split suffix, we check if lvol with filesystem's lvol + suffix
	# exists if yes we merge it to filesystem's lvol and lvsync lvol
	foreach my $fs(@$filesystems) {
			
		my $patchedFilesys = SysAdmToolkit::Storage::Filesystem->new('fs' => $fs);
		my $patchedVolName = $patchedFilesys->get('volume');
		my $patchedVol = SysAdmToolkit::Lvm::LogicalVolume->new('lv' => $patchedVolName, 'os' => $os, 'ver' => $osVersion);
		my $splitSuffix = $patchedVol->get('splitsuffix');
		my $splitedVolName = $patchedVolName . $splitSuffix;
		
		my $splitedVolExists = $patchedVol->lvExists($splitedVolName);
		
		$self->runMonitor('message' => "Logical Volume $splitedVolName existence...", 'severity' => 2, 'subsystem' => __PACKAGE__, 'status' => $splitedVolExists);
		
		if($splitedVolExists) {
			
			$self->runMonitor('message' => "Starting merging $splitedVolName to $patchedVolName...", 'severity' => 2, 'subsystem' => __PACKAGE__, 'status' => 1, 'statusOff' => 1);
			
			my $mergeStatus = $patchedVol->mergeLvol($splitedVolName);
			
			$self->runMonitor('message' => "Merging of $splitedVolName to $patchedVolName...", 'severity' => 2, 'subsystem' => __PACKAGE__, 'status' => $mergeStatus);
		
			if(!$mergeStatus) {
				die("Merging of $splitedVolName to $patchedVolName unsuccessfull! Aborting!");
			} # if
			
			$self->runMonitor('message' => "Syncing Lvol $patchedVolName...", 'severity' => 2, 'subsystem' => __PACKAGE__, 'status' => 1, 'statusOff' => 1);
			
			my $lvSyncStatus = $patchedVol->lvsync();
			
			$self->runMonitor('message' => "Syncing of Lvol $patchedVolName...", 'severity' => 2, 'subsystem' => __PACKAGE__, 'status' => $lvSyncStatus);
			
			if(!$lvSyncStatus) {
				die("Syncing of $patchedVolName unsuccessfull! Aborting!");
			} # if
			
		} else {
			die "Splited Logical Volume $splitedVolName doesn't exist! Aborting!";
		} # if
			
	} # foreach
	
} # end sub merge

=head1 DEPENDECIES

	SysAdmToolkit::Monitor::Subject
	SysAdmToolkit::Term::Shell
	SysAdmToolkit::Storage::Filesystem
	SysAdmToolkit::Lvm::LogicalVolume

=head1 AUTHOR

	Pavol Ipoth 2013

=head1 COPYRIGHT

	2013 GPLv2

=cut

1;
