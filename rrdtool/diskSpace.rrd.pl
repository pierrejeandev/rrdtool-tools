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
my $rrdFile = 'dataDiskSpace.rrd';
my $scripttime = time;
#$sec, $min, $hour, $mday, $mon, $year
my ($sec, $min, $hour, $mday, $mon, $year) = localtime($scripttime);

my $notDrawAll = 0;
$notDrawAll = 1 if (scalar(@ARGV) == 0);

# toutes les 5 minutes seulement
if (($min % 5)!=0 && $notDrawAll ) # 5 min
{
  exit;
  print "exit;\n";
}

#my $disk1 = '/dev/sdb2';
#my $disk2 = '/dev/shm';
#my $disk3 = '/dev/sda1';

my $disk1 = '/';
my $disk2 = '/boot';
my $disk3 = '_none_';

#($device, $size, $used, $free, $percent, $mount) = split(/\s+/);
$_ = `df -B 1 $disk1 | grep "$disk1"`;
my (undef, undef, $used1, $free1, undef, $diskName1) = split(/\s+/);
$diskName1 = $disk1 if ( (not defined $diskName1) || $diskName1 eq '' );
($used1, $free1) = ('U', 'U') if (not(defined($used1)) or $used1 eq '');

$_ = `df -B 1 $disk2 | grep "$disk2"`;
my (undef, undef, $used2, $free2, undef, $diskName2) = split(/\s+/);
$diskName2 = $disk2 if ( (not defined $diskName2) || $diskName2 eq '' );
($used2, $free2) = ('U', 'U') if (not(defined($used2)) or $used2 eq '');

$_ = `df -B 1 $disk3 | grep "$disk3"`;
my (undef, undef, $used3, $free3, undef, $diskName3) = split(/\s+/);
$diskName3 = $disk3 if ( (not defined $diskName3) || $diskName3 eq '' );
($used3, $free3) = ('U', 'U') if (not(defined($used3)) or $used3 eq '');


# memTot:memFree:memBuf:memCache:swpTot:swpFree
my $cmd = "rrdtool update $datadir/$rrdFile $scripttime:$used1:$free1:$used2:$free2:$used3:$free3 ";
print $cmd."\n";
print `$cmd`;


#my $width = 480;
my $width = 700;
my $height = 200;
my $cmdp;

my $timestamp = sprintf("%4d-%02d-%02d %02d\\:%02d\\:%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);
#my (undef, $min, $hour) = localtime($scripttime);

drawGraph ('1', $diskName1);
drawGraph ('2', $diskName2);
drawGraph ('3', $diskName3);

sub drawGraph
{
  my ($noDisk, $nameDisk) = @_;

  $cmd = "rrdtool graph $webdir/imgname -a PNG --start starttime --end stoptime -w $width -h $height --lower-limit 0 ";
  $cmd .= "DEF:KoUsed=$datadir/$rrdFile:KoUsed$noDisk:AVERAGE DEF:KoFree=$datadir/$rrdFile:KoFree$noDisk:AVERAGE ";

  $cmd .= "COMMENT:\"Mount point\\: $nameDisk\\n\" ";
  $cmd .= "COMMENT:\"             Avg            Min            Max            Last\\n\" ";
  $cmd .= "GPRINT:KoUsed:AVERAGE:\"        %8.2lf %so\" GPRINT:KoUsed:MIN:\"  %8.2lf %So\" ";
  $cmd .= "GPRINT:KoUsed:MAX:\"  %8.2lf %So\" GPRINT:KoUsed:LAST:\"  %8.2lf %So     \" ";
  $cmd .= "AREA:KoUsed#C00000:\"KoUsed\" COMMENT:\"\\n\" ";
  $cmd .= "GPRINT:KoFree:AVERAGE:\"        %8.2lf %so\" GPRINT:KoFree:MIN:\"  %8.2lf %So\" ";
  $cmd .= "GPRINT:KoFree:MAX:\"  %8.2lf %So\" GPRINT:KoFree:LAST:\"  %8.2lf %So     \" ";
  $cmd .= "STACK:KoFree#0173FF:\"KoFree\" COMMENT:\"\\n\" ";
  $cmd .= "COMMENT:\"          ----------------------------   $timestamp   -----------------------\\n\" ";

  $scripttime = 60 * int( ($scripttime + 5) / 60); # arrondi à la minute

  my $stoptime = $scripttime;
  my $imgBaseName = "diskSpace$noDisk";
  my $imgname = $imgBaseName.'-2day.png';
  my $starttime = $stoptime - ($width - 1) * 300; # 1px / 5 min ; 480x5 min = 40h
  $cmdp = $cmd;
  $cmdp =~ s/starttime/$starttime/;
  $cmdp =~ s/stoptime/$stoptime/;
  $cmdp =~ s/imgname/$imgname/;
  print `$cmdp`;

  if (($min % 30)!=0 && $notDrawAll) # 30 min
  {
    return;
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
    return;
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
    return;
  }

  $imgname = $imgBaseName.'-year.png';
  $starttime = $stoptime - ($width - 1) * 86400; # 1px / 1 jour ; 480 jours = 1.3 ans
    $cmdp = $cmd;
  $cmdp =~ s/starttime/$starttime/;
  $cmdp =~ s/stoptime/$stoptime/;
  $cmdp =~ s/imgname/$imgname/;
  print `$cmdp`;

}

