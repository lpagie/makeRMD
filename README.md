Development of a simple (?) wrapper for compiling Rmd documents from the
commandline.

Some requirements are:
* specify input, having different file extensions (Rmd, Rhtml, ...)
* specify outputdirectory for saving all (!) (intermediate) output
* specify output filename (plus path, which will place the outputfile somewhere else than outputdir)
* run the compiling with empty cache (ie rerun from scratch)
* automatically commit input and outputfiles to git??
