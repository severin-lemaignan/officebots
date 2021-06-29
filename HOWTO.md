How To
======


Add new dynamic object
----------------------

DYnamic object = object that can move when colliding

0. Select and open `MainOffice.tscn`
1. select the mesh
2. create a `RigidBody` child
3. Drag the `RigidBody` outside of the mesh (eg re-parent the rigidbody to the
   parent of the mesh) and move the mesh as a child of the rigid body (doing
   these 2 steps ensure all the transformation are now correct)
4. create the collision mesh: select the mesh, then 'Create Single Convex
   Collision Sibling'
5. Rename the rigid body as appropriate, and move it to the `DynamicObstacles`
   parent
6. Attach the script `InteractiveObject.gd` to the rigid body


Add new pickable object
-----------------------

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

