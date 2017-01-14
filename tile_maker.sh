
#! /bin/bash 

# Check for output directory, and create it if missing
if [ ! -d "$output" ]; then
  mkdir output
fi


main(){
	# 1. defines
	input=$1
	input_file=`basename $input`
	clean_name="${input_file%.*}"
	
	style=$2
	style_dir=`dirname $style`
	style_file=`basename $style`
	style_name="${style_file%.*}"
	
	output="./output"
	out_file=$output/$input_file

	cp $1 output/

	
	# 3. tile it
	out_dir=$output/$clean_name
	mkdir -p $out_dir
	convert $out_file -crop 3x3+50+50@ +repage +adjoin $out_dir/$clean_name"_%d.png"


	  mkdir output/$out_dir/feathered
          mkdir output/$out_dir/tiles
	


}

main $1 $2 $3
