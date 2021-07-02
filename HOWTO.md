How To
======


Add new interactive/pickable object
------------------------------------

0. Select and open `MainOffice.tscn`
1. select the mesh
2. reparent to `PickableObjects`
3. add a `InteractiveObject.tscn` child
4. clear the transforms of the `InteractiveObject`
5. Drag the `InteractiveObject` outside of the mesh and move the mesh as a child of the interactive object instance
6. create the collision mesh: select the mesh, then 'Create Single Convex
   Collision Sibling'
7. Tick 'Pickable' in the properties of the interactive object
7. Rename the interactive object as appropriate

