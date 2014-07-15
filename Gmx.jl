# Module for reading in xtc file with libxdrfile
module Gmx

import Xtc: xtc_init, read_xtc, close_xtc
import Ndx: read_ndx

export read_gmx

type gmxType
	no_configs
	time
	box
    x
 	natoms
end

type gmxGroup
	x
	natoms
end

#=  TODO: read in command line arguments (beginning, end, skip, xtc file).
    Also, be able to read in index file (how to do groups?)
=#

function save_xtc(gmx,conf,xtc)

    gmx.time[conf] = xtc.time[]
    gmx.box[:,:,conf] = xtc.box[:,:]
	gmx.x[:,:,conf] = xtc.x[:,:]

end

function save_xtc_ndx(gmx,conf,xtc,locs,group)

    gmx.time[conf] = xtc.time[]
    gmx.box[:,:,conf] = xtc.box[:,:]

	gmx.x[group][:,:,conf] = xtc.x[:,locs]

end


function read_gmx(xtc_file,first,last,ndx_file="0",group...)

    println("First frame to save: ", first)
    println("Last frame to save: ", last)
    no_configs = (last - first)

	(stat, xtc) = xtc_init(xtc_file)

	# if no index file is specified
	if ndx_file=="0"
  
	    gmx_tmp = gmxType(
	        last,
			Array(Float32,last),
			Array(Float32,(3,3,last)),
			Array(Float32,(3,int64(xtc.natoms),last)),
			xtc.natoms )
  
	# if an index file is specified
	else

		ndx_dict = read_ndx(ndx_file)
		natoms_dict = Dict()
		x_dict = Dict()

		no_groups = size(group,1)

		# Create dictionary containing number of atoms for each group
		for i in 1:no_groups
			natoms = size(ndx_dict[group[i]],1)
			natoms_dict[group[i]] = natoms
			x_dict[group[i]] = Array(Float32,(3,natoms,last))
		end

	    gmx_tmp = gmxType(
	        last,
	        Array(Float32,last),
	        Array(Float32,(3,3,last)),
			x_dict,
	        #Array(Float32,(3,size(ndx_dict[group[1]],1),last)),
		 	natoms_dict)

	end

    # Skip frames until we get to the first frame to read in
    for conf = 1:(first-1)

		(stat, xtc) = read_xtc(xtc)

        if stat != 0
			break
		end

    end

    # Read and save these frames
    for conf = first:last

		# TODO: add output counter
		(stat, xtc) = read_xtc(xtc)

        if stat != 0
            no_configs = (conf - first)
			break
		end
		
#	if ndx_file == "0"
#		save_xtc(gmx_tmp,conf,xtc)
#	else
			for grp in 1:no_groups
				save_xtc_ndx(gmx_tmp,conf,xtc,ndx_dict[group[grp]],group[grp])
			end
#	end

    end 

    println(string("Read in ", no_configs, " frames."))

    # Resize the arrays
	if ndx_file == "0"

		gmx = gmxType(
			no_configs,
			Array(Float32,no_configs),
			Array(Float32,(3,3,no_configs)),
			Array(Float32,(3,int64(xtc.natoms),no_configs)),
			xtc.natoms )

		gmx.no_configs = no_configs
	    gmx.time = gmx_tmp.time[1:no_configs]
		gmx.box = gmx_tmp.box[:,:,1:no_configs]

		gmx.x = gmx_tmp.x[:,:,1:no_configs]
		gmx.natoms = xtc.natoms

	else

		gmx = gmxType(
			no_configs,
			Array(Float32,no_configs),
			Array(Float32,(3,3,no_configs)),
			x_dict,
			natoms_dict )

		gmx.no_configs = no_configs
	    gmx.time = gmx_tmp.time[1:no_configs]
		gmx.box = gmx_tmp.box[:,:,1:no_configs]

		for i in group
			gmx.x[i] = gmx_tmp.x[i][:,:,1:no_configs]
		end
		gmx.natoms = gmx_tmp.natoms

	end
	
    return gmx

end

end
