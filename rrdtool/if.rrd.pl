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
my $scripttimereal = time;
my $scripttime = 60 * int( ($scripttimereal + 5) / 60); # arrondi à la minute

#my $rrdFile = 'dataMem.rrd';

my $width = 700;
my $height = 200;
my $cmdp;

#$sec, $min, $hour, $mday, $mon, $year
my ($sec, $min, $hour, $mday, $mon, $year) = localtime($scripttime);
my $timestamp = sprintf('%4d-%02d-%02d %02d\:%02d\:%02d', $year+1900, $mon+1, $mday, $hour, $min, $sec);

# Recherche des données dans /proc
# les donnée sont stockée dans la variable $devs
my $kernelversion = `uname -r`;

my $devs = {};

# print `date`;

if ($kernelversion =~m/^2\.4\..*/)
{
  # Non implemented
  print "Unsuported kervel version. Supported version are 2.4 and 2.6\n";
  exit;
}
elsif ($kernelversion =~m/^2\.6\..*/ || $kernelversion =~m/^[34]\..*/)
{
  my @devstat = `cat /proc/net/dev`;
  for(my $i=2; $i <= $#devstat; $i++)
  {
#Inter-|   Receive                                                |  Transmit
# face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed

    if($devstat[$i] =~ m/^\s*(\w+):\s*(\d+)\s+(\d+)\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+(\d+)\s+(\d+)\s+/)
    {
      $devs->{$1} = {ReceiveByte => $2, ReceivePacket => $3, TransmitByte => $4, TransmitPacket => $5};
    }
    else
    {
      print $i, ' ', $devstat[$i], "\n";
    }
  }
}
else
{
  print "Unsuported kervel version. Supported version are 2.4 and 2.6\n";
  exit;
}

# traitement de chaque interface contenue dans $devs
foreach my $dev (keys(%$devs))
{
  updateRrdForDevice($dev);
}


# fonction de traitement d'une interface
sub updateRrdForDevice
{
# le device (interface) à traiter. Par ex lo, eth0, tap0
  my ($dev) = @_;

  print "Updating $dev\n";

  my $rrdFile = "dataIf$dev.rrd";
  
  # vérification de l'existance de la base rrd --> on arrête si pas de base pour ce device
  if( not -e "$datadir/$rrdFile")
  {
    print "No data file '$datadir/$rrdFile'\n";
    return;
  }


  # mise à jour de la base RRD
  my $cmd = "rrdtool update $datadir/$rrdFile $scripttimereal:" . $devs->{$dev}->{ReceiveByte} . ':' . $devs->{$dev}->{TransmitByte} . "\n";
#  print "$cmd";  # DEBUG
  print `$cmd`;

  
 # Graphique 
  $cmd = "rrdtool graph $webdir/imgname -a PNG --start starttime --end stoptime -w $width -h $height --logarithmic --units=si ";
  $cmd .= "DEF:RecAvg=$datadir/$rrdFile:Receive:AVERAGE DEF:TraAvg=$datadir/$rrdFile:Transmit:AVERAGE ";
  $cmd .= "DEF:RecMax=$datadir/$rrdFile:Receive:MAX DEF:TraMax=$datadir/$rrdFile:Transmit:MAX ";

  $cmd .= "COMMENT:\"       Min              Max               Avg             Last\\n\" ";
  $cmd .= "GPRINT:RecAvg:MIN:\"    %6.2lf %sB/s\" GPRINT:RecMax:MAX:\"    %6.2lf %sB/s\" ";
  $cmd .= "GPRINT:RecAvg:AVERAGE:\"    %6.2lf %sB/s\" GPRINT:RecAvg:LAST:\"    %6.2lf %sB/s     \" ";
  $cmd .= "AREA:RecMax#80FF80: ";
  $cmd .= "AREA:RecAvg#00FF00:\"Receive Bytes per second\" COMMENT:\"\\n\" ";
  $cmd .= "GPRINT:TraAvg:MIN:\"    %6.2lf %sB/s\" GPRINT:TraMax:MAX:\"    %6.2lf %sB/s\" ";
  $cmd .= "GPRINT:TraAvg:AVERAGE:\"    %6.2lf %sB/s\" GPRINT:TraAvg:LAST:\"    %6.2lf %sB/s     \" ";
  $cmd .= "LINE:TraMax#8080FF: ";
  $cmd .= "LINE:TraAvg#0000FF:\"Transmit Bytes per second\" COMMENT:\"\\n\" ";
  $cmd .= "COMMENT:\"          ----------------------------   $timestamp   -----------------------\\n\" \n";


  my $stoptime = $scripttime;
  my $starttime = $stoptime - ($width - 1) * 60; # 1px / 1 min ; 480 min = 8h
  my $imgname = "if-$dev-1-hday.png";
  $cmdp = $cmd;
  $cmdp =~ s/starttime/$starttime/;
  $cmdp =~ s/stoptime/$stoptime/;
  $cmdp =~ s/imgname/$imgname/;
  #print "$cmdp";  # DEBUG
  print `$cmdp`;

  if (($min % 5)!=0) # 5 min
  {
    return;
  }

  $imgname = "if-$dev-2-2day.png";
  $starttime = $stoptime - ($width - 1) * 300; # 1px / 5 min ; 480x5 min = 40h
  $cmdp = $cmd;
  $cmdp =~ s/starttime/$starttime/;
  $cmdp =~ s/stoptime/$stoptime/;
  $cmdp =~ s/imgname/$imgname/;
  print `$cmdp`;

  if (($min % 30)!=0) # 30 min
  {
    return;
  }

  $imgname = "if-$dev-3-week.png";
  $starttime = $stoptime - ($width - 1) * 1800; # 1px / 30 min ; 480x30 min = 240h = 10 jours
  $cmdp = $cmd;
  $cmdp =~ s/starttime/$starttime/;
  $cmdp =~ s/stoptime/$stoptime/;
  $cmdp =~ s/imgname/$imgname/;
  print `$cmdp`;

  if (($hour % 2)!=0 || $min!=0) # 2 heures
  {
    return;
  }

  $imgname = "if-$dev-4-month.png";
  $starttime = $stoptime - ($width - 1) * 7200; # 1px / 2h ; 480x2h = 40 jours
  $cmdp = $cmd;
  $cmdp =~ s/starttime/$starttime/;
  $cmdp =~ s/stoptime/$stoptime/;
  $cmdp =~ s/imgname/$imgname/;
  print `$cmdp`;

  if ($hour!=0) # 1 jour
  {
    return;
  }

  $imgname = "if-$dev-5-year.png";
  $starttime = $stoptime - ($width - 1) * 86400; # 1px / 1 jour ; 480 jours = 1.3 ans
  $cmdp = $cmd;
  $cmdp =~ s/starttime/$starttime/;
  $cmdp =~ s/stoptime/$stoptime/;
  $cmdp =~ s/imgname/$imgname/;
  print `$cmdp`;


}

