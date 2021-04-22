#!/usr/bin/python3

import sys, getopt
import numpy as np
import bitstring

def binary(num):
    return bitstring.BitArray(float=num, length=32).bin

def dump_numpy(input, output):

    data = np.load(input).astype('uint8')

    f = open(output, "w")
    f.write("memory_initaialization_radix=2;\n") # specify we are writing in binary format
    f.write("memory_initialization_vector=")

    for id_image, image in enumerate(data):

        for id_row, row in enumerate(image):

            for pixel in row:
                f.write(str(pixel.item())) # directly write pixel value

            if not (id_row+1)%32 and id_row != 0: # we store 32 rows in every word in the buffer
                if id_image==11 and id_row==127: # last row so just finish .coe file
                    f.write(";")
                else: # new line on the image buffer
                    f.write(",\n")


def main(argv):
    input = ""
    output = ""

    try:
        opts, args = getopt.getopt(argv,"hi:o:",["input=","output="])
    except getopt.GetoptError:
        print ('test.py -i <inputfile> -o <outputfile>')
        sys.exit(2)

    for opt, arg in opts:
        if opt == '-h':
            print ('test.py -i <input_file> -o <output_file>')
            sys.exit()
        elif opt in ("-i", "--input"):
            input = arg
        elif opt in ("-o", "--output"):
            output = arg

    dump_numpy(input, output)

if __name__ == "__main__":
    main(sys.argv[1:])
