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
my $rrdFileVoltage = 'dataVoltage.rrd';
my $rrdFileTemperature = 'dataTemperature.rrd';
my $scripttime = time;

# $ sensors
# nouveau-pci-0300
# Adapter: PCI adapter
# temp1:        +58.0°C  (high = +95.0°C, hyst =  +3.0°C)
#                        (crit = +105.0°C, hyst =  +5.0°C)
#                        (emerg = +135.0°C, hyst =  +5.0°C)
# 
# coretemp-isa-0000
# Adapter: ISA adapter
# Core 0:       +35.0°C  (crit = +100.0°C)
# Core 1:       +36.0°C  (crit = +100.0°C)
#
# atk0110-acpi-0
# Adapter: ACPI interface
# Vcore Voltage:      +1.13 V  (min =  +0.80 V, max =  +1.60 V)
#  +3.3 Voltage:      +3.30 V  (min =  +2.97 V, max =  +3.63 V)
#  +5 Voltage:        +5.09 V  (min =  +4.50 V, max =  +5.50 V)
#  +12 Voltage:      +11.87 V  (min = +10.20 V, max = +13.80 V)
# CPU FAN Speed:     2163 RPM  (min = 1600 RPM, max = 7200 RPM)
# CHASSIS FAN Speed: 2083 RPM  (min = 1600 RPM, max = 7200 RPM)
# CPU Temperature:    +46.0°C  (high = +60.0°C, crit = +95.0°C)
# MB Temperature:     +42.0°C  (high = +45.0°C, crit = +75.0°C)
# GPU Temperature:    +58.0°C  (high = +60.0°C, crit = +95.0°C)

my @sensors = `sensors`;
my ($v5, $v12, $vCore, $v3) = ('', '', '', '');
my ($tpPci, $tpCore0, $tpCore1, $tpCpu, $tpMb, $tpGpu) = ('', '', '', '', '', '');

my $cmd;
foreach my $line (@sensors)
{
  if($line =~ m/Vcore Voltage:\s+([\+\d\.]+)\sV/)
  {
    $vCore = $1;
  }
  elsif($line =~ m/\+3.3 Voltage:\s+([\+\d\.]+)\sV/)
  {
    $v3 = $1;
  }
  elsif($line =~ m/\+5 Voltage:\s+([\+\d\.]+)\sV/)
  {
    $v5 = $1;
  }
  elsif($line =~ m/\+12 Voltage:\s+([\+\d\.]+)\sV/)
  {
    $v12 = $1;
  }
  elsif($line =~ m/temp1:\s+([\+\d\.]+)°C/)
  {
    $tpPci = $1;
  }
  elsif($line =~ m/Core 0:\s+([\+\d\.]+)°C/)
  {
    $tpCore0 = $1;
  }
  elsif($line =~ m/Core 1:\s+([\+\d\.]+)°C/)
  {
    $tpCore1 = $1;
  }
  elsif($line =~ m/CPU Temperature:\s+([\+\d\.]+)°C/)
  {
    $tpCpu = $1;
  }
  elsif($line =~ m/MB Temperature:\s+([\+\d\.]+)°C/)
  {
    $tpMb = $1;
  }
  elsif($line =~ m/GPU Temperature:\s+([\+\d\.]+)°C/)
  {
    $tpGpu = $1;
  }
}

if(not -e "$datadir/$rrdFileVoltage")
{
  $cmd  = "rrdtool create $datadir/$rrdFileVoltage --step 60 --start " . ($scripttime - 60) . " ";
  $cmd .= "DS:vCore:GAUGE:600:-1:30 ";
  $cmd .= "DS:v3:GAUGE:600:-1:30 "; 
  $cmd .= "DS:v5:GAUGE:600:-1:30 "; 
  $cmd .= "DS:v12:GAUGE:600:-1:30 "; 
  $cmd .= "RRA:AVERAGE:0.5:1:1500 ";
  $cmd .= "RRA:AVERAGE:0.5:5:700 ";
  $cmd .= "RRA:AVERAGE:0.5:30:700 ";
  $cmd .= "RRA:AVERAGE:0.5:120:775 ";
  $cmd .= "RRA:AVERAGE:0.5:1440:797 ";
  $cmd .= "RRA:MIN:0.5:1:1500 ";
  $cmd .= "RRA:MIN:0.5:5:700 ";
  $cmd .= "RRA:MIN:0.5:30:700 ";
  $cmd .= "RRA:MIN:0.5:120:775 ";
  $cmd .= "RRA:MIN:0.5:1440:797 ";
  print `$cmd`;
}
if(not -e "$datadir/$rrdFileTemperature")
{
  $cmd  = "rrdtool create $datadir/$rrdFileTemperature --step 60 --start " . ($scripttime - 60) . " ";
  $cmd .= "DS:tpPci:GAUGE:600:-20:200 ";
  $cmd .= "DS:tpCore0:GAUGE:600:-20:200 "; 
  $cmd .= "DS:tpCore1:GAUGE:600:-20:200 "; 
  $cmd .= "DS:tpCpu:GAUGE:600:-20:200 "; 
  $cmd .= "DS:tpMb:GAUGE:600:-20:200 "; 
  $cmd .= "DS:tpGpu:GAUGE:600:-20:200 "; 
  $cmd .= "RRA:AVERAGE:0.5:1:1500 ";
  $cmd .= "RRA:AVERAGE:0.5:5:700 ";
  $cmd .= "RRA:AVERAGE:0.5:30:700 ";
  $cmd .= "RRA:AVERAGE:0.5:120:775 ";
  $cmd .= "RRA:AVERAGE:0.5:1440:797 ";
  $cmd .= "RRA:MAX:0.5:1:1500 ";
  $cmd .= "RRA:MAX:0.5:5:700 ";
  $cmd .= "RRA:MAX:0.5:30:700 ";
  $cmd .= "RRA:MAX:0.5:120:775 ";
  $cmd .= "RRA:MAX:0.5:1440:797 ";
  print `$cmd`;
}

print "voltage $vCore, $v3, $v5, $v12\n";
$cmd = "rrdtool update $datadir/$rrdFileVoltage $scripttime:$vCore:$v3:$v5:$v12 \n";
print `$cmd`;

print "temperature $tpPci, $tpCore0, $tpCore1, $tpCpu, $tpMb, $tpGpu\n";
$cmd = "rrdtool update $datadir/$rrdFileTemperature $scripttime:$tpPci:$tpCore0:$tpCore1:$tpCpu:$tpMb:$tpGpu \n";
print `$cmd`;

#my $width = 480;
my $width = 700;
my $height = 200;
my $cmdp;

#$sec, $min, $hour, $mday, $mon, $year
my ($sec, $min, $hour, $mday, $mon, $year) = localtime($scripttime);
my $timestamp = sprintf('%4d-%02d-%02d %02d\:%02d\:%02d', $year+1900, $mon+1, $mday, $hour, $min, $sec);



$cmd = "rrdtool graph $webdir/imgname -a PNG --start starttime --end stoptime -w $width -h $height -l 0 ";
$cmd .= "DEF:vCore=$datadir/$rrdFileVoltage:vCore:AVERAGE DEF:v3=$datadir/$rrdFileVoltage:v3:AVERAGE ";
$cmd .= "DEF:v5=$datadir/$rrdFileVoltage:v5:AVERAGE       DEF:v12=$datadir/$rrdFileVoltage:v12:AVERAGE ";

$cmd .= "COMMENT:\"              Min             Max             Avg             Last\\n\" ";
$cmd .= "GPRINT:vCore:MIN:\"          %7.2lf %SV\" GPRINT:vCore:MAX:\"    %7.2lf %SV\" ";
$cmd .= "GPRINT:vCore:AVERAGE:\"    %7.2lf %SV\"   GPRINT:vCore:LAST:\"    %7.2lf %SV     \" ";
$cmd .= "LINE2:vCore#C00000:\"vCore\" COMMENT:\"\\n\" ";
$cmd .= "GPRINT:v3:MIN:\"          %7.2lf %SV\" GPRINT:v3:MAX:\"    %7.2lf %SV\" ";
$cmd .= "GPRINT:v3:AVERAGE:\"    %7.2lf %SV\"   GPRINT:v3:LAST:\"    %7.2lf %SV     \" ";
$cmd .= "LINE2:v3#0173FF:\"v3.3\" COMMENT:\"\\n\" ";
$cmd .= "GPRINT:v5:MIN:\"          %7.2lf %SV\" GPRINT:v5:MAX:\"    %7.2lf %SV\" ";
$cmd .= "GPRINT:v5:AVERAGE:\"    %7.2lf %SV\"   GPRINT:v5:LAST:\"    %7.2lf %SV     \" ";
$cmd .= "LINE2:v5#FF8737:\"v5\" COMMENT:\"\\n\" ";
$cmd .= "GPRINT:v12:MIN:\"          %7.2lf %SV\" GPRINT:v12:MAX:\"    %7.2lf %SV\" ";
$cmd .= "GPRINT:v12:AVERAGE:\"    %7.2lf %SV\"   GPRINT:v12:LAST:\"    %7.2lf %SV     \" ";
$cmd .= "LINE2:v12#009000:\"v12\" COMMENT:\"\\n\" ";
$cmd .= "COMMENT:\"          ----------------------------   $timestamp   -----------------------\\n\" ";

my $cmd2;
$cmd2 = "rrdtool graph $webdir/imgname -a PNG --start starttime --end stoptime -w $width -h $height ";
$cmd2 .= "DEF:tpPci=$datadir/$rrdFileTemperature:tpPci:AVERAGE     DEF:tpCore0=$datadir/$rrdFileTemperature:tpCore0:AVERAGE ";
$cmd2 .= "DEF:tpCore1=$datadir/$rrdFileTemperature:tpCore1:AVERAGE DEF:tpCpu=$datadir/$rrdFileTemperature:tpCpu:AVERAGE ";
$cmd2 .= "DEF:tpMb=$datadir/$rrdFileTemperature:tpMb:AVERAGE       DEF:tpGpu=$datadir/$rrdFileTemperature:tpGpu:AVERAGE ";

$cmd2 .= "COMMENT:\"              Min             Max             Avg             Last\\n\" ";
$cmd2 .= "GPRINT:tpPci:MIN:\"          %7.2lf %S°C\" GPRINT:tpPci:MAX:\"    %7.2lf %S°C\" ";
$cmd2 .= "GPRINT:tpPci:AVERAGE:\"    %7.2lf %S°C\"   GPRINT:tpPci:LAST:\"    %7.2lf %S°C     \" ";
$cmd2 .= "LINE2:tpPci#C00000:\"tp PCI\" COMMENT:\"\\n\" ";
$cmd2 .= "GPRINT:tpCore0:MIN:\"          %7.2lf %S°C\" GPRINT:tpCore0:MAX:\"    %7.2lf %S°C\" ";
$cmd2 .= "GPRINT:tpCore0:AVERAGE:\"    %7.2lf %S°C\"   GPRINT:tpCore0:LAST:\"    %7.2lf %S°C     \" ";
$cmd2 .= "LINE2:tpCore0#0173FF:\"tp Core 0\" COMMENT:\"\\n\" ";
$cmd2 .= "GPRINT:tpCore1:MIN:\"          %7.2lf %S°C\" GPRINT:tpCore1:MAX:\"    %7.2lf %S°C\" ";
$cmd2 .= "GPRINT:tpCore1:AVERAGE:\"    %7.2lf %S°C\"   GPRINT:tpCore1:LAST:\"    %7.2lf %S°C     \" ";
$cmd2 .= "LINE2:tpCore1#FF8737:\"tp Core 1\" COMMENT:\"\\n\" ";
$cmd2 .= "GPRINT:tpCpu:MIN:\"          %7.2lf %S°C\" GPRINT:tpCpu:MAX:\"    %7.2lf %S°C\" ";
$cmd2 .= "GPRINT:tpCpu:AVERAGE:\"    %7.2lf %S°C\"   GPRINT:tpCpu:LAST:\"    %7.2lf %S°C     \" ";
$cmd2 .= "LINE2:tpCpu#009000:\"tp CPU\" COMMENT:\"\\n\" ";
$cmd2 .= "GPRINT:tpMb:MIN:\"          %7.2lf %S°C\" GPRINT:tpMb:MAX:\"    %7.2lf %S°C\" ";
$cmd2 .= "GPRINT:tpMb:AVERAGE:\"    %7.2lf %S°C\"   GPRINT:tpMb:LAST:\"    %7.2lf %S°C     \" ";
$cmd2 .= "LINE2:tpMb#80FF80:\"tp MB\" COMMENT:\"\\n\" ";
$cmd2 .= "GPRINT:tpGpu:MIN:\"          %7.2lf %S°C\" GPRINT:tpGpu:MAX:\"    %7.2lf %S°C\" ";
$cmd2 .= "GPRINT:tpGpu:AVERAGE:\"    %7.2lf %S°C\"   GPRINT:tpGpu:LAST:\"    %7.2lf %S°C     \" ";
$cmd2 .= "LINE2:tpGpu#FFC549:\"tp GPU\" COMMENT:\"\\n\" ";
$cmd2 .= "COMMENT:\"          ----------------------------   $timestamp   -----------------------\\n\" ";

# memTot:memFree:memBuf:memCache:swpTot:swpFree
$scripttime = 60 * int( ($scripttime + 5) / 60); # arrondi à la minute

my $imgNameBaseVoltage = 'voltage';
my $imgNameBaseTemperature = 'temperature';
my $stoptime = $scripttime;
my $starttime = $stoptime - ($width - 1) * 60; # 1px / 1 min ; 480 min = 8h
my $imgname = "$imgNameBaseVoltage-1-hday.png";
$cmdp = $cmd;
$cmdp =~ s/starttime/$starttime/;
$cmdp =~ s/stoptime/$stoptime/;
$cmdp =~ s/imgname/$imgname/;
print `$cmdp`;
$imgname = "$imgNameBaseTemperature-1-hday.png";
$cmdp = $cmd2;
$cmdp =~ s/starttime/$starttime/;
$cmdp =~ s/stoptime/$stoptime/;
$cmdp =~ s/imgname/$imgname/;
print `$cmdp`;

if (($min % 5)!=0) # 5 min
{
  exit;
}

$imgname = "$imgNameBaseVoltage-2-2day.png";
$starttime = $stoptime - ($width - 1) * 300; # 1px / 5 min ; 480x5 min = 40h
$cmdp = $cmd;
$cmdp =~ s/starttime/$starttime/;
$cmdp =~ s/stoptime/$stoptime/;
$cmdp =~ s/imgname/$imgname/;
print `$cmdp`;
$imgname = "$imgNameBaseTemperature-2-2day.png";
$cmdp = $cmd2;
$cmdp =~ s/starttime/$starttime/;
$cmdp =~ s/stoptime/$stoptime/;
$cmdp =~ s/imgname/$imgname/;
print `$cmdp`;

if (($min % 30)!=0) # 30 min
{
  exit;
}

$imgname = "$imgNameBaseVoltage-3-week.png";
$starttime = $stoptime - ($width - 1) * 1800; # 1px / 30 min ; 480x30 min = 240h = 10 jours
$cmdp = $cmd;
$cmdp =~ s/starttime/$starttime/;
$cmdp =~ s/stoptime/$stoptime/;
$cmdp =~ s/imgname/$imgname/;
print `$cmdp`;
$imgname = "$imgNameBaseTemperature-3-week.png";
$cmdp = $cmd2;
$cmdp =~ s/starttime/$starttime/;
$cmdp =~ s/stoptime/$stoptime/;
$cmdp =~ s/imgname/$imgname/;
print `$cmdp`;

if (($hour % 2)!=0 || $min!=0) # 2 heures
{
  exit;
}

$imgname = "$imgNameBaseVoltage-4-month.png";
$starttime = $stoptime - ($width - 1) * 7200; # 1px / 2h ; 480x2h = 40 jours
$cmdp = $cmd;
$cmdp =~ s/starttime/$starttime/;
$cmdp =~ s/stoptime/$stoptime/;
$cmdp =~ s/imgname/$imgname/;
print `$cmdp`;
$imgname = "$imgNameBaseTemperature-4-month.png";
$cmdp = $cmd2;
$cmdp =~ s/starttime/$starttime/;
$cmdp =~ s/stoptime/$stoptime/;
$cmdp =~ s/imgname/$imgname/;
print `$cmdp`;

if ($hour!=0) # 1 jour
{
  exit;
}

$imgname = "$imgNameBaseVoltage-5-year.png";
$starttime = $stoptime - ($width - 1) * 86400; # 1px / 1 jour ; 480 jours = 1.3 ans
$cmdp = $cmd;
$cmdp =~ s/starttime/$starttime/;
$cmdp =~ s/stoptime/$stoptime/;
$cmdp =~ s/imgname/$imgname/;
print `$cmdp`;
$imgname = "$imgNameBaseTemperature-5-year.png";
$cmdp = $cmd2;
$cmdp =~ s/starttime/$starttime/;
$cmdp =~ s/stoptime/$stoptime/;
$cmdp =~ s/imgname/$imgname/;
print `$cmdp`;


