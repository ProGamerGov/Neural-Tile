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
  #convert $input -resize 1000x1000 $out_file #juse resize
	
	w1=`convert $out_file -format "%w" info:`
	h1=`convert $out_file -format "%h" info:`
	
	# 3. tile it
	out_dir=$output/$clean_name
	mkdir -p $out_dir
	convert $out_file -crop 3x3+50+50@ +repage +adjoin $out_dir/$clean_name"_%d.png"
	#To change the crop values, change the +20+20 on line 35, and change the "20" on lines 77,78,99,100. Make sure to use the same value.
	
	# tile style
	#convert $style -crop 3x3+20+20@ +repage +adjoin $style_dir/$style_name"_%d.png"
	
	w2=`convert $out_dir/$clean_name'_0.png' -format "%w" info:`
	h2=`convert $out_dir/$clean_name'_0.png' -format "%h" info:`
	#w_percent=`echo 20 $w2 | awk '{print $1/$2}'`
	#h_percent=`echo 20 $h2 | awk '{print $1/$2}'`

	
	
	#Resize all tiles to avoid ImageMagick weirdness
	 convert $out_dir/$clean_name'_0.png' -resize "$w2"x"$h2"\! $out_dir/$clean_name'_0.png'
	 convert $out_dir/$clean_name'_1.png' -resize "$w2"x"$h2"\! $out_dir/$clean_name'_1.png'
	 convert $out_dir/$clean_name'_2.png' -resize "$w2"x"$h2"\! $out_dir/$clean_name'_2.png'
	 convert $out_dir/$clean_name'_3.png' -resize "$w2"x"$h2"\! $out_dir/$clean_name'_3.png'
	 convert $out_dir/$clean_name'_4.png' -resize "$w2"x"$h2"\! $out_dir/$clean_name'_4.png'
	 convert $out_dir/$clean_name'_5.png' -resize "$w2"x"$h2"\! $out_dir/$clean_name'_5.png'
	 convert $out_dir/$clean_name'_6.png' -resize "$w2"x"$h2"\! $out_dir/$clean_name'_6.png'
	 convert $out_dir/$clean_name'_7.png' -resize "$w2"x"$h2"\! $out_dir/$clean_name'_7.png'
	 convert $out_dir/$clean_name'_8.png' -resize "$w2"x"$h2"\! $out_dir/$clean_name'_8.png'	 					
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
	
	#Test	



	w2_2=`convert $tiles_dir/$clean_name'_0.png' -format "%w" info:`
	h2_2=`convert $tiles_dir/$clean_name'_0.png' -format "%h" info:`
	w_20=50
	h_20=50

	#w2_22="$w2"/"$w2_2"
	#h2_22="$h2"/"$h2_2"

	w2_22=`echo $w2 $w2_2 | awk '{print $1/$2}'`
	h2_22=`echo $h2 $h2_2 | awk '{print $1/$2}'`


	border_w_2=`echo $w2_22 $w_20 | awk '{print $1*$2}'`
	border_h_2=`echo $h2_22 $h_20 | awk '{print $1*$2}'`
	

	border_w=`echo $border_w_2 $w_20 | awk '{print $1+$2}'`
	border_h=`echo $border_h_2 $h_20 | awk '{print $1+$2}'`

	#border_w=`echo $w1 $w_percent | awk '{print $1*$2}'`
	#border_h=`echo $h1 $h_percent | awk '{print $1*$2}'`

	
	
	w_percent=`echo 50 $w2_2 | awk '{print $1/$2}'`
	h_percent=`echo 50 $h2_2 | awk '{print $1/$2}'`

	#Test

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
					$feathered_dir/$clean_name'_8.png'  -tile 3x3 -geometry -$border_w-$border_h -background none -debug trace $output/$clean_name.large_feathered.png
 # -$border_w-$border_h

	# 7. merge un-feathered tiles
	montage $tiles_dir/$clean_name'_0.png' $tiles_dir/$clean_name'_1.png' \
					$tiles_dir/$clean_name'_2.png' $tiles_dir/$clean_name'_3.png' \
					$tiles_dir/$clean_name'_4.png' $tiles_dir/$clean_name'_5.png' \
					$tiles_dir/$clean_name'_6.png' $tiles_dir/$clean_name'_7.png' \
					$tiles_dir/$clean_name'_8.png'  -tile 3x3 -geometry -$border_w-$border_h -background none -debug trace $output/$clean_name.large.png
			


	# 8. Combine feathered and un-feathered output images to disguise feathering.

	composite $output/$clean_name.large_feathered.png $output/$clean_name.large.png $output/$clean_name.large_final.png

}

retry=0
neural_style(){
	echo "Neural Style Transfering "$1
	if [ ! -s $3 ]; then
#####################################################################################
th neural_style.lua \ #Commands here
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
th neural_style.lua \ #Commands here
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
