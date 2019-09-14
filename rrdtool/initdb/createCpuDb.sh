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

rrdtool create dataCpu.rrd --step 60 --start $time \
  DS:user:COUNTER:600:0:2000 DS:priv:COUNTER:600:0:2000 \
  DS:idle:COUNTER:600:0:2000 \
  RRA:AVERAGE:0.5:1:1500 RRA:AVERAGE:0.5:5:700 \
  RRA:AVERAGE:0.5:30:700 RRA:AVERAGE:0.5:120:775 \
  RRA:AVERAGE:0.5:1440:797 RRA:MAX:0.5:1:1500 \
  RRA:MAX:0.5:5:700 RRA:MAX:0.5:30:700 \
  RRA:MAX:0.5:120:775 RRA:MAX:0.5:1440:797

