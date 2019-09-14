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
# Copyrigth Pierre-Jean DEVILLE  2011-02-13
##############################################################################

time=$(date +%s)

rrdtool create dataDiskIo.rrd --step 60 --start $time \
  DS:Reads1:COUNTER:600:0:3000   DS:Writes1:COUNTER:600:0:3000  \
  DS:ReadBytes1:COUNTER:600:0:U  DS:WriteBytes1:COUNTER:600:0:U \
  DS:Reads2:COUNTER:600:0:3000   DS:Writes2:COUNTER:600:0:3000  \
  DS:ReadBytes2:COUNTER:600:0:U  DS:WriteBytes2:COUNTER:600:0:U \
  DS:Reads3:COUNTER:600:0:3000   DS:Writes3:COUNTER:600:0:3000  \
  DS:ReadBytes3:COUNTER:600:0:U  DS:WriteBytes3:COUNTER:600:0:U \
  RRA:AVERAGE:0.5:1:1500   RRA:AVERAGE:0.5:5:700    \
  RRA:AVERAGE:0.5:30:700   RRA:AVERAGE:0.5:120:775  \
  RRA:AVERAGE:0.5:1440:797  \
  RRA:MAX:0.5:1:1500       RRA:MAX:0.5:5:700        \
  RRA:MAX:0.5:30:700       RRA:MAX:0.5:120:775      \
  RRA:MAX:0.5:1440:797

