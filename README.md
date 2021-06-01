# 3D printing models

## General printing instructions

All prints are designed for a fixed layer height of 0.15mm (see `layerHeight` in util.scad). It is important that the first layer also 0.15mm high (the default is larger in many slicers).

Elephant's foot compensation should be used for all parts as well.


## Instructions for generating stl files

All models are made with OpenSCAD. Run `make` in a subdirectory to build all the stl files for that model.


## 3D printed locks

Several 3d printed locks and related ideas.
These locks are all designed with anti-pick features

Finished:

* disclock: A disc detainer padlock, with a reverse sidebar.
* euro-twist: A standard euro cylinder lock, but with a twist. Designed to use standard pins and springs.
* lever-lock: A lever lock with a curtain that blocks access to the levers. Can not be picked with standard wires.

Mostly finished:

* splitlock: A lock with a split key, which is held together by magnets. The key pins are inaccessible from the outside.
* rotate-wafer-lock: A lock with both rotating discs and sliding wafers. The key shape makes it virtually impossible to access the rear wafers.
* waverlock: A waferlock with a very large bitting range. The back wafers can not be accessed with a straight pick.
* combination-lock: A combination padlock that can not be tensioned by pulling the shackle.
* button-combination-lock: A combination padlock with sliding buttons
* magnetic-disc-lock: A lock with magnetic discs, based on a commercially available lock.

Work in progress:

* combination-lock2: A combination padlock that locks in the combination before tensioning the lock

Other:

* tools: Locksport tools, such as pinning tweezers.


## Puzzles

Finished:

* puzzle1: A puzzle padlock, based on gravity

Work in progress:

* puzzle2: A puzzle padlock using a maze
* puzzle3: A puzzle padlock where bearing balls are moved around
* puzzle-frog: Make the frog into a princess. 
* puzzle-maze: A twisting maze puzzle

