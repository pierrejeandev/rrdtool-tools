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
## Copyrigth Pierre-Jean DEVILLE  30/08/2005
###############################################################################


use strict;

use File::Basename;
use Cwd 'abs_path';

# datadir = folder where this script is stored
my $datadir = dirname(abs_path(__FILE__));
my $webdir = '/var/www/rrd';

my $pinghost = 'www.yahoo.com';
my $id = '1';
if(scalar(@ARGV) == 2)
{
  $id = $ARGV[0];
  $pinghost = $ARGV[1];
}
else
{
  print "usage: ./ping.rrd.pl <id> <hostname> \n";
}

my $rrdFile = "dataPing${id}.rrd";

my $scripttime = time;


my ($sec, $min, $hour, $mday, $mon, $year) = localtime($scripttime);
my $timestamp = sprintf('%4d-%02d-%02d %02d\:%02d\:%02d', $year+1900, $mon+1, $mday, $hour, $min, $sec);
#print "$timestamp\n";
print "Ping to $pinghost ($id) : \n";

my @lines = `ping -q -i 1 -c 59 -s 500 $pinghost`;

#PING fd-fp3.wg1.b.yahoo.com (46.228.47.115) 500(528) bytes of data.
#--- fd-fp3.wg1.b.yahoo.com ping statistics ---
#60 packets transmitted, 60 received, 0% packet loss, time 59081ms
#rtt min/avg/max/mdev = 59.577/61.614/81.036/2.818 ms

my ($sent, $received, $lost, $rttmin, $rttmax, $rttavg, $rttmdev) = ('U', 'U', 'U', 'U', 'U', 'U', 'U');
foreach my $line (@lines)
{
  if($line =~ m/(\d+) packets transmitted, (\d+) received/)
  {
    $sent = $1;
    $received = $2;
    # in perccent
    $lost = ($sent - $received) / $sent * 100.0;
    $received = $received / $sent * 100.0;

  }
  elsif($line =~m/rtt min\/avg\/max\/mdev = ([\d\.]+)\/([\d\.]+)\/([\d\.]+)\/([\d\.]+) ms/)
  {
    $rttmin  = $1;
    $rttavg  = $2;
    $rttmax  = $3;
    $rttmdev = $4;
  }
}

$scripttime = time;
my ($sec, $min, $hour, $mday, $mon, $year) = localtime($scripttime);
my $timestamp = sprintf('%4d-%02d-%02d %02d\:%02d\:%02d', $year+1900, $mon+1, $mday, $hour, $min, $sec);

print "$timestamp\n";
print "ping $id $pinghost sent:$sent, recieved:$received, lost:$lost:, rtttmin:$rttmin, rttavg:$rttavg, rttmax:$rttmax, rttdev:$rttmdev\n";

my $cmd = "rrdtool update $datadir/$rrdFile $scripttime:$sent:$received:$lost:$rttmin:$rttavg:$rttmax:$rttmdev \n";
print `$cmd`;


my $width = 700; # 480;
my $height = 200;


$cmd  = "rrdtool graph $webdir/imgname -a PNG --start starttime --end stoptime -w $width -h $height --logarithmic -l 1 ";
$cmd .= "DEF:received=$datadir/$rrdFile:received:AVERAGE DEF:lost=$datadir/$rrdFile:lost:AVERAGE ";
$cmd .= "COMMENT:\"             Min            Max            Avg            Last\\n\" ";
$cmd .= "GPRINT:lost:MIN:\"       %10.2lf %%\" GPRINT:lost:MAX:\" %10.2lf %%\" ";
$cmd .= "GPRINT:lost:AVERAGE:\" %10.2lf %%\" GPRINT:lost:LAST:\" %10.2lf %%     \" ";
$cmd .= "AREA:lost#FF0000:\"lost ping %\" COMMENT:\"\\n\" ";
$cmd .= "GPRINT:received:MIN:\"       %10.2lf %%\" GPRINT:received:MAX:\" %10.2lf %%\" ";
$cmd .= "GPRINT:received:AVERAGE:\" %10.2lf %%\" GPRINT:received:LAST:\" %10.2lf %%     \" ";
$cmd .= "STACK:received#00FF00:\"received ping %\" COMMENT:\"\\n\" ";
$cmd .= "COMMENT:\"          ping $pinghost \\n\" ";
$cmd .= "COMMENT:\"          ----------------------------   $timestamp   -----------------------\\n\" ";

my $cmd2 = "rrdtool graph $webdir/imgname -a PNG --start starttime --end stoptime -w $width -h $height --units-exponent 0 --logarithmic ";
$cmd2 .= "DEF:rrtMin=$datadir/$rrdFile:rrtMin:MIN DEF:rrtAvg=$datadir/$rrdFile:rrtAvg:AVERAGE ";
$cmd2 .= "DEF:rrtMax=$datadir/$rrdFile:rrtMax:MAX DEF:rrtMdev=$datadir/$rrdFile:rrtMdev:AVERAGE ";
$cmd2 .= "COMMENT:\"             Min            Max            Avg            Last\\n\" ";
$cmd2 .= "GPRINT:rrtMin:MIN:\"       %10.2lf ms\" GPRINT:rrtMin:MAX:\" %10.2lf ms\" ";
$cmd2 .= "GPRINT:rrtMin:AVERAGE:\" %10.2lf ms\" GPRINT:rrtMin:LAST:\" %10.2lf ms     \" ";
$cmd2 .= "LINE:rrtMin#00FF00:\"rrtMin ms\" COMMENT:\"\\n\" ";
$cmd2 .= "GPRINT:rrtAvg:MIN:\"       %10.2lf ms\" GPRINT:rrtAvg:MAX:\" %10.2lf ms\" ";
$cmd2 .= "GPRINT:rrtAvg:AVERAGE:\" %10.2lf ms\" GPRINT:rrtAvg:LAST:\" %10.2lf ms     \" ";
$cmd2 .= "LINE:rrtAvg#0000FF:\"rrtAvg ms\" COMMENT:\"\\n\" ";
$cmd2 .= "GPRINT:rrtMax:MIN:\"       %10.2lf ms\" GPRINT:rrtMax:MAX:\" %10.2lf ms\" ";
$cmd2 .= "GPRINT:rrtMax:AVERAGE:\" %10.2lf ms\" GPRINT:rrtMax:LAST:\" %10.2lf ms     \" ";
$cmd2 .= "LINE:rrtMax#FF0000:\"rrtMax ms\" COMMENT:\"\\n\" ";
$cmd2 .= "GPRINT:rrtMdev:MIN:\"       %10.2lf ms\" GPRINT:rrtMdev:MAX:\" %10.2lf ms\" ";
$cmd2 .= "GPRINT:rrtMdev:AVERAGE:\" %10.2lf ms\" GPRINT:rrtMdev:LAST:\" %10.2lf ms     \" ";
$cmd2 .= "LINE:rrtMdev#00FFFF:\"rrtMdev ms\" COMMENT:\"\\n\" ";
$cmd2 .= "COMMENT:\"          ping $pinghost \\n\" ";
$cmd2 .= "COMMENT:\"          ----------------------------   $timestamp   -----------------------\\n\" ";


my $cmdp;

$scripttime = 60 * int( ($scripttime + 5) / 60); # arrondi à la minute

my $stoptime = $scripttime;
my $starttime = $stoptime - ($width - 1) * 60; # 1px / 1 min ; 480 min = 8h
my $imgname = "ping-${id}-1-hday.png";
$cmdp = $cmd;
$cmdp =~ s/starttime/$starttime/;
$cmdp =~ s/stoptime/$stoptime/;
$cmdp =~ s/imgname/$imgname/;
print `$cmdp`;
my $imgname = "ping${id}Lat-hday.png";
$cmdp = $cmd2;
$cmdp =~ s/starttime/$starttime/;
$cmdp =~ s/stoptime/$stoptime/;
$cmdp =~ s/imgname/$imgname/;
print `$cmdp`;


if (($min % 5)!=0) # 5 min
{
    exit;
}

$imgname = "ping-${id}-2-2day.png";
my $starttime = $stoptime - ($width - 1) * 300; # 1px / 5 min ; 480x5 min = 40h
$cmdp = $cmd;
$cmdp =~ s/starttime/$starttime/;
$cmdp =~ s/stoptime/$stoptime/;
$cmdp =~ s/imgname/$imgname/;
#print $cmdp, "\n";
print `$cmdp`;
my $imgname = "ping-${id}-Lat-2-2day.png";
$cmdp = $cmd2;
$cmdp =~ s/starttime/$starttime/;
$cmdp =~ s/stoptime/$stoptime/;
$cmdp =~ s/imgname/$imgname/;
print `$cmdp`;

if (($min % 30)!=0) # 30 min
{
    exit;
}

$imgname = "ping-${id}-3-week.png";
$starttime = $stoptime - ($width - 1) * 1800; # 1px / 30 min ; 480x30 min = 240h = 10 jours
$cmdp = $cmd;
$cmdp =~ s/starttime/$starttime/;
$cmdp =~ s/stoptime/$stoptime/;
$cmdp =~ s/imgname/$imgname/;
print `$cmdp`;
my $imgname = "ping-${id}-Lat-3-week.png";
$cmdp = $cmd2;
$cmdp =~ s/starttime/$starttime/;
$cmdp =~ s/stoptime/$stoptime/;
$cmdp =~ s/imgname/$imgname/;
print `$cmdp`;

if (($hour % 2)!=0 || $min!=0) # 2 heures
{
    exit;
}

$imgname = "ping-${id}-4-month.png";
$starttime = $stoptime - ($width - 1) * 7200; # 1px / 2h ; 480x2h = 40 jours
$cmdp = $cmd;
$cmdp =~ s/starttime/$starttime/;
$cmdp =~ s/stoptime/$stoptime/;
$cmdp =~ s/imgname/$imgname/;
print `$cmdp`;
my $imgname = "ping-${id}-Lat-4-month.png";
$cmdp = $cmd2;
$cmdp =~ s/starttime/$starttime/;
$cmdp =~ s/stoptime/$stoptime/;
$cmdp =~ s/imgname/$imgname/;
print `$cmdp`;

if ($hour!=0) # 1 jour
{
    exit;
}

$imgname = "ping-${id}-5-year.png";
$starttime = $stoptime - ($width - 1) * 86400; # 1px / 1 jour ; 480 jours = 1.3 ans
$cmdp = $cmd;
$cmdp =~ s/starttime/$starttime/;
$cmdp =~ s/stoptime/$stoptime/;
$cmdp =~ s/imgname/$imgname/;
print `$cmdp`;
my $imgname = "ping-${id}-Lat-5-year.png";
$cmdp = $cmd2;
$cmdp =~ s/starttime/$starttime/;
$cmdp =~ s/stoptime/$stoptime/;
$cmdp =~ s/imgname/$imgname/;
print `$cmdp`;
     
