use strict;

my $ssacli="C:\\Program Files\\Smart Storage Administrator\\ssacli\\bin\\ssacli.exe";

sub ssacli {

	my $command = $_[0];
	my $data = `"$ssacli" $command`;
	return $data;

}

sub ssacli_open {

	my $command= $_[0];
	my $fh;
	open($fh,'"' . $ssacli . '"' . " $command|");
	return $fh;

}

sub get_controllers {

	my $data = ssacli("ctrl all show detail");
	my ($ctrl, $slot, $c, $controllers, $status, $bbu_status, $cache_status, $write_cache_status);

	foreach $_ ( split("/\n/",	$data) ) {
		if($_ =~ / in Slot /) { 
			# delete values when a new controller block starts
			$ctrl=$slot=$status=$bbu_status=$cache_status=$write_cache_status=undef;
		}
		($ctrl, $slot) 		= /(.*) in Slot ([0-9]+)/;
		($status) 		= /Controller Status: (.*)/;
		($bbu_status) 		= /Battery\/Capacitor Status: (.*)/;
		($cache_status)		= /Cache Status: (.*)/;
		($write_cache_status)	= /Drive Write Cache: (.*)/;

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
		}
	}
	return $controllers;

}

sub get_ctrl_disks {

	my $ctrl_slot = $_[0];
	my $fh = ssacli_open("ctrl slot=$ctrl_slot pd all show detail");

	my ($location, $all_disks, $disk, $size, $serial, $temp, $array, $interface, $status);

	while ($_=<$fh> ) {
		if($_ =~ /physicaldrive (.*)/) { 
			$location=$1;
			# delete values when a new controller block starts
			$disk=$size=$serial=$temp=$interface=undef;
		}
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

	my ($status, $summary, $bbu_error, $ctrl_error, $cache_error, $write_cache_error);
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
					."controller_status: ".$c->{"status"}.($ctrl_error==1?"(!!)":"").", "
					."cache_status: ".$c->{"cache_status"}.($cache_error==1?"(!!)":"").", "
					."write_cache_status: ".$c->{"write_cache_status"}.($write_cache_error==1?"(!!)":"").", "
					."bbu_status: ".$c->{"bbu_status"}.($bbu_error==1?"(!!)":"")." ";
			print "$status HP_RAID_Slot_".$c->{"slot"}." - $summary\n";
			
		}
}

sub output_check_mk_disk_lines {

	my $disks = $_[0]; 
	my ($status);

	foreach my $d ( @$disks ) {

		$status = 0;
		$status = 1 if ($d->{"status"} !~ /OK/i);
		print "$status hdd_".$d->{"location"}
			." Temperature=".$d->{"temp"}." Hard disk on HP RAID Controller. "
			." Type: ".$d->{"interface"}.","
			." Size: ".$d->{"size"}.","
			." Is-Part-of-Array: ".$d->{"array"}.","
			." Serial: ".$d->{"serial"}.","
			." Controller-Port: ".$d->{"location"}
			."\n";		
	}
}
my $controllers = get_controllers();
my $disks	= get_all_disks($controllers);

output_check_mk_controller_lines($controllers);
output_check_mk_disk_lines($disks);
