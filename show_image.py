#!/usr/bin/python3
## Project      : EE4DSH Practical Work
## Author       : Dr. John Williams
## Copyright    : 2020--2022 Aston University

"""Python Script to vga display output data from VHDL simulations 
as an image.

Usage: show-image.py <filename>
"""

import numpy as np
import sys
import matplotlib.pyplot as plt

size=(480,640,3) #Must match VGA dimensions
#size=(10,10,3) #Must match VGA dimensions

img=np.empty(size,np.uint8)
infile=open(sys.argv[-1],'r')

for y in range(0,size[0]):
    for x in range(0,size[1]):
        delta=int(infile.readline());
        if delta==255:
            r=0; g=0; b=0;
        elif (delta % 2)==0:
            r=0x1f; g=0x1f; b=0x9f;
        else:
            r=0xdf; g=0xdf; b=0x1f;
        r= 255 - delta;
        g = 255 - delta;
        b = delta / 2;
        img[y,x,0]=r;
        img[y,x,1]=g;
        img[y,x,2]=b;
            
infile.close()
plt.figure()
plt.axis('off')
plt.imshow(img,aspect='equal')
plt.show()
