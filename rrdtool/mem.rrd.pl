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
my $rrdFile = 'dataMem.rrd';
my $scripttime = time;


my $kernelversion = `uname -r`;
my ($memtotal, $memused, $memfree, $memshared, $membuffer, $memcached);
my ($swptotal, $swpused, $swpfree);

if ($kernelversion =~m/^2\.4\..*/)
{
  (undef, $memtotal, $memused, $memfree, $memshared, $membuffer, $memcached) = split(/\s+/, `grep Mem: /proc/meminfo`);
  (undef, $swptotal, $swpused, $swpfree) = split(/\s+/, `grep Swap: /proc/meminfo`);
}
elsif ($kernelversion =~m/^2\.6\..*/ || $kernelversion =~m/^3\..*/)
{
  (undef, $memtotal, $memused, $memfree, $memshared, $membuffer, $memcached) = split(/\s+/, `free | grep Mem:`);
  (undef, $swptotal, $swpused, $swpfree) = split(/\s+/, `free | grep Swap:`);
}
elsif ($kernelversion =~m/^2\.6\..*/ || $kernelversion =~m/^4\..*/)
{
  (undef, $memtotal, $memused, $memfree, $memshared, $memcached, undef) = split(/\s+/, `free | grep Mem:`);
  (undef, $swptotal, $swpused, $swpfree) = split(/\s+/, `free | grep Swap:`);
  $membuffer = 0
}
else
{
  print "Unsuported kervel version. Supported version are 2.4 and 2.6\n";
  exit;
}

print "mem $memtotal, $memused, $memfree, $memshared, $membuffer, $memcached\n";
print "swp $swptotal, $swpused, $swpfree\n";

# memTot:memFree:memBuf:memCache:swpTot:swpFree
my $cmd = "rrdtool update $datadir/$rrdFile $scripttime:$memtotal:$memfree:$membuffer:$memcached:$swptotal:$swpfree \n";
print `$cmd`;


#my $width = 480;
my $width = 700;
my $height = 200;
my $cmdp;

#$sec, $min, $hour, $mday, $mon, $year
my ($sec, $min, $hour, $mday, $mon, $year) = localtime($scripttime);
my $timestamp = sprintf('%4d-%02d-%02d %02d\:%02d\:%02d', $year+1900, $mon+1, $mday, $hour, $min, $sec);


$cmd = "rrdtool graph $webdir/imgname -a PNG --start starttime --end stoptime -w $width -h $height ";
$cmd .= "DEF:memTotB=$datadir/$rrdFile:memTot:AVERAGE DEF:memFreeB=$datadir/$rrdFile:memFree:AVERAGE ";
$cmd .= "DEF:memBufB=$datadir/$rrdFile:memBuf:AVERAGE DEF:memCacheB=$datadir/$rrdFile:memCache:AVERAGE ";
$cmd .= "DEF:inswpTotB=$datadir/$rrdFile:swpTot:AVERAGE DEF:inswpFreeB=$datadir/$rrdFile:swpFree:AVERAGE ";

$cmd .= "CDEF:memTot=1024,memTotB,* CDEF:memFree=1024,memFreeB,* CDEF:memBuf=1024,memBufB,* ";
$cmd .= "CDEF:memCache=1024,memCacheB,* CDEF:inswpTot=1024,inswpTotB,* CDEF:inswpFree=1024,inswpFreeB,* ";

$cmd .= "CDEF:inswpUsed=inswpTot,inswpFree,- CDEF:swpFree=0,inswpFree,- CDEF:swpUsed=0,inswpUsed,- ";
#$cmd .= "CDEF:swpTot=0,inswpTot,- CDEF:swpFree=0,inswpFree,- CDEF:swpUsed=0,inswpTot,inswpFree,-,- ";

$cmd .= "CDEF:memUsed=memTot,memCache,memBuf,memFree,+,+,- ";
$cmd .= "COMMENT:\"              Min             Max             Avg             Last\\n\" ";
$cmd .= "GPRINT:memUsed:MIN:\"          %7.2lf %So\" GPRINT:memUsed:MAX:\"    %7.2lf %So\" ";
$cmd .= "GPRINT:memUsed:AVERAGE:\"    %7.2lf %So\" GPRINT:memUsed:LAST:\"    %7.2lf %So     \" ";
$cmd .= "AREA:memUsed#C00000:\"memUsed\" COMMENT:\"\\n\" ";
$cmd .= "GPRINT:memCache:MIN:\"          %7.2lf %So\" GPRINT:memCache:MAX:\"    %7.2lf %So\" ";
$cmd .= "GPRINT:memCache:AVERAGE:\"    %7.2lf %So\" GPRINT:memCache:LAST:\"    %7.2lf %So     \" ";
$cmd .= "STACK:memCache#0173FF:\"memCache\" COMMENT:\"\\n\" ";
$cmd .= "GPRINT:memBuf:MIN:\"          %7.2lf %So\" GPRINT:memBuf:MAX:\"    %7.2lf %So\" ";
$cmd .= "GPRINT:memBuf:AVERAGE:\"    %7.2lf %So\" GPRINT:memBuf:LAST:\"    %7.2lf %So     \" ";
$cmd .= "STACK:memBuf#FF8737:\"memBuf\" COMMENT:\"\\n\" ";
$cmd .= "GPRINT:memFree:MIN:\"          %7.2lf %So\" GPRINT:memFree:MAX:\"    %7.2lf %So\" ";
$cmd .= "GPRINT:memFree:AVERAGE:\"    %7.2lf %So\" GPRINT:memFree:LAST:\"    %7.2lf %So     \" ";
$cmd .= "STACK:memFree#009000:\"memFree\" COMMENT:\"\\n\" ";
$cmd .= "COMMENT:\"          ----------------------------------------------------------------------------\\n\" ";
$cmd .= "GPRINT:inswpUsed:MIN:\"          %7.2lf %So\" GPRINT:inswpUsed:MAX:\"    %7.2lf %So\" ";
$cmd .= "GPRINT:inswpUsed:AVERAGE:\"    %7.2lf %So\" GPRINT:inswpUsed:LAST:\"    %7.2lf %So     \" ";
$cmd .= "AREA:swpUsed#80FF80:\"swpUsed\" COMMENT:\"\\n\" ";
$cmd .= "GPRINT:inswpFree:MIN:\"          %7.2lf %So\" GPRINT:inswpFree:MAX:\"    %7.2lf %So\" ";
$cmd .= "GPRINT:inswpFree:AVERAGE:\"    %7.2lf %So\" GPRINT:inswpFree:LAST:\"    %7.2lf %So     \" ";
$cmd .= "STACK:swpFree#FFC549:\"swpFree\" COMMENT:\"\\n\" ";
$cmd .= "COMMENT:\"          ----------------------------   $timestamp   -----------------------\\n\" ";

$scripttime = 60 * int( ($scripttime + 5) / 60); # arrondi à la minute

my $stoptime = $scripttime;
my $starttime = $stoptime - ($width - 1) * 60; # 1px / 1 min ; 480 min = 8h
my $imgname = 'mem-1-hday.png';
$cmdp = $cmd;
$cmdp =~ s/starttime/$starttime/;
$cmdp =~ s/stoptime/$stoptime/;
$cmdp =~ s/imgname/$imgname/;
print `$cmdp`;

if (($min % 5)!=0) # 5 min
{
  exit;
}

$imgname = 'mem-2-2day.png';
$starttime = $stoptime - ($width - 1) * 300; # 1px / 5 min ; 480x5 min = 40h
$cmdp = $cmd;
$cmdp =~ s/starttime/$starttime/;
$cmdp =~ s/stoptime/$stoptime/;
$cmdp =~ s/imgname/$imgname/;
print `$cmdp`;

if (($min % 30)!=0) # 30 min
{
  exit;
}

$imgname = 'mem-3-week.png';
$starttime = $stoptime - ($width - 1) * 1800; # 1px / 30 min ; 480x30 min = 240h = 10 jours
$cmdp = $cmd;
$cmdp =~ s/starttime/$starttime/;
$cmdp =~ s/stoptime/$stoptime/;
$cmdp =~ s/imgname/$imgname/;
print `$cmdp`;

if (($hour % 2)!=0 || $min!=0) # 2 heures
{
  exit;
}

$imgname = 'mem-4-month.png';
$starttime = $stoptime - ($width - 1) * 7200; # 1px / 2h ; 480x2h = 40 jours
$cmdp = $cmd;
$cmdp =~ s/starttime/$starttime/;
$cmdp =~ s/stoptime/$stoptime/;
$cmdp =~ s/imgname/$imgname/;
print `$cmdp`;

if ($hour!=0) # 1 jour
{
  exit;
}

$imgname = 'mem-5-year.png';
$starttime = $stoptime - ($width - 1) * 86400; # 1px / 1 jour ; 480 jours = 1.3 ans
$cmdp = $cmd;
$cmdp =~ s/starttime/$starttime/;
$cmdp =~ s/stoptime/$stoptime/;
$cmdp =~ s/imgname/$imgname/;
print `$cmdp`;


