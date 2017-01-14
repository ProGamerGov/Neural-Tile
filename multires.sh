
th neural_style.lua \
  -content_image \
  -style_image \
  -image_size 640 \
  -output_image out1.png \
   [Put Your Command Paramters Here] 

th neural_style.lua \
  -content_image \
  -style_image \
  -init image -init_image out1.png \
  [Put Your Command Paramters Here] \
  -output_image out2.png \
  -image_size 768 \
  -num_iterations 500 \
 
th neural_style.lua \
  -content_image \
  -style_image \
  -init image -init_image out2.png \
  [Put Your Command Paramters Here] \
  -image_size 1024 \
  -num_iterations 200 \
  -output_image out3.png \

th neural_style.lua \
  -content_image \
  -style_image \
  -init image -init_image out3.png \
  [Put Your Command Paramters Here] \
  -image_size 1152 \
  -num_iterations 200 \
  -output_image out4.png \

th neural_style.lua \
  -content_image \
  -style_image \
  -init image -init_image out4.png \
  [Put Your Command Paramters Here] \
  -image_size 1536 \
  -num_iterations 200 \
  -output_image out5.png \

th neural_style.lua \
  -content_image \
  -style_image \
  -init image -init_image out5.png \
  [Put Your Command Paramters Here] \
  -image_size 1664 \
  -num_iterations 200 \
  -output_image out6.png \


th neural_style.lua \
  -content_image \
  -style_image \
  -init image -init_image out6.png \
 [Put Your Command Paramters Here] \
  -image_size 1920 \
  -num_iterations 100 \
  -output_image out7.png 
