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
	
	# 2. neural-style the original input
	if [ ! -s $out_file ] ; then
		neural_style $input $style $out_file
	fi
	
	original_output_w=`convert $out_file -format "%w" info:`
	original_output_h=`convert $out_file -format "%h" info:`
	
	# 3. tile it
	out_dir=$output/$clean_name
	mkdir -p $out_dir
	convert $out_file -crop 3x3+50+50@ +repage +adjoin $out_dir/$clean_name"_%d.png"
	#To change the crop values, change the +20+20 on line 35, and change the "20" on lines 77,78,99,100. Make sure to use the same value.
	
	original_tile_w=`convert $out_dir/$clean_name'_0.png' -format "%w" info:`
	original_tile_h=`convert $out_dir/$clean_name'_0.png' -format "%h" info:`

	
	
	 #Resize all tiles to avoid ImageMagick weirdness
	 convert $out_dir/$clean_name'_0.png' -resize "$original_tile_w"x"$original_tile_h"\! $out_dir/$clean_name'_0.png' 
	 convert $out_dir/$clean_name'_1.png' -resize "$original_tile_w"x"$original_tile_h"\! $out_dir/$clean_name'_1.png'
	 convert $out_dir/$clean_name'_2.png' -resize "$original_tile_w"x"$original_tile_h"\! $out_dir/$clean_name'_2.png'
	 convert $out_dir/$clean_name'_3.png' -resize "$original_tile_w"x"$original_tile_h"\! $out_dir/$clean_name'_3.png'
	 convert $out_dir/$clean_name'_4.png' -resize "$original_tile_w"x"$original_tile_h"\! $out_dir/$clean_name'_4.png'
	 convert $out_dir/$clean_name'_5.png' -resize "$original_tile_w"x"$original_tile_h"\! $out_dir/$clean_name'_5.png'
	 convert $out_dir/$clean_name'_6.png' -resize "$original_tile_w"x"$original_tile_h"\! $out_dir/$clean_name'_6.png'
	 convert $out_dir/$clean_name'_7.png' -resize "$original_tile_w"x"$original_tile_h"\! $out_dir/$clean_name'_7.png'
	 convert $out_dir/$clean_name'_8.png' -resize "$original_tile_w"x"$original_tile_h"\! $out_dir/$clean_name'_8.png'	 					
					#WxH				

	# 4. neural-style each tile
	tiles_dir="$out_dir/tiles"
	mkdir -p $tiles_dir
	for tile in `ls $out_dir | grep $clean_name"_"[0-9]".png"`
	do
		#for i in $( seq 0 8 ); do
		#	neural_style $out_dir/$clean_name"_$i.png" $style_dir/$style_name"_$i.png" $tiles_dir/$clean_name"_$i.png"
		#done
		neural_style_tiled $out_dir/$tile $style $tiles_dir/$tile
	done
	
	#Perform the required mathematical operations:	

	upres_tile_w=`convert $tiles_dir/$clean_name'_0.png' -format "%w" info:`
	upres_tile_h=`convert $tiles_dir/$clean_name'_0.png' -format "%h" info:`

	overlap_w=50
	overlap_h=50
	
	tile_diff_w=`echo $upres_tile_w $original_tile_w | awk '{print $1/$2}'`
	tile_diff_h=`echo $upres_tile_h $original_tile_h | awk '{print $1/$2}'`

	smush_value_w=`echo $overlap_w $tile_diff_w | awk '{print $1*$2}'`
	smush_value_h=`echo $overlap_h $tile_diff_h | awk '{print $1*$2}'`
	

	# 5. feather tiles
	feathered_dir=$out_dir/feathered
	mkdir -p $feathered_dir
	for tile in `ls $tiles_dir | grep $clean_name"_"[0-9]".png"`
	do
		tile_name="${tile%.*}"
		convert $tiles_dir/$tile -alpha set -virtual-pixel transparent -channel A -morphology Distance Euclidean:1,50\! +channel "$feathered_dir/$tile_name.png"
	done
	
	# 7. Smush the feathered tiles together

	convert -background transparent \( $feathered_dir/$clean_name'_0.png' $feathered_dir/$clean_name'_1.png' $feathered_dir/$clean_name'_2.png' +smush -$smush_value_w -background transparent \) \
		\( $feathered_dir/$clean_name'_3.png' $feathered_dir/$clean_name'_4.png' $feathered_dir/$clean_name'_5.png' +smush -$smush_value_w -background transparent \) \
		\( $feathered_dir/$clean_name'_6.png' $feathered_dir/$clean_name'_7.png' $feathered_dir/$clean_name'_8.png' +smush -$smush_value_w -background transparent \) \
		-background none  -background transparent -smush -$smush_value_h  $output/$clean_name.large_feathered.png

	# 8. Smush the non-feathered tiles together

	convert \( $tiles_dir/$clean_name'_0.png' $tiles_dir/$clean_name'_1.png' $tiles_dir/$clean_name'_2.png' +smush -$smush_value_w \) \
		\( $tiles_dir/$clean_name'_3.png' $tiles_dir/$clean_name'_4.png' $tiles_dir/$clean_name'_5.png' +smush -$smush_value_w \) \
		\( $tiles_dir/$clean_name'_6.png' $tiles_dir/$clean_name'_7.png' $tiles_dir/$clean_name'_8.png' +smush -$smush_value_w \) \
		-background none -smush -$smush_value_h  $output/$clean_name.large.png

			


	# 8. Combine feathered and un-feathered output images to disguise feathering.

	composite $output/$clean_name.large_feathered.png $output/$clean_name.large.png $output/$clean_name.large_final.png

}

retry=0
neural_style(){
	echo "Neural Style Transfering "$1
	if [ ! -s $3 ]; then
#####################################################################################
th neural_style.lua \
  -content_image $1 \
  -style_image $2 \
  -image_size 640 \
  -output_image out1.png \
  -num_iterations 100 \
  
th neural_style.lua \
  -content_image $1 \
  -style_image $2 \
  -init image -init_image out1.png \
  -output_image $3 \
  -image_size 768 \
  -num_iterations 50 \
#####################################################################################
	fi
	if [ ! -s $3 ] && [ $retry -lt 3 ] ;then
			echo "Transfer Failed, Retrying for $retry time(s)"
			retry=`echo 1 $retry | awk '{print $1+$2}'`
			neural_style $1 $2 $3
	fi
	retry=0
}


retry=0
neural_style_tiled(){
	echo "Neural Style Transfering "$1
	if [ ! -s $3 ]; then
#####################################################################################	

th neural_style.lua \
  -content_image $1 \
  -style_image $2 \
  -image_size 640 \
  -output_image out1.png \
  -num_iterations 100 \
  
th neural_style.lua \
  -content_image $1 \
  -style_image $2 \
  -init image -init_image out1.png \
  -output_image $3 \
  -image_size 768 \
  -num_iterations 50 
 
#####################################################################################
	fi
	if [ ! -s $3 ] && [ $retry -lt 3 ] ;then
			echo "Transfer Failed, Retrying for $retry time(s)"
			retry=`echo 1 $retry | awk '{print $1+$2}'`
			neural_style_tiled $1 $2 $3
	fi
	retry=0
}

main $1 $2 $3
