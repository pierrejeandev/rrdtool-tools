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
my $rrdFile = 'dataCpu.rrd';
my $scripttime = time;



my @cpustats = `cat /proc/stat | grep cpu`;
my $nbcpu = @cpustats-1;
print "Nombre de CPU : $nbcpu\n";


my (undef, $user, $nice, $priv, $idle, $iowait, $irq, $softirq) = split(' ', $cpustats[0]);
$user += $nice;
$priv += $iowait + $irq + $softirq;
print "$user, $priv, $idle\n";



my $cmd = "rrdtool update $datadir/$rrdFile $scripttime:$user:$priv:$idle  \n";
print `$cmd`;


my $width = 700; # 480;
my $height = 200;


my ($sec, $min, $hour, $mday, $mon, $year) = localtime($scripttime);
my $timestamp = sprintf('%4d-%02d-%02d %02d\:%02d\:%02d', $year+1900, $mon+1, $mday, $hour, $min, $sec);

$cmd  = "rrdtool graph $webdir/imgname -a PNG --start starttime --end stoptime -w $width -h $height ";
$cmd .= "DEF:user=$datadir/$rrdFile:user:AVERAGE DEF:priv=$datadir/$rrdFile:priv:AVERAGE ";
$cmd .= "DEF:idle=$datadir/$rrdFile:idle:AVERAGE ";
$cmd .= "COMMENT:\"             Min            Max            Avg            Last\\n\" ";
$cmd .= "GPRINT:user:MIN:\"       %10.2lf %%\" GPRINT:user:MAX:\" %10.2lf %%\" ";
$cmd .= "GPRINT:user:AVERAGE:\" %10.2lf %%\" GPRINT:user:LAST:\" %10.2lf %%     \" ";
$cmd .= "AREA:user#00FF00:\"user Cpu\" COMMENT:\"\\n\" ";
$cmd .= "GPRINT:priv:MIN:\"       %10.2lf %%\" GPRINT:priv:MAX:\" %10.2lf %%\" ";
$cmd .= "GPRINT:priv:AVERAGE:\" %10.2lf %%\" GPRINT:priv:LAST:\" %10.2lf %%     \" ";
$cmd .= "STACK:priv#FF0000:\"priv Cpu\" COMMENT:\"\\n\" ";
$cmd .= "GPRINT:idle:MIN:\"       %10.2lf %%\" GPRINT:idle:MAX:\" %10.2lf %%\" ";
$cmd .= "GPRINT:idle:AVERAGE:\" %10.2lf %%\" GPRINT:idle:LAST:\" %10.2lf %%     \" ";
$cmd .= "STACK:idle#8080FF:\"idle Cpu\" COMMENT:\"\\n\" ";
$cmd .= "COMMENT:\"          ----------------------------   $timestamp   -----------------------\\n\" ";

my $cmdp;

$scripttime = 60 * int( ($scripttime + 5) / 60); # arrondi à la minute

my $stoptime = $scripttime;
my $starttime = $stoptime - ($width - 1) * 60; # 1px / 1 min ; 480 min = 8h
my $imgname = 'cpu-1-hday.png';
$cmdp = $cmd;
$cmdp =~ s/starttime/$starttime/;
$cmdp =~ s/stoptime/$stoptime/;
$cmdp =~ s/imgname/$imgname/;
print `$cmdp`;


if (($min % 5)!=0) # 5 min
{
  exit;
}
  
$imgname = 'cpu-2-2day.png';
$starttime = $stoptime - ($width - 1) * 300; # 1px / 5 min ; 480x5 min = 40h
$cmdp = $cmd;
$cmdp =~ s/starttime/$starttime/;
$cmdp =~ s/stoptime/$stoptime/;
$cmdp =~ s/imgname/$imgname/;
#print $cmdp, "\n";
print `$cmdp`;

if (($min % 30)!=0) # 30 min
{
  exit;
}

$imgname = 'cpu-3-week.png';
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

$imgname = 'cpu-4-month.png';
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

$imgname = 'cpu-5-year.png';
$starttime = $stoptime - ($width - 1) * 86400; # 1px / 1 jour ; 480 jours = 1.3 ans
$cmdp = $cmd;
$cmdp =~ s/starttime/$starttime/;
$cmdp =~ s/stoptime/$stoptime/;
$cmdp =~ s/imgname/$imgname/;
print `$cmdp`;


