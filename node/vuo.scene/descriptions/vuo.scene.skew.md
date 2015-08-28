Moves part of the object, while holding part of it steady.

This node moves some of the object's vertices toward one side.  The further above or below the ground (XZ) plane the vertices are, the more they are moved.

   - `amount` — The distance, in scene coordinates, to move the vertices at y=1 and y=-1.  Vertices closer to y=0 are moved less; vertices further out are moved more.
   - `direction` — The angle, in degrees about the Y axis, of the plane along which the vertices are moved.