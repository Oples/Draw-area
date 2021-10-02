#!/bin/bash
#==============================================================================#
#title           :draw_area.sh
#description     :Drawing area for graphics tablets on linux.
#author		 :Oples
#date            :20200504
#version         :0.0.1
#usage		 :bash draw_area.sh
#notes           :Make shure you have xinput and xrandr to run this script.
#bash_version    :5.0.3(1)-release
#license         :GNU GENERAL PUBLIC LICENSE v3.0
#==============================================================================#


# get the list of aviable(connected) displays as a single string
DISP_LST=$(xrandr | grep ' connected')

# declaration of variables
RES=""
i=0
MAIN_DISP=""
MAIN_DISP_NUM=0
DISP=()
DISP_DESC=()
param_inp_disp=-1
param_inp_pen=-1

while getopts 'd:p:h' OPTION; do
    case "$OPTION" in
        d)
            param_inp_disp=$OPTARG
            ;;
        p)
            param_inp_pen=$OPTARG
            ;;
        h)
            farg="$OPTARG"
            echo "Usage: $0 [-h] [-d display number] [-p pen number]" >&2
            exit 0
            ;;
        *)
            ;;
    esac
done

echo ""
# split the displays string in a list
while IFS=$'\n' read -ra ADDR; do
   # for i in "${ADDR[@]}"; do
       # process "$i"

   TMP=$(printf "$ADDR" | sed -e 's/ connected.*$//g')
   TMP_DESC=$(printf "$ADDR" | sed -e 's/^.*connected //g' -e 's/\+.*//g')
   if echo "$ADDR" | grep -q " primary"; then
      MAIN_DISP="$TMP"
      MAIN_DISP_NUM=$i
   fi
   DISP+=("$TMP")
   DISP_DESC+=("$TMP_DESC")

   # done
done <<< "$DISP_LST"


# iterate for every display
for i in ${!DISP[*]}
do
   # print all aviable displays
   printf "$i) ${DISP[$i]}    (${DISP_DESC[$i]})\n"
done


echo ""

# user input
# select the display you want the tablet to be restricted on
while true; do
    inp_num=-1
    if [[ param_inp_disp -ge 0 ]]; then
        inp_num=$param_inp_disp
    else
        read -p "Select the display [$MAIN_DISP_NUM]: " -i "$MAIN_DISP_NUM" inp_num
    fi
    case $inp_num in
        # only numbers are accepted
        [0123456789]* ) MAIN_DISP_NUM=$inp_num; MAIN_DISP=${DISP[$MAIN_DISP_NUM]}; break;;
        # no input, use default
        "" ) break;;
        # wrong input
        * ) echo "Please enter a number [0-9].";;
    esac
done




# get the list of aviable(connected) tablet/pen as a single string
HID_TABLET_OUT=$(xinput | grep -Ei "(pen|tablet)" | tr -cd "[:print:]\n" | tr -s ' ' | sed -e 's/\[.*\]$//g' | grep -P '[ a-zA-Z=0-9()]+' -o | sed -e 's/^ //g')

# declaration of variables
HID_TABLET=()
HID_ID=()
MAIN_HID_PEN=""
MAIN_HID_ID=0


echo ""
# split the displays string in a list
while IFS=$'\n' read -ra ADDR; do
   TMP_STR=$(printf "$ADDR" | sed -e "s/ id=[0-9]*//g")
   TMP_ID=$(printf "$ADDR" | grep -P '=[0-9]+$' -o | sed -e 's/^=//g')

   HID_TABLET+=("$TMP_STR")
   HID_ID+=("$TMP_ID")
done <<< "$HID_TABLET_OUT"


for i in ${!HID_TABLET[*]}
do
   printf "$i) ${HID_TABLET[$i]}   id=${HID_ID[$i]}\n"
done



# default is the first in the list
MAIN_HID_PEN=${HID_TABLET[0]};
MAIN_HID_ID=${HID_ID[0]};


echo ""
# user input
# select the Pen option if possible
while true; do
    inp_num=-1
    if [[ param_inp_pen -ge 0 ]]; then
        inp_num=$param_inp_pen
    else
        read -p "Select the Pen [0]: " -i "0" inp_num
    fi
    case $inp_num in
        [0123456789]* ) MAIN_HID_PEN=${HID_TABLET[$inp_num]}; MAIN_HID_ID=${HID_ID[$inp_num]}; break;;
        "" ) break;; # default
        * ) echo "Please enter a number [0-9].";;
    esac
done



# set the pen (drawing tablet area) to a specific screen
echo ""
echo "xinput map-to-output $MAIN_HID_ID $MAIN_DISP"
xinput map-to-output $MAIN_HID_ID $MAIN_DISP
