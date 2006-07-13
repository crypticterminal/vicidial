#!/usr/bin/perl
#
# AST_CRON_mix_recordings_GSM.pl
# runs every 5 minutes and mixes the call recordings in the monitor together
# and puts the resulting ALL file into the DONE directory in the "monitor" dir
# and converts the ALL file to GSM format to save space.
# 
# soxmix is REQUIRED to use this script, soxmix is available only as part of 
# the sox audio package, and only in newer versions. Make sure you have soxmix
# installed properly and in your path
# 
# put an entry into the cron of of your asterisk machine to run this script 
# every 5 minutes or however often you desire
#
# make sure that the following directories exist:
# /var/spool/asterisk/monitor		# default Asterisk recording directory
# /var/spool/asterisk/monitor/DONE	# where the combined files are put
# /var/spool/asterisk/monitor/ORIG	# where the original in/out files are put
# 
# This program assumes that recordings are saved as .wav
# should be easy to change this code if you use .gsm instead
# 
# This program also sends the ALL combined file to an FTP server for archival
# purposes, you can comment out the Net::Ping and Net::FTP lines as well as the
# file transfer section of the code to deactivate remote copying of the
# recording files
#
# Copyright (C) 2006  Matt Florell <vicidial@gmail.com>    LICENSE: GPLv2
#
# 
# 51021-1058 Added quotes around CLI executed commands
# 51122-1455 Added soxmix and sox binary path check
# 


#$v=1;

# Customize variables for FTP
$FTP_host = '10.0.0.4';
$FTP_user = 'cron';
$FTP_pass = 'test';
$FTP_dir  = 'RECORDINGS';
$FTP_port = '21';

### directory where in/out recordings are saved to by Asterisk
$dir1 = '/var/spool/asterisk/monitor';

$soxmixbin = '';
if ( -e ('/usr/bin/soxmix')) {$soxmixbin = '/usr/bin/soxmix';}
else 
	{
	if ( -e ('/usr/local/bin/soxmix')) {$soxmixbin = '/usr/local/bin/soxmix';}
	else
		{
		print "Can't find soxmix binary! Exiting...\n";
		exit;
		}
	}
$soxbin = '';
if ( -e ('/usr/bin/sox')) {$soxbin = '/usr/bin/sox';}
else 
	{
	if ( -e ('/usr/local/bin/sox')) {$soxbin = '/usr/local/bin/sox';}
	else
		{
		print "Can't find sox binary! Exiting...\n";
		exit;
		}
	}

use Net::Ping;
use Net::FTP;


 opendir(FILE, "$dir1/");
 @FILES = readdir(FILE);

$i=0;
foreach(@FILES)
   {
	$size1 = 0;
	$size2 = 0;

	if ( (length($FILES[$i]) > 4) && (!-d $FILES[$i]) )
		{

		$size1 = (-s "$dir1/$FILES[$i]");
		if ($v) {print "$FILES[$i] $size1\n";}
		sleep(1);
		$size2 = (-s "$dir1/$FILES[$i]");
		if ($v) {print "$FILES[$i] $size2\n\n";}


		if ( ($FILES[$i] !~ /out\.wav/i) && ($size1 eq $size2) && (length($FILES[$i]) > 4))
			{
			$INfile = $FILES[$i];
			$OUTfile = $FILES[$i];
			$OUTfile =~ s/-in\.wav/-out.wav/gi;
			$ALLfile = $FILES[$i];
			$ALLfile =~ s/-in\.wav/-all.wav/gi;
			$GSMfile = $ALLfile;
			$GSMfile =~ s/-all\.wav/-all.gsm/gi;

		if ($v) {print "|$INfile|    |$OUTfile|     |$ALLfile|\n\n";}

			`$soxmixbin "$dir1/$INfile" "$dir1/$OUTfile" "$dir1/$ALLfile"`;
		if ($v) {print "|$INfile|    |$OUTfile|     |$ALLfile|\n\n";}
			if (!$T)
				{
				`mv -f "$dir1/$INfile" "$dir1/ORIG/$INfile"`;
				`mv -f "$dir1/$OUTfile" "$dir1/ORIG/$OUTfile"`;
				`mv -f "$dir1/$ALLfile" "$dir1/DONE/$ALLfile"`;
				}
			else
				{
				`cp -f "$dir1/$ALLfile" "$dir1/DONE/$ALLfile"`;
				}

			`$soxbin "$dir1/DONE/$ALLfile" "$dir1/DONE/$GSMfile"`;

			if (!$T)
				{
				`rm -f "$dir1/DONE/$ALLfile"`;
				}

			if($DB){print STDERR "\n|/usr/bin/sox $live_folder/$filename[$k]$WAV $arch_folder/$filename[$k]$GSM|\n";}
		chmod 0755, "$dir1/DONE/$GSMfile";

	### BEGIN Remote file transfer
	#		$p = Net::Ping->new();
	#		$ping_good = $p->ping("$FTP_host");

	#		if ($ping_good)
	#			{
				$ftp = Net::FTP->new("$FTP_host", Port => $FTP_port, Debug => 0,  Passive => 1);
				$ftp->login("$FTP_user","$FTP_pass");
				$ftp->cwd("$FTP_dir");
				$ftp->binary();
				$ftp->put("$dir1/DONE/$GSMfile", "$GSMfile");
				$ftp->quit;
	#			}
	### END Remote file transfer

			}
		}
	$i++;
	}

if ($v) {print "DONE... EXITING\n\n";}

exit;