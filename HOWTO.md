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

Steps to import Synty characters to godot, with mixamo animations
-----------------------------------------------------------------

### Step 1: prepare model in Blender

1. Start blender (tested with Blender 3.2.2), select all (A), delete all (X)
2. import the synty character fbx with the following options:
    - Manual orientation ticked (-Z forward, Y up)
    - Armature > Automatic bone orientation
3. switch to 'Pose mode', then Pose > Clear transform > all
4. export the blend file to fbx, with the following options:
    - Armature > Armature FBXNode Type > Root
    - untick Armature > Add leaf bones
    
### Step 2: get the mixamo animations

1. go to mixamo, and upload the fbx file you've just exported (don't worry about missing texture)
2. select a first animation, then click 'Download' with the following options:
    - Format: binary fbx
    - FPS: 60
    - Skin: with Skin
    - keyframe reduction: None
3. select the other animations you want, and download them as well, but *without the skin*

### Animation integration in Blender

1. re-open Blender, starting with an empty scene (select all and delete all)
2. import your first fbx file, using the default fbx import option
3. fix missing texture: 
    - select the mesh
    - select the tab 'Material properties'
    - click on 'Base color', then 'Image Texture'
    - navigate to the right synty png texture
    - then: File > External data > Automatically pack external data
4. rename the animation: in the outliner, click on Root > Animation and double-click the animation name (eg 'Root|mixamo.com|layer0') to rename it (eg 'dance')
5. import each additional animation by import the fbx file in the *same* Blender project. For each of them:
    - rename the animation
    - in the outliner, right click on the animation and select 'Add fake user'
    - delete the additional armature (eg delete 'Root.001')
6. save the file as a glTF2.0 file 

### Godot import

1. finally in Godot, import the .glb file by drag-dropping it
2. if you add the newly-imported object to the scene and open it ('Open in editor'), you'll see an AnimationPlayer node automatically created by Godot, with all your animations. 
