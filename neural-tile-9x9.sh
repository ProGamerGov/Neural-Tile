#! /bin/bash

# Check for output directory, and create it if missing
if [ ! -d "$output" ]; then
  mkdir output
fi


main(){
	# 1. Defines the content image as a variable
	input=$1
	input_file=`basename $input`
	clean_name="${input_file%.*}"
	
	#Defines the style image as a variable
	style=$2
	style_dir=`dirname $style`
	style_file=`basename $style`
	style_name="${style_file%.*}"
	
	#Defines the output directory
	output="./output"
	out_file=$output/$input_file
	
	#Defines the overlap
	overlap_w=50
	overlap_h=50
	
	# 2. Creates your original styled output. This step will be skipped if you place a previously styled image with the same name 
	# as your specified "content image", located in your Neural-Style/output/<Styled_Image> directory.
	if [ ! -s $out_file ] ; then
		time neural_style $input $style $out_file
	fi
	
	# 3. Chop the styled image into 9x9 tiles with the specified overlap value.
	out_dir=$output/$clean_name
	mkdir -p $out_dir
	convert $out_file +repage -crop 9x9+"$overlap_w"+"$overlap_h"@ +repage +adjoin $out_dir/$clean_name"_%d.png"
	
	#Finds out the length and width of the first tile as a refrence point for resizing the other tiles.
	original_tile_w=`convert $out_dir/$clean_name'_0.png' -format "%w" info:`
	original_tile_h=`convert $out_dir/$clean_name'_0.png' -format "%h" info:`
	
	 #Resize all tiles to avoid ImageMagick weirdness
	 mogrify -path $output/$clean_name/ -resize "$original_tile_w"x"$original_tile_h"\! $output/$clean_name/*.png
					#WxH				

	# 4. neural-style each tile
	echo Processing individual tiles...
	tiles_dir="$out_dir/tiles"
	mkdir -p $tiles_dir
	for tile in "${clean_name}_"{0..81}.png
	do
		neural_style_tiled $out_dir/$tile $style $tiles_dir/$tile
	done

	#Perform the required mathematical operations:	

	upres_tile_w=`convert $tiles_dir/$clean_name'_0.png' -format "%w" info:`
	upres_tile_h=`convert $tiles_dir/$clean_name'_0.png' -format "%h" info:`
	
	tile_diff_w=`echo $upres_tile_w $original_tile_w | awk '{print $1/$2}'`
	tile_diff_h=`echo $upres_tile_h $original_tile_h | awk '{print $1/$2}'`

	smush_value_w=`echo $overlap_w $tile_diff_w | awk '{print $1*$2}'`
	smush_value_h=`echo $overlap_h $tile_diff_h | awk '{print $1*$2}'`
	
	# 5. feather tiles
	echo Feathering tiles...
	feathered_dir=$out_dir/feathered
	mkdir -p $feathered_dir
	for tile in `ls $tiles_dir | grep $clean_name"_"[0-9][0-9]".png"`
	do
		tile_name="${tile%.*}"
		convert $tiles_dir/$tile -alpha set -virtual-pixel transparent -channel A -morphology Distance Euclidean:1,50\! +channel "$feathered_dir/$tile_name.png"
	done
	
	# 7. Smush the feathered tiles together
	echo Combining feathered tiles...
	convert -background transparent \( $feathered_dir/$clean_name'_0.png' $feathered_dir/$clean_name'_1.png' $feathered_dir/$clean_name'_2.png' $feathered_dir/$clean_name'_3.png' $feathered_dir/$clean_name'_4.png' $feathered_dir/$clean_name'_5.png' $feathered_dir/$clean_name'_6.png' $feathered_dir/$clean_name'_7.png' $feathered_dir/$clean_name'_8.png' +smush -$smush_value_w -background transparent \) \
			\( $feathered_dir/$clean_name'_9.png' $feathered_dir/$clean_name'_10.png' $feathered_dir/$clean_name'_11.png' $feathered_dir/$clean_name'_12.png' $feathered_dir/$clean_name'_13.png' $feathered_dir/$clean_name'_14.png' $feathered_dir/$clean_name'_15.png' $feathered_dir/$clean_name'_16.png' $feathered_dir/$clean_name'_17.png' +smush -$smush_value_w -background transparent \) \
			\( $feathered_dir/$clean_name'_18.png' $feathered_dir/$clean_name'_19.png' $feathered_dir/$clean_name'_20.png' $feathered_dir/$clean_name'_21.png' $feathered_dir/$clean_name'_22.png' $feathered_dir/$clean_name'_23.png' $feathered_dir/$clean_name'_24.png' $feathered_dir/$clean_name'_25.png' $feathered_dir/$clean_name'_26.png' +smush -$smush_value_w -background transparent \) \
			\( $feathered_dir/$clean_name'_27.png' $feathered_dir/$clean_name'_28.png' $feathered_dir/$clean_name'_29.png' $feathered_dir/$clean_name'_30.png' $feathered_dir/$clean_name'_31.png' $feathered_dir/$clean_name'_32.png' $feathered_dir/$clean_name'_33.png' $feathered_dir/$clean_name'_34.png' $feathered_dir/$clean_name'_35.png' +smush -$smush_value_w -background transparent \) \
			\( $feathered_dir/$clean_name'_36.png' $feathered_dir/$clean_name'_37.png' $feathered_dir/$clean_name'_38.png' $feathered_dir/$clean_name'_39.png' $feathered_dir/$clean_name'_40.png' $feathered_dir/$clean_name'_41.png' $feathered_dir/$clean_name'_42.png' $feathered_dir/$clean_name'_43.png' $feathered_dir/$clean_name'_44.png' +smush -$smush_value_w -background transparent \) \
			\( $feathered_dir/$clean_name'_45.png' $feathered_dir/$clean_name'_46.png' $feathered_dir/$clean_name'_47.png' $feathered_dir/$clean_name'_48.png' $feathered_dir/$clean_name'_49.png' $feathered_dir/$clean_name'_50.png' $feathered_dir/$clean_name'_51.png' $feathered_dir/$clean_name'_52.png' $feathered_dir/$clean_name'_53.png' +smush -$smush_value_w -background transparent \) \
			\( $feathered_dir/$clean_name'_54.png' $feathered_dir/$clean_name'_55.png' $feathered_dir/$clean_name'_56.png' $feathered_dir/$clean_name'_57.png' $feathered_dir/$clean_name'_58.png' $feathered_dir/$clean_name'_59.png' $feathered_dir/$clean_name'_60.png' $feathered_dir/$clean_name'_61.png' $feathered_dir/$clean_name'_62.png' +smush -$smush_value_w -background transparent \) \
			\( $feathered_dir/$clean_name'_63.png' $feathered_dir/$clean_name'_64.png' $feathered_dir/$clean_name'_65.png' $feathered_dir/$clean_name'_66.png' $feathered_dir/$clean_name'_67.png' $feathered_dir/$clean_name'_68.png' $feathered_dir/$clean_name'_69.png' $feathered_dir/$clean_name'_70.png' $feathered_dir/$clean_name'_71.png' +smush -$smush_value_w -background transparent \) \
			\( $feathered_dir/$clean_name'_72.png' $feathered_dir/$clean_name'_73.png' $feathered_dir/$clean_name'_74.png' $feathered_dir/$clean_name'_75.png' $feathered_dir/$clean_name'_76.png' $feathered_dir/$clean_name'_77.png' $feathered_dir/$clean_name'_78.png' $feathered_dir/$clean_name'_79.png' $feathered_dir/$clean_name'_80.png' +smush -$smush_value_w -background transparent \) \
			-background none  -background transparent -smush -$smush_value_h  $output/$clean_name.large_feathered.png

	# 8. Smush the non-feathered tiles together
	echo Combining non-feathered tiles...
	convert \( $tiles_dir/$clean_name'_0.png' $tiles_dir/$clean_name'_1.png' $tiles_dir/$clean_name'_2.png' $tiles_dir/$clean_name'_3.png' $tiles_dir/$clean_name'_4.png' $tiles_dir/$clean_name'_5.png' $tiles_dir/$clean_name'_6.png' $tiles_dir/$clean_name'_7.png' $tiles_dir/$clean_name'_8.png' +smush -$smush_value_w \) \
			\( $tiles_dir/$clean_name'_9.png' $tiles_dir/$clean_name'_10.png' $tiles_dir/$clean_name'_11.png' $tiles_dir/$clean_name'_12.png' $tiles_dir/$clean_name'_13.png' $tiles_dir/$clean_name'_14.png' $tiles_dir/$clean_name'_15.png' $tiles_dir/$clean_name'_16.png' $tiles_dir/$clean_name'_17.png' +smush -$smush_value_w \) \
			\( $tiles_dir/$clean_name'_18.png' $tiles_dir/$clean_name'_19.png' $tiles_dir/$clean_name'_20.png' $tiles_dir/$clean_name'_21.png' $tiles_dir/$clean_name'_22.png' $tiles_dir/$clean_name'_23.png' $tiles_dir/$clean_name'_24.png' $tiles_dir/$clean_name'_25.png' $tiles_dir/$clean_name'_26.png' +smush -$smush_value_w \) \
			\( $tiles_dir/$clean_name'_27.png' $tiles_dir/$clean_name'_28.png' $tiles_dir/$clean_name'_29.png' $tiles_dir/$clean_name'_30.png' $tiles_dir/$clean_name'_31.png' $tiles_dir/$clean_name'_32.png' $tiles_dir/$clean_name'_33.png' $tiles_dir/$clean_name'_34.png' $tiles_dir/$clean_name'_35.png' +smush -$smush_value_w \) \
			\( $tiles_dir/$clean_name'_36.png' $tiles_dir/$clean_name'_37.png' $tiles_dir/$clean_name'_38.png' $tiles_dir/$clean_name'_39.png' $tiles_dir/$clean_name'_40.png' $tiles_dir/$clean_name'_41.png' $tiles_dir/$clean_name'_42.png' $tiles_dir/$clean_name'_43.png' $tiles_dir/$clean_name'_44.png' +smush -$smush_value_w \) \
			\( $tiles_dir/$clean_name'_45.png' $tiles_dir/$clean_name'_46.png' $tiles_dir/$clean_name'_47.png' $tiles_dir/$clean_name'_48.png' $tiles_dir/$clean_name'_49.png' $tiles_dir/$clean_name'_50.png' $tiles_dir/$clean_name'_51.png' $tiles_dir/$clean_name'_52.png' $tiles_dir/$clean_name'_53.png' +smush -$smush_value_w \) \
			\( $tiles_dir/$clean_name'_54.png' $tiles_dir/$clean_name'_55.png' $tiles_dir/$clean_name'_56.png' $tiles_dir/$clean_name'_57.png' $tiles_dir/$clean_name'_58.png' $tiles_dir/$clean_name'_59.png' $tiles_dir/$clean_name'_60.png' $tiles_dir/$clean_name'_61.png' $tiles_dir/$clean_name'_62.png' +smush -$smush_value_w \) \
			\( $tiles_dir/$clean_name'_63.png' $tiles_dir/$clean_name'_64.png' $tiles_dir/$clean_name'_65.png' $tiles_dir/$clean_name'_66.png' $tiles_dir/$clean_name'_67.png' $tiles_dir/$clean_name'_68.png' $tiles_dir/$clean_name'_69.png' $tiles_dir/$clean_name'_70.png' $tiles_dir/$clean_name'_71.png' +smush -$smush_value_w \) \
			\( $tiles_dir/$clean_name'_72.png' $tiles_dir/$clean_name'_73.png' $tiles_dir/$clean_name'_74.png' $tiles_dir/$clean_name'_75.png' $tiles_dir/$clean_name'_76.png' $tiles_dir/$clean_name'_77.png' $tiles_dir/$clean_name'_78.png' $tiles_dir/$clean_name'_79.png' $tiles_dir/$clean_name'_80.png' +smush -$smush_value_w \) \
			-background none -smush -$smush_value_h  $output/$clean_name.large.png
			
	echo Creating final image...

	# 8. Combine feathered and un-feathered output images to disguise feathering.
	composite $output/$clean_name.large_feathered.png $output/$clean_name.large.png $output/$clean_name.large_final.png
	
	echo Finished
}

retry=0

#Runs the content image and style image through Neural-Style with your chosen parameters.
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
  -num_iterations 50 
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

#Runs the tiles through Neural-Style with your chosen parameters. 
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
