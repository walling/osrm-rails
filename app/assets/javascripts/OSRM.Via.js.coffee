# This program is free softwareyou can redistribute it and/or modify
# it under the terms of the GNU AFFERO General Public License as published by
# the Free Software Foundationeither version 3 of the License, or
# any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTYwithout even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with this programif not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
# or see http://www.gnu.org/licenses/agpl.txt.

# OSRM via marker routines
# [find correct position for a via marker]

# store location of via points returned by server
OSRM.GLOBALS.via_points = null


OSRM.Via =
		
# find route segment of current route geometry that is closest to the new via node (marked by index of its endpoint)
_findNearestRouteSegment: ( new_via ) ->
	min_dist = Number.MAX_VALUE
	min_index = undefined

	p = OSRM.G.map.latLngToLayerPoint( new_via )
	positions = OSRM.G.route.getPoints()
	for i in [1..positions.length-1]
		_sqDist = L.LineUtil._sqClosestPointOnSegment(p, positions[i-1], positions[i], true)
		if _sqDist < min_dist
			min_dist = _sqDist
			min_index = i
	
	return min_index
,


# find the correct index among all via nodes to insert the new via node, and insert it  
findViaIndex: ( new_via_position ) -> 
	# find route segment that is closest to click position (marked by last index)
	nearest_index = OSRM.Via._findNearestRouteSegment( new_via_position )

	# find correct index to insert new via node
	new_via_index = OSRM.G.via_points.length
	via_index = Array()
	for i in [0...OSRM.G.via_points.length]
		via_index[i] = OSRM.Via._findNearestRouteSegment( new L.LatLng(OSRM.G.via_points[i][0], OSRM.G.via_points[i][1]) )
		if via_index[i] > nearest_index
			new_via_index = i
			break

	# add via node
	return new_via_index
,


# function that draws a drag marker
dragTimer: new Date(),

drawDragMarker: (event) ->
	if OSRM.G.route.isShown() == false
		return
	if OSRM.G.dragging == true 
		return
	
	# throttle computation
	if (new Date() - OSRM.Via.dragTimer) < 25
		return
	OSRM.Via.dragTimer = new Date()
	
	# get distance to route
	minpoint = OSRM.G.route._current_route.route.closestLayerPoint( event.layerPoint )
	if minpoint
		min_dist =  minpoint._sqDist
	else
		min_dist = 1000
	
	# get distance to markers
	mouse = event.latlng
	for i in [0...OSRM.G.markers.route.length]
		if OSRM.G.markers.route[i].label=='drag'
			continue
		position = OSRM.G.markers.route[i].getPosition()
		dist = OSRM.G.map.project(mouse).distanceTo(OSRM.G.map.project(position))
		if dist < 20
			min_dist = 1000
		
	# check whether mouse is over another marker
	pos = OSRM.G.map.layerPointToContainerPoint(event.layerPoint)
	obj = document.elementFromPoint(pos.x,pos.y)
	for i in [0...OSRM.G.markers.route.length]
		if OSRM.G.markers.route[i].label=='drag'
			continue
		if obj == OSRM.G.markers.route[i].marker._icon
			min_dist = 1000
		
	# special care for highlight marker
	if OSRM.G.markers.highlight.isShown()
		if OSRM.G.map.project(mouse).distanceTo(OSRM.G.map.project( OSRM.G.markers.highlight.getPosition() ) ) < 20
			min_dist = 1000
		else if obj == OSRM.G.markers.highlight.marker._icon
			min_dist = 1000
	
	if min_dist < 400
		OSRM.G.markers.dragger.setPosition( OSRM.G.map.layerPointToLatLng(minpoint) )
		OSRM.G.markers.dragger.show()
	else
		OSRM.G.markers.dragger.hide()