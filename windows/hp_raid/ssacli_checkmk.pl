
#
#	program:	ssacli_checkmk.pl
#
#	purpose:	local check for checkmk on windows to monitor raid controller
#			which can be checked with ssacli.exe
#
#

use strict;

use constant LOG_ENABLED => 1;

my  $basedir="C:\\Program Files (x86)\\monitoring";
my  $bindir="$basedir\\bin";
my  $datadir="$basedir\\data";
my  $ssacli="$bindir\\ssacli.exe";
my  $outputfile="$datadir\\ssacli.txt";
my  $logfile="$datadir\\main.log";

sub ssacli_open {

	my $command= $_[0];
	my $fh;
	if(! -f "$ssacli") {
		mylog("Error: program $ssacli does not exit");
		return;
	}
	open($fh,'"' . $ssacli . '"' . " $command|");
	return $fh;

}

sub get_controllers {

	my $fh = ssacli_open("ctrl all show detail");
	return unless($fh);

	my ($ctrl, $slot, $c, $controllers, $status, $bbu_status, $cache_status, $write_cache_status);

	while(<$fh>) {
		if(/(.*) in Slot ([0-9]+)/) { 
			($ctrl, $slot) 		= ($1, $2);
		}
		($status) 		= $1 		if(/Controller Status: (.*)/);
		($bbu_status) 		= $1		if(/Battery\/Capacitor Status: (.*)/);
		($cache_status)		= $1		if(/Cache Status: (.*)/);
		($write_cache_status)	= $1		if(/Drive Write Cache: (.*)/);

 		if($ctrl && $slot ne "" && $status && $bbu_status && $cache_status && $write_cache_status) {

			$c = { 
				"controller" 		=> $ctrl, 
				"slot" 			=> $slot, 
				"status" 		=> $status, 
				"bbu_status" 		=> $bbu_status,
				"cache_status"		=> $cache_status,
				"write_cache_status" 	=> $write_cache_status
			};
			push @$controllers, $c;	
			$ctrl=$slot=$status=$bbu_status=$cache_status=$write_cache_status=undef;
		}
	}
	close($fh);
	return $controllers;

}

sub get_ctrl_disks {

	my $ctrl_slot = $_[0];
	my $fh = ssacli_open("ctrl slot=$ctrl_slot pd all show detail");
	return unless($fh);

	my ($location, $all_disks, $disk, $size, $serial, $temp, $array, $interface, $status);

	while (<$fh>) {

		$location=$1 if /physicaldrive (.*)/;
		$array 	= $1 if /Array (.*)/;
		$status = $1 if /[ \t]+Status: (.*)/;
		$size 	= $1 if /^[ \t]+Size: (.*)/;
		$serial	= $1 if /[ \t]+Serial Number: (.*)/;
		$temp	= $1 if /[ \t]+Current Temperature ...: (.*)/;
		$interface = $1 if /[ \t]+Interface Type: (.*)/;

		if($status && $size && $serial && $temp && $interface && $array)   {
			$disk = { 
				"array"		=> $array,
				"location"	=> $location,
				"status"	=> $status,
				"size"		=> $size,
				"serial"	=> $serial,
				"temp"		=> $temp,
				"interface"	=> $interface
			};
			push @$all_disks, $disk;
			$disk=$size=$serial=$temp=$interface=undef;
		}

	}
	close($fh);
	return $all_disks;
}

sub get_all_disks {

	my $controllers = $_[0];
	my ($ctrl_disks, $disks, $all_disks);
	foreach my $ctrl (@$controllers) {
		$ctrl_disks = get_ctrl_disks($ctrl->{"slot"});
		push @$all_disks,@$ctrl_disks;
	}
	return $all_disks;
}

sub output_check_mk_controller_lines {

	my ($status, $summary, $bbu_error, $ctrl_error, $cache_error, $write_cache_error, $output);
	$output="";
	my $controllers = $_[0];
	foreach my $c (@$controllers) {
		$status=$cache_error=$write_cache_error=$bbu_error=$ctrl_error=0;
		$cache_error=1	if ( 		$c->{"cache_status"} 		=~ /Disabled/i );
		$write_cache_error=1	if ( 	$c->{"write_cache_status"} 	=~ /Disabled/i );
		$bbu_error=1	if (		$c->{"bbu_status"} 		=~ /Failed/i   );
		$ctrl_error=1	if (		$c->{"status"}			!~ /OK/i      );
		if( $ctrl_error or $bbu_error or $cache_error or $write_cache_error ) {
			$status = 1;
		}
		$summary=	 $c->{"controller"}." "
				."controller_status: ".$c->{"status"}.", "
				."cache_status: ".$c->{"cache_status"}.", "
				."write_cache_status: ".$c->{"write_cache_status"}.", "
				."bbu_status: ".$c->{"bbu_status"};
		$output .= "$status HP_RAID-Controller_Slot_".$c->{"slot"}." - $summary\n";			
	}
	return $output;	
}

sub output_check_mk_disk_lines {

	my $disks = $_[0]; 
	my ($status);
	my $output="";

	foreach my $d ( @$disks ) {

		$status = 0;
		$status = 1 if ($d->{"status"} !~ /OK/i);
		$output .= "$status hdd_".$d->{"location"}
			." Temperature=".$d->{"temp"}." Hard disk on HP RAID Controller. "
			." Status: ".$d->{"status"}.","
			." Type: ".$d->{"interface"}.","
			." Size: ".$d->{"size"}.","
			." Is-Part-of-Array: ".$d->{"array"}.","
			." Serial: ".$d->{"serial"}.","
			." Controller-Port: ".$d->{"location"}
			."\n";		
	}
	return $output;
}

sub mylog {
	my ($text) = @_;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
                                                            localtime(time);
	my ($loghandle);

	# inefficent logging to open and close for every write. but it's only for debugging

	if(LOG_ENABLED) {
		open($loghandle,">>$logfile");
		printf("%4d-%02d-%02d %02d:%02d:%02d %s\n",1900+$year,$mon+1,$mday,$hour,$min,$sec,$text);
		printf $loghandle "%4d-%02d-%02d %02d:%02d:%02d %s\n",1900+$year,$mon+1,$mday,$hour,$min,$sec,$text;
		close($loghandle);
	}
}

sub write_file_atomic {

	my ($filename,$data) = @_;
	my ($fh);
	if(open($fh,">","$filename.tmp")) {
		print $fh $data;
		close($fh);
		rename("$filename.tmp","$filename") or mylog("can not rename file $filename.tmp to $filename: $!\n");
	} else {
	 	mylog("can not write to file $filename: $!\n")
	}
}

sub main {

	my ($controllers, $disks, $data);

	while(1) {
		$controllers 	= get_controllers();
		$disks		= get_all_disks($controllers);
		$data 		= "";

		$data	 	.= output_check_mk_controller_lines($controllers);
		$data	 	.= output_check_mk_disk_lines($disks);
		write_file_atomic($outputfile,$data);
		sleep(60);
	}

}

main
