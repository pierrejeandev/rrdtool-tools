#!/usr/bin/perl
##############################################################################
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, write to the Free Software
## Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
##
## Copyrigth Pierre-Jean DEVILLE  2011-02-13
###############################################################################


use strict;
use warnings;

use File::Basename;
use Cwd 'abs_path';

# datadir = folder where this script is stored
my $datadir = dirname(abs_path(__FILE__));
my $webdir = '/var/www/rrd';
my $rrdFile = 'dataUptime.rrd';
my $scripttime = time;
#$sec, $min, $hour, $mday, $mon, $year
my ($sec, $min, $hour, $mday, $mon, $year) = localtime($scripttime);

$scripttime = int($scripttime / 60) * 60;

my $notDrawAll = 0;
$notDrawAll = 1 if (scalar(@ARGV) == 0);

# toutes les 5 minutes seulement
if (($min % 5)!=0 && $notDrawAll ) # 5 min
{
  exit;
  print "exit;\n";
}


$_ = `cat /proc/uptime` ;
my ($uptime, $idletime) = split(/\s+/);

# 4 cpu -> division par 4
$idletime = $idletime / 4;

# om compte l'uptime en jours
my $oneday = 24*60*60;
$uptime = $uptime / $oneday;
$idletime = $idletime / $oneday;

my $cmd = "rrdtool update $datadir/$rrdFile $scripttime:$uptime:$idletime ";
print $cmd."\n";
print `$cmd`;


#my $width = 480;
my $width = 700;
my $height = 200;
my $cmdp;

my $timestamp = sprintf("%4d-%02d-%02d %02d\\:%02d\\:%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);


$cmd = "rrdtool graph $webdir/imgname -a PNG --start starttime --end stoptime -w $width -h $height --lower-limit 0 ";
$cmd .= "DEF:uptime=$datadir/$rrdFile:uptime:AVERAGE DEF:idletime=$datadir/$rrdFile:idletime:AVERAGE ";

$cmd .= "CDEF:usedtime=uptime,idletime,- ";

$cmd .= "COMMENT:\"           Avg             Min              Max            Last\\n\" ";
$cmd .=   'GPRINT:uptime:AVERAGE:"        %6.2lf %sdays" GPRINT:uptime:MIN:"  %6.2lf %Sdays" ';
$cmd .=   'GPRINT:uptime:MAX:"  %6.2lf %Sdays" GPRINT:uptime:LAST:"  %6.2lf %Sdays     " ';
$cmd .= "AREA:uptime#C00000:\"uptime\" COMMENT:\"\\n\" ";
$cmd .= 'GPRINT:usedtime:AVERAGE:"        %6.2lf %sdays" GPRINT:usedtime:MIN:"  %6.2lf %Sdays" ';
$cmd .= 'GPRINT:usedtime:MAX:"  %6.2lf %Sdays" GPRINT:usedtime:LAST:"  %6.2lf %Sdays     " ';
$cmd .= "AREA:usedtime#0173FF:\"usedtime\" COMMENT:\"\\n\" ";
$cmd .= "COMMENT:\"          ----------------------------   $timestamp   -----------------------\\n\" ";


$scripttime = 60 * int( ($scripttime + 5) / 60); # arrondi à la minute

my $stoptime = $scripttime;
my $imgBaseName = "uptime";
my $imgname = $imgBaseName.'-2day.png';
my $starttime = $stoptime - ($width - 1) * 300; # 1px / 5 min ; 480x5 min = 40h
$cmdp = $cmd;
$cmdp =~ s/starttime/$starttime/;
$cmdp =~ s/stoptime/$stoptime/;
$cmdp =~ s/imgname/$imgname/;
print `$cmdp`;

if (($min % 30)!=0 && $notDrawAll) # 30 min
{
  exit;
}

$imgname = $imgBaseName.'-week.png';
$starttime = $stoptime - ($width - 1) * 1800; # 1px / 30 min ; 480x30 min = 240h = 10 jours
$cmdp = $cmd;
$cmdp =~ s/starttime/$starttime/;
$cmdp =~ s/stoptime/$stoptime/;
$cmdp =~ s/imgname/$imgname/;
print `$cmdp`;

if ( (($hour % 2)!=0 || $min!=0) && $notDrawAll ) # 2 heures
{
  exit;
}

$imgname = $imgBaseName.'-month.png';
$starttime = $stoptime - ($width - 1) * 7200; # 1px / 2h ; 480x2h = 40 jours
$cmdp = $cmd;
$cmdp =~ s/starttime/$starttime/;
$cmdp =~ s/stoptime/$stoptime/;
$cmdp =~ s/imgname/$imgname/;
print `$cmdp`;

if ($hour!=0 && $notDrawAll) # 1 jour
{
  exit;
}

$imgname = $imgBaseName.'-year.png';
$starttime = $stoptime - ($width - 1) * 86400; # 1px / 1 jour ; 480 jours = 1.3 ans
$cmdp = $cmd;
$cmdp =~ s/starttime/$starttime/;
$cmdp =~ s/stoptime/$stoptime/;
$cmdp =~ s/imgname/$imgname/;
print `$cmdp`;


