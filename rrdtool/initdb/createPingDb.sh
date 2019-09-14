#!/bin/bash
##############################################################################
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#
# Copyrigth Pierre-Jean DEVILLE  30/08/2005
##############################################################################

time=$(date +%s)

# memTot:memFree:memBuf:memCache:swpTot:swpFree
rrdtool create dataPing1.rrd --step 60 --start $time \
  DS:sent:GAUGE:600:U:U \
  DS:received:GAUGE:600:U:U \
  DS:lost:GAUGE:600:U:U \
  DS:rrtMin:GAUGE:600:U:U \
  DS:rrtAvg:GAUGE:600:U:U \
  DS:rrtMax:GAUGE:600:U:U \
  DS:rrtMdev:GAUGE:600:U:U \
  RRA:AVERAGE:0.5:1:1500 RRA:AVERAGE:0.5:5:700 \
  RRA:AVERAGE:0.5:30:700 RRA:AVERAGE:0.5:120:775 \
  RRA:AVERAGE:0.5:1440:797 \
  RRA:MAX:0.5:1:1500 \
  RRA:MAX:0.5:5:700 RRA:MAX:0.5:30:700 \
  RRA:MAX:0.5:120:775 RRA:MAX:0.5:1440:797 \
  RRA:MIN:0.5:1:1500 \
  RRA:MIN:0.5:5:700 RRA:MIN:0.5:30:700 \
  RRA:MIN:0.5:120:775 RRA:MIN:0.5:1440:797

