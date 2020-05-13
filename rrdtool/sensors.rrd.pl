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


my $datadir = '/home/piter/rrdtool';
my $webdir = '/var/www/rrd';
my $rrdFileTemperature = 'dataTemperature.rrd';
my $rrdFileFan = 'dataFan.rrd';
my $scripttime = time;

# Sample output from sensors:
# $ sensors
# coretemp-isa-0000
# Adapter: ISA adapter
# Package id 0:  +78.0°C  (high = +84.0°C, crit = +100.0°C)
# Core 0:        +76.0°C  (high = +84.0°C, crit = +100.0°C)
# Core 1:        +78.0°C  (high = +84.0°C, crit = +100.0°C)
#
# dell_smm-virtual-0
# Adapter: Virtual device
# Processor Fan: 4004 RPM
# CPU:            +78.0°C
# Ambient:        +61.0°C
# SODIMM:         +40.0°C
# GPU:            +60.0°C



my @sensors = `sensors`;
#my ($temp1, $tpCpu, $tpCore0, $tpCore1, $tpCore2, $tpCore3) = ('U', 'U', 'U', 'U', 'U', 'U');
my ($temp1, $tpCpu, $tpCore0, $tpCore1) = ('U', 'U', 'U', 'U');
my ($fan1, $fan2) = ('U', 'U');
#my ($tpDiska, $tpDiskb, $tpDiskc) = ('U', 'U', 'U');
my ($tpDiska) = ('U');

my $cmd;
foreach my $line (@sensors)
{
  if($line =~ m/Ambient:\s+([\+\d\.]+).+C/)
  {
    $temp1 = $1;
  }
  elsif($line =~ m/Package id 0:\s+([\+\d\.]+).+C/)
  {
    $tpCpu = $1;
  }
  elsif($line =~ m/Core 0:\s+([\+\d\.]+).+C/)
  {
    $tpCore0 = $1;
  }
  elsif($line =~ m/Core 1:\s+([\+\d\.]+).+C/)
  {
    $tpCore1 = $1;
  }
  #elsif($line =~ m/Core 2:\s+([\+\d\.]+).+C/)
  #{
  #  $tpCore2 = $1;
  #}
  #elsif($line =~ m/Core 3:\s+([\+\d\.]+).+C/)
  #{
  #  $tpCore3 = $1;
  #}
  elsif($line =~ m/Processor Fan:\s+([\+\d\.]+).+RPM/)
  {
    # Processor Fan: 3806 RPM
    $fan1 = $1;
  }
  #else
  #{
  #  print $line;
  #}
}

# Disk temprature from smartmontools data saved to temps file in /dev/shm/disk-sda-smart.txt
# Sample content: 
# 194 Temperature_Celsius     0x0022   116   113   000    Old_age   Always       -       34
# 190 Airflow_Temperature_Cel 0x0022   061   048   045    Old_age   Always       -       39 (Min/Max 35/39)
my $diskData = `cat /dev/shm/disk-sda-smart.txt`;
if($diskData =~ m/^\s*\d+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+(\d+)\s/)
{
  #print "Disk a: $1 \n'$diskData'\n";
  $tpDiska = $1;
}

#print "temperature $temp1, $tpCpu, $tpCore0, $tpCore1, $tpCore2, $tpCore3\n";
#$cmd = "rrdtool update $datadir/$rrdFileTemperature $scripttime:$temp1:$tpCpu:$tpCore0:$tpCore1:$tpCore2:$tpCore3:$tpDiska:$tpDiskb:$tpDiskc \n";
print "sensor temperature $temp1, $tpCpu, $tpCore0, $tpCore1, $tpDiska\n";
$cmd = "rrdtool update $datadir/$rrdFileTemperature $scripttime:$temp1:$tpCpu:$tpCore0:$tpCore1:$tpDiska \n";
print `$cmd`;

print "sensor fan $fan1, $fan2\n";
$cmd = "rrdtool update $datadir/$rrdFileFan $scripttime:$fan1:$fan2 \n";
print `$cmd`;


#my $width = 480;
my $width = 700;
my $height = 200;
my $cmdp;

#$sec, $min, $hour, $mday, $mon, $year
my ($sec, $min, $hour, $mday, $mon, $year) = localtime($scripttime);
my $timestamp = sprintf('%4d-%02d-%02d %02d\:%02d\:%02d', $year+1900, $mon+1, $mday, $hour, $min, $sec);


# Fan
$cmd = "rrdtool graph $webdir/imgname -a PNG --start starttime --end stoptime -w $width -h $height ";
$cmd .= "DEF:fan1=$datadir/$rrdFileFan:fan1:AVERAGE      DEF:fan2=$datadir/$rrdFileFan:fan2:AVERAGE ";
$cmd .= "DEF:fan1Min=$datadir/$rrdFileFan:fan1:MIN       DEF:fan2Min=$datadir/$rrdFileFan:fan2:MIN ";
$cmd .= "DEF:fan1Max=$datadir/$rrdFileFan:fan1:MAX       DEF:fan2Max=$datadir/$rrdFileFan:fan2:MAX ";
$cmd .= "COMMENT:\"              Min              Max              Avg              Last\\n\" ";
$cmd .= "GPRINT:fan1:AVERAGE:\"          %7.2lf %SRPM\" GPRINT:fan1Min:MIN:\"   %7.2lf %SRPM\" ";
$cmd .= "GPRINT:fan1Max:MAX:\"   %7.2lf %SRPM\"   GPRINT:fan1:LAST:\"   %7.2lf %SRPM    \" ";
$cmd .= "LINE2:fan1#C00000:\"temp 1\" COMMENT:\"\\n\" ";
$cmd .= "GPRINT:fan2:AVERAGE:\"          %7.2lf %SRPM\" GPRINT:fan2Min:MIN:\"   %7.2lf %SRPM\" ";
$cmd .= "GPRINT:fan2Max:MAX:\"   %7.2lf %SRPM\"   GPRINT:fan2:LAST:\"   %7.2lf %SRPM    \" ";
$cmd .= "LINE2:fan2#0173FF:\"tp Core 0\" COMMENT:\"\\n\" ";
$cmd .= "COMMENT:\"          ----------------------------   $timestamp   -----------------------\\n\" ";

# Temperatures
my $cmd2;
$cmd2 = "rrdtool graph $webdir/imgname -a PNG --start starttime --end stoptime -w $width -h $height ";
$cmd2 .= "DEF:temp1=$datadir/$rrdFileTemperature:temp1:AVERAGE      DEF:tpCpu=$datadir/$rrdFileTemperature:tpCpu:AVERAGE ";
$cmd2 .= "DEF:tpCore0=$datadir/$rrdFileTemperature:tpCore0:AVERAGE  DEF:tpCore1=$datadir/$rrdFileTemperature:tpCore1:AVERAGE ";
$cmd2 .= "DEF:temp1Min=$datadir/$rrdFileTemperature:temp1:MIN       DEF:tpCpuMin=$datadir/$rrdFileTemperature:tpCpu:MIN ";
$cmd2 .= "DEF:tpCore0Min=$datadir/$rrdFileTemperature:tpCore0:MIN   DEF:tpCore1Min=$datadir/$rrdFileTemperature:tpCore1:MIN ";
$cmd2 .= "DEF:temp1Max=$datadir/$rrdFileTemperature:temp1:MAX       DEF:tpCpuMax=$datadir/$rrdFileTemperature:tpCpu:MAX ";
$cmd2 .= "DEF:tpCore0Max=$datadir/$rrdFileTemperature:tpCore0:MAX   DEF:tpCore1Max=$datadir/$rrdFileTemperature:tpCore1:MAX ";
#$cmd2 .+ "DEF:tpCore2=$datadir/$rrdFileTemperature:tpCore2:AVERAGE  DEF:tpCore3=$datadir/$rrdFileTemperature:tpCore3:AVERAGE ";
#$cmd2 .+ "DEF:tpCore2Min=$datadir/$rrdFileTemperature:tpCore2:MIN  DEF:tpCore3Min=$datadir/$rrdFileTemperature:tpCore3:MIN ";
#$cmd2 .+ "DEF:tpCore2Max=$datadir/$rrdFileTemperature:tpCore2:MAX  DEF:tpCore3Max=$datadir/$rrdFileTemperature:tpCore3:MAX ";
$cmd2 .= "DEF:tpDiska=$datadir/$rrdFileTemperature:tpDiska:AVERAGE ";
$cmd2 .= "DEF:tpDiskaMin=$datadir/$rrdFileTemperature:tpDiska:MIN ";
$cmd2 .= "DEF:tpDiskaMax=$datadir/$rrdFileTemperature:tpDiska:MAX ";
#$cmd2 .= "DEF:tpDiskb=$datadir/$rrdFileTemperature:tpDiskb:AVERAGE  DEF:tpDiskc=$datadir/$rrdFileTemperature:tpDiskc:AVERAGE ";
#$cmd2 .= "DEF:tpDiskbMin=$datadir/$rrdFileTemperature:tpDiskb:MIN  DEF:tpDiskcMin=$datadir/$rrdFileTemperature:tpDiskc:MIN ";
#$cmd2 .= "DEF:tpDiskbMax=$datadir/$rrdFileTemperature:tpDiskb:MAX  DEF:tpDiskcMax=$datadir/$rrdFileTemperature:tpDiskc:MAX ";

$cmd2 .= "COMMENT:\"              Min              Max              Avg              Last\\n\" ";
$cmd2 .= "GPRINT:temp1:AVERAGE:\"          %7.2lf %S°C\" GPRINT:temp1Min:MIN:\"    %7.2lf %S°C\" ";
$cmd2 .= "GPRINT:temp1Max:MAX:\"    %7.2lf %S°C\"   GPRINT:temp1:LAST:\"    %7.2lf %S°C     \" ";
$cmd2 .= "LINE2:temp1#C00000:\"temp 1\" COMMENT:\"\\n\" ";
$cmd2 .= "GPRINT:tpCore0:AVERAGE:\"          %7.2lf %S°C\" GPRINT:tpCore0Min:MIN:\"    %7.2lf %S°C\" ";
$cmd2 .= "GPRINT:tpCore0Max:MAX:\"    %7.2lf %S°C\"   GPRINT:tpCore0:LAST:\"    %7.2lf %S°C     \" ";
$cmd2 .= "LINE2:tpCore0#0173FF:\"tp Core 0\" COMMENT:\"\\n\" ";
$cmd2 .= "GPRINT:tpCore1:AVERAGE:\"          %7.2lf %S°C\" GPRINT:tpCore1Min:MIN:\"    %7.2lf %S°C\" ";
$cmd2 .= "GPRINT:tpCore1Max:MAX:\"    %7.2lf %S°C\"   GPRINT:tpCore1:LAST:\"    %7.2lf %S°C     \" ";
$cmd2 .= "LINE2:tpCore1#FF8737:\"tp Core 1\" COMMENT:\"\\n\" ";
#$cmd2 .= "GPRINT:tpCore2:AVERAGE:\"          %7.2lf %S°C\" GPRINT:tpCore2Min:MIN:\"    %7.2lf %S°C\" ";
#$cmd2 .= "GPRINT:tpCore2Max:MAX:\"    %7.2lf %S°C\"   GPRINT:tpCore2:LAST:\"    %7.2lf %S°C     \" ";
#$cmd2 .= "LINE2:tpCore2#0173FF:\"tp Core 2\" COMMENT:\"\\n\" ";
#$cmd2 .= "GPRINT:tpCore3:AVERAGE:\"          %7.2lf %S°C\" GPRINT:tpCore3Min:MIN:\"    %7.2lf %S°C\" ";
#$cmd2 .= "GPRINT:tpCore3Max:MAX:\"    %7.2lf %S°C\"   GPRINT:tpCore3:LAST:\"    %7.2lf %S°C     \" ";
#$cmd2 .= "LINE2:tpCore3#FF8737:\"tp Core 3\" COMMENT:\"\\n\" ";
$cmd2 .= "GPRINT:tpCpu:AVERAGE:\"          %7.2lf %S°C\" GPRINT:tpCpuMin:MIN:\"    %7.2lf %S°C\" ";
$cmd2 .= "GPRINT:tpCpuMax:MAX:\"    %7.2lf %S°C\"   GPRINT:tpCpu:LAST:\"    %7.2lf %S°C     \" ";
$cmd2 .= "LINE2:tpCpu#009000:\"tp CPU\" COMMENT:\"\\n\" ";
$cmd2 .= "GPRINT:tpDiska:AVERAGE:\"          %7.2lf %S°C\" GPRINT:tpDiskaMin:MIN:\"    %7.2lf %S°C\" ";
$cmd2 .= "GPRINT:tpDiskaMax:MAX:\"    %7.2lf %S°C\"   GPRINT:tpDiska:LAST:\"    %7.2lf %S°C     \" ";
$cmd2 .= "LINE2:tpDiska#80FF80:\"tp sda\" COMMENT:\"\\n\" ";
#$cmd2 .= "GPRINT:tpDiskb:AVERAGE:\"          %7.2lf %S°C\" GPRINT:tpDiskbMin:MIN:\"    %7.2lf %S°C\" ";
#$cmd2 .= "GPRINT:tpDiskbMax:MAX:\"    %7.2lf %S°C\"   GPRINT:tpDiskb:LAST:\"    %7.2lf %S°C     \" ";
#$cmd2 .= "LINE2:tpDiskb#FFC549:\"tp sdb\" COMMENT:\"\\n\" ";
#$cmd2 .= "GPRINT:tpDiskc:AVERAGE:\"          %7.2lf %S°C\" GPRINT:tpDiskcMin:MIN:\"    %7.2lf %S°C\" ";
#$cmd2 .= "GPRINT:tpDiskcMax:MAX:\"    %7.2lf %S°C\"   GPRINT:tpDiskc:LAST:\"    %7.2lf %S°C     \" ";
#$cmd2 .= "LINE2:tpDiskc#FFC549:\"tp sdb\" COMMENT:\"\\n\" ";
$cmd2 .= "COMMENT:\"          ----------------------------   $timestamp   -----------------------\\n\" ";

# memTot:memFree:memBuf:memCache:swpTot:swpFree
$scripttime = 60 * int( ($scripttime + 5) / 60); # rouded to minute

my $imgNameBaseFan = 'fan';
my $imgNameBaseTemperature = 'temperature';
my $stoptime = $scripttime;
my $starttime = $stoptime - ($width - 1) * 60; # 1px / 1 min ; 480 min = 8h
my $imgname;

# Fan
$imgname = "$imgNameBaseFan-1-hday.png";
$cmdp = $cmd;
$cmdp =~ s/starttime/$starttime/;
$cmdp =~ s/stoptime/$stoptime/;
$cmdp =~ s/imgname/$imgname/;
print `$cmdp`;
# Temp
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

# Fan
$imgname = "$imgNameBaseFan-2-2day.png";
$cmdp = $cmd;
$cmdp =~ s/starttime/$starttime/;
$cmdp =~ s/stoptime/$stoptime/;
$cmdp =~ s/imgname/$imgname/;
print `$cmdp`;
# Temp
$starttime = $stoptime - ($width - 1) * 300; # 1px / 5 min ; 480x5 min = 40h
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

# Fan
$imgname = "$imgNameBaseFan-3-week.png";
$cmdp = $cmd;
$cmdp =~ s/starttime/$starttime/;
$cmdp =~ s/stoptime/$stoptime/;
$cmdp =~ s/imgname/$imgname/;
print `$cmdp`;
# Temp
$starttime = $stoptime - ($width - 1) * 1800; # 1px / 30 min ; 480x30 min = 240h = 10 jours
$imgname = "$imgNameBaseTemperature-3-week.png";
$cmdp = $cmd2;
$cmdp =~ s/starttime/$starttime/;
$cmdp =~ s/stoptime/$stoptime/;
$cmdp =~ s/imgname/$imgname/;
print `$cmdp`;

if (($hour % 2)!=0 || $min!=0) # 2 hour
{
  exit;
}

# Fan
$imgname = "$imgNameBaseFan-4-month.png";
$cmdp = $cmd;
$cmdp =~ s/starttime/$starttime/;
$cmdp =~ s/stoptime/$stoptime/;
$cmdp =~ s/imgname/$imgname/;
print `$cmdp`;
# Temp
$starttime = $stoptime - ($width - 1) * 7200; # 1px / 2h ; 480x2h = 40 jours
$imgname = "$imgNameBaseTemperature-4-month.png";
$cmdp = $cmd2;
$cmdp =~ s/starttime/$starttime/;
$cmdp =~ s/stoptime/$stoptime/;
$cmdp =~ s/imgname/$imgname/;
print `$cmdp`;

if ($hour!=0) # 1 day
{
  exit;
}

# Fan
$imgname = "$imgNameBaseFan-5-year.png";
$cmdp = $cmd;
$cmdp =~ s/starttime/$starttime/;
$cmdp =~ s/stoptime/$stoptime/;
$cmdp =~ s/imgname/$imgname/;
print `$cmdp`;
# Temp
$starttime = $stoptime - ($width - 1) * 86400; # 1px / 1 jour ; 480 jours = 1.3 ans
$imgname = "$imgNameBaseTemperature-5-year.png";
$cmdp = $cmd2;
$cmdp =~ s/starttime/$starttime/;
$cmdp =~ s/stoptime/$stoptime/;
$cmdp =~ s/imgname/$imgname/;
print `$cmdp`;


