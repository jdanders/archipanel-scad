# Archipanels

Make system from: https://github.com/mofosyne/openscad-makefile

See https://www.printables.com/model/482128-archipanels-make-your-own-polyhedra.

* `make all` - Make all png previews and stl files
* `make clear` - Clear all build files

Tip:
* `make -j8 all` - Same as `make all` but runs up to 8 jobs at the same time, leading to faster compilation. This is called Parallel Execution as explained in [gnu make manual](https://www.gnu.org/software/make/manual/make.html#Parallel).

## Minimum support

This is intented to be used by windows users and linux users.

You need at least minimum:
* OpenSCAD installed
* makefile support
* Python 3.6 or higher

