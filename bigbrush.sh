#! /bin/bash


#1920/3=640 and Multries starts at 640. So multires tile size is good. 

# DEFINES
IMAGE_SIZE=1000 # -image_size for neural-style
ITERATIONS=250 # -num_iterations for neural-style
EXPAND_BORDER=20 # expanded border while cropping 

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
	mkdir -p $output
	out_file=$output/$input_file
	
	# 2. neural-style the original input
	if [ ! -s $out_file ] ; then
		neural_style $input $style $out_file
	fi
  #convert $input -resize 1000x1000 $out_file #juse resize
	
	# first output file size
	w1=`convert $out_file -format "%w" info:`
	h1=`convert $out_file -format "%h" info:`
	
	# 3. tile it
	out_dir=$output/$clean_name
	mkdir -p $out_dir
	convert $out_file -crop 3x3+$EXPAND_BORDER+$EXPAND_BORDER@ +repage +adjoin $out_dir/$clean_name"_%d.png"
	#To change the crop values, change the +20+20 on line 35, and change the "20" on lines 77,78,99,100. Make sure to use the same value.
	
	w2=`convert $out_dir/$clean_name'_0.png' -format "%w" info:`
	h2=`convert $out_dir/$clean_name'_0.png' -format "%h" info:`
	
	#Resize all tiles to avoid ImageMagick weirdness 					
	for outfile in `ls $out_dir | grep $clean_name"_"[0-9]".png"`
	do
		convert $out_dir/$outfile -resize "$w2"x"$h2"\! $out_dir/$outfile
	done

	# 4. neural-style each tile
	tiles_dir="$out_dir/tiles"
	mkdir -p $tiles_dir
	for tile in `ls $out_dir | grep $clean_name"_"[0-9]".png"`
	do
		neural_style_tiled $out_dir/$tile $style $tiles_dir/$tile
	done
	
	#Test	
	w2_2=`convert $tiles_dir/$clean_name'_0.png' -format "%w" info:`
	h2_2=`convert $tiles_dir/$clean_name'_0.png' -format "%h" info:`
	w_20=$EXPAND_BORDER
	h_20=$EXPAND_BORDER

	w2_22=`echo $w2 $w2_2 | awk '{print $1/$2}'`
	h2_22=`echo $h2 $h2_2 | awk '{print $1/$2}'`


	border_w_2=`echo $w2_22 $w_20 | awk '{print $1*$2}'`
	border_h_2=`echo $h2_22 $h_20 | awk '{print $1*$2}'`
	

	border_w=`echo $border_w_2 $w_20 | awk '{print $1+$2}'`
	border_h=`echo $border_h_2 $h_20 | awk '{print $1+$2}'`
	
	w_percent=`echo 20 $w2_2 | awk '{print $1/$2}'`
	h_percent=`echo 20 $h2_2 | awk '{print $1/$2}'`

	# 5. feather tiles
	feathered_dir=$out_dir/feathered
	mkdir -p $feathered_dir
	for tile in `ls $tiles_dir | grep $clean_name"_"[0-9]".png"`
	do
		tile_name="${tile%.*}"
		convert $tiles_dir/$tile -alpha set -virtual-pixel transparent -channel A -morphology Distance Euclidean:1,50\! +channel "$feathered_dir/$tile_name.png"
	done
	
	# 6. merge feathered tiles
	montage $feathered_dir/$clean_name'_0.png' $feathered_dir/$clean_name'_1.png' \
					$feathered_dir/$clean_name'_2.png' $feathered_dir/$clean_name'_3.png' \
					$feathered_dir/$clean_name'_4.png' $feathered_dir/$clean_name'_5.png' \
					$feathered_dir/$clean_name'_6.png' $feathered_dir/$clean_name'_7.png' \
					$feathered_dir/$clean_name'_8.png'  -tile 3x3 -geometry -$border_w-$border_h $output/$clean_name.large_feathered.png
 # -$border_w-$border_h

	# 7. merge un-feathered tiles
	montage $tiles_dir/$clean_name'_0.png' $tiles_dir/$clean_name'_1.png' \
					$tiles_dir/$clean_name'_2.png' $tiles_dir/$clean_name'_3.png' \
					$tiles_dir/$clean_name'_4.png' $tiles_dir/$clean_name'_5.png' \
					$tiles_dir/$clean_name'_6.png' $tiles_dir/$clean_name'_7.png' \
					$tiles_dir/$clean_name'_8.png'  -tile 3x3 -geometry -$border_w-$border_h $output/$clean_name.large.png

	# 8. Combine feathered and un-feathered output images to disguise feathering.
	composite $output/$clean_name.large_feathered.png $output/$clean_name.large.png $output/$clean_name.large_final.png

}

retry=0
neural_style(){
	echo "Neural Style Transfering "$1
	if [ ! -s $3 ]; then
		th neural_style.lua -content_image $1 -style_image $2 -output_image $3 \
				-image_size $IMAGE_SIZE -print_iter 100 -backend cudnn -gpu 0 -save_iter 0 \
				-style_weight 20 -num_iterations $ITERATIONS 
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
		th neural_style.lua -content_image $1 -style_image $2 -output_image $3 \
			-image_size $IMAGE_SIZE -print_iter 100 -backend cudnn -gpu 0 -save_iter 0 \
				-style_weight 20 -num_iterations $ITERATIONS 
	fi
	if [ ! -s $3 ] && [ $retry -lt 3 ] ;then
			echo "Transfer Failed, Retrying for $retry time(s)"
			retry=`echo 1 $retry | awk '{print $1+$2}'`
			neural_style_tiled $1 $2 $3
	fi
	retry=0
}

main $1 $2 $3

