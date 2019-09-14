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
my $rrdFile = 'dataDiskIO.rrd';
my $scripttime = time;
#$sec, $min, $hour, $mday, $mon, $year
my ($sec, $min, $hour, $mday, $mon, $year) = localtime($scripttime);

my $notDrawAll = 0;
$notDrawAll = 1 if (scalar(@ARGV) == 0);


my $disk1 = '/';
my $disk1dev = 'mmcblk0p2';
my $disk2 = '/boot';
my $disk2dev = 'mmcblk0p1';
my $disk3 = '_none_';
my $disk3dev = '_none_';

# get data
open(my $handle, '<', '/proc/diskstats');
chomp(my @lines = <$handle>);
close $handle;

# fielsd:
# 0              1              2       3     4          5           6         7      8           9           10      11      12    13
# majorDevNumber minorDevNumber devName reads mergereads readSectors msReading writes mergeWrites writeSector msWrite activeIO msIo weightedmsIO

my ($reads1,  $readBytes1,  $reads2,  $readBytes2,  $reads3,  $readBytes3 ) = ('U', 'U', 'U', 'U', 'U', 'U');
my ($writes1, $writeBytes1, $writes2, $writeBytes2, $writes3, $writeBytes3 ) = ('U', 'U', 'U', 'U', 'U', 'U');

foreach my $line (@lines)
{
  my @parts = split(/\s+/, $line);
  ($reads1, $readBytes1, $writes1, $writeBytes1) = ($parts[4], $parts[6] * 512, $parts[8], $parts[10] * 512) if($parts[3] eq $disk1dev);
  ($reads2, $readBytes2, $writes2, $writeBytes2) = ($parts[4], $parts[6] * 512, $parts[8], $parts[10] * 512) if($parts[3] eq $disk2dev);
  ($reads3, $readBytes3, $writes3, $writeBytes3) = ($parts[4], $parts[6] * 512, $parts[8], $parts[10] * 512) if($parts[3] eq $disk3dev);
}

# memTot:memFree:memBuf:memCache:swpTot:swpFree
my $cmd = "rrdtool update $datadir/$rrdFile $scripttime:$reads1:$writes1:$readBytes1:$writeBytes1:$reads2:$writes2:$readBytes2:$writeBytes2:$reads3:$writes3:$readBytes3:$writeBytes3 ";
print $cmd."\n";
print `$cmd`;


exit if($notDrawAll eq 1);

#my $width = 480;
my $width = 700;
my $height = 200;
my ($cmdp, $cmd2);

my $timestamp = sprintf("%4d-%02d-%02d %02d\\:%02d\\:%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);
#my (undef, $min, $hour) = localtime($scripttime);

drawGraph ('1', $disk1);
drawGraph ('2', $disk2);
drawGraph ('3', $disk3);

sub drawGraph
{
  my ($noDisk, $nameDisk) = @_;

  $cmd = "rrdtool graph $webdir/imgname -a PNG --start starttime --end stoptime -w $width -h $height --lower-limit 0 ";
  $cmd .= "DEF:Reads=$datadir/$rrdFile:Reads$noDisk:AVERAGE DEF:Writes=$datadir/$rrdFile:Writes$noDisk:AVERAGE ";

  $cmd .= "COMMENT:\"Mount point\\: $nameDisk\\n\" ";
  $cmd .= "COMMENT:\"             Avg            Min            Max            Last\\n\" ";
  $cmd .= "GPRINT:Reads:AVERAGE:\"        %8.2lf %so\" GPRINT:Reads:MIN:\"  %8.2lf %So\" ";
  $cmd .= "GPRINT:Reads:MAX:\"  %8.2lf %So\" GPRINT:Reads:LAST:\"  %8.2lf %So     \" ";
  $cmd .= "LINE:Reads#C00000:\"Reads\" COMMENT:\"\\n\" ";
  $cmd .= "GPRINT:Writes:AVERAGE:\"        %8.2lf %so\" GPRINT:Writes:MIN:\"  %8.2lf %So\" ";
  $cmd .= "GPRINT:Writes:MAX:\"  %8.2lf %So\" GPRINT:Writes:LAST:\"  %8.2lf %So     \" ";
  $cmd .= "LINE:Writes#0173FF:\"Writes\" COMMENT:\"\\n\" ";
  $cmd .= "COMMENT:\"          ----------------------------   $timestamp   -----------------------\\n\" ";


  $cmd2 = "rrdtool graph $webdir/imgname -a PNG --start starttime --end stoptime -w $width -h $height --lower-limit 0 ";
  $cmd2 .= "DEF:ReadBytes=$datadir/$rrdFile:ReadBytes$noDisk:AVERAGE DEF:WriteBytes=$datadir/$rrdFile:WriteBytes$noDisk:AVERAGE ";

  $cmd2 .= "COMMENT:\"Mount point\\: $nameDisk\\n\" ";
  $cmd2 .= "COMMENT:\"             Avg            Min            Max            Last\\n\" ";
  $cmd2 .= "GPRINT:ReadBytes:AVERAGE:\"        %8.2lf %so\" GPRINT:ReadBytes:MIN:\"  %8.2lf %So\" ";
  $cmd2 .= "GPRINT:ReadBytes:MAX:\"  %8.2lf %So\" GPRINT:ReadBytes:LAST:\"  %8.2lf %So     \" ";
  $cmd2 .= "LINE:ReadBytes#C00000:\"ReadBytes\" COMMENT:\"\\n\" ";
  $cmd2 .= "GPRINT:WriteBytes:AVERAGE:\"        %8.2lf %so\" GPRINT:WriteBytes:MIN:\"  %8.2lf %So\" ";
  $cmd2 .= "GPRINT:WriteBytes:MAX:\"  %8.2lf %So\" GPRINT:WriteBytes:LAST:\"  %8.2lf %So     \" ";
  $cmd2 .= "LINE:WriteBytes#0173FF:\"WriteBytes\" COMMENT:\"\\n\" ";
  $cmd2 .= "COMMENT:\"          ----------------------------   $timestamp   -----------------------\\n\" ";





  $scripttime = 60 * int( ($scripttime + 5) / 60); # arrondi à la minute

  my $stoptime = $scripttime;
  my $imgBaseName = "diskIO$noDisk-ops";
  my $imgBaseName2 = "diskIO$noDisk-bytes";


  my $imgname = $imgBaseName . '-1-hday.png';
  my $starttime = $stoptime - ($width - 1) * 60; # 1px / 1 min ; 480 min = 8h
  $cmdp = $cmd;
  $cmdp =~ s/starttime/$starttime/;
  $cmdp =~ s/stoptime/$stoptime/;
  $cmdp =~ s/imgname/$imgname/;
  print `$cmdp`;

  $imgname = $imgBaseName2 . '-1-hday.png';
  $cmdp = $cmd2;
  $cmdp =~ s/starttime/$starttime/;
  $cmdp =~ s/stoptime/$stoptime/;
  $cmdp =~ s/imgname/$imgname/;
  print `$cmdp`;


  if (($min % 5)!=0 && $notDrawAll) # 5 min
  {
    return;
  }

  $imgname = $imgBaseName . '-2-2day.png';
  $starttime = $stoptime - ($width - 1) * 300; # 1px / 5 min ; 480x5 min = 40h
  $cmdp = $cmd;
  $cmdp =~ s/starttime/$starttime/;
  $cmdp =~ s/stoptime/$stoptime/;
  $cmdp =~ s/imgname/$imgname/;
  print `$cmdp`;

  $imgname = $imgBaseName2 . '-2-2day.png';
  $cmdp = $cmd2;
  $cmdp =~ s/starttime/$starttime/;
  $cmdp =~ s/stoptime/$stoptime/;
  $cmdp =~ s/imgname/$imgname/;
  print `$cmdp`;

  if (($min % 30)!=0 && $notDrawAll) # 30 min
  {
    return;
  }

  $imgname = $imgBaseName . '-3-week.png';
  $starttime = $stoptime - ($width - 1) * 1800; # 1px / 30 min ; 480x30 min = 240h = 10 jours
  $cmdp = $cmd;
  $cmdp =~ s/starttime/$starttime/;
  $cmdp =~ s/stoptime/$stoptime/;
  $cmdp =~ s/imgname/$imgname/;
  print `$cmdp`;

  if ( (($hour % 2)!=0 || $min!=0) && $notDrawAll ) # 2 heures
  {
    return;
  }

  $imgname = $imgBaseName . '-4-month.png';
  $starttime = $stoptime - ($width - 1) * 7200; # 1px / 2h ; 480x2h = 40 jours
  $cmdp = $cmd;
  $cmdp =~ s/starttime/$starttime/;
  $cmdp =~ s/stoptime/$stoptime/;
  $cmdp =~ s/imgname/$imgname/;
  print `$cmdp`;

  if ($hour!=0 && $notDrawAll) # 1 jour
  {
    return;
  }

  $imgname = $imgBaseName . '-5-year.png';
  $starttime = $stoptime - ($width - 1) * 86400; # 1px / 1 jour ; 480 jours = 1.3 ans
    $cmdp = $cmd;
  $cmdp =~ s/starttime/$starttime/;
  $cmdp =~ s/stoptime/$stoptime/;
  $cmdp =~ s/imgname/$imgname/;
  print `$cmdp`;

}

