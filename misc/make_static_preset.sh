#!/bin/bash

preset_file="$1"
pragma_parameter_file="$2"
out_file2="$3"


temp_file=/tmp/slangp.temp
out_file=/tmp/out.slangp

OPWD="$PWD"

cd $(dirname "$preset_file")

cp "$preset_file" "$out_file"

while grep "#reference " "$out_file" ; do
    reference_file=$(grep "#reference " "$out_file" | cut -d \" -f 2)
    echo "found reference line to file: $reference_file"
    # strip reference line from working file
        grep -vi "#reference " "$out_file" > "$temp_file"
        mv "$temp_file" "$out_file"

    #don't append the main referenced .slangp, use keyword shader0 to match it
    if !(grep "shader0=\|shader0 =" "$reference_file") ; then
    #append reference file to working file
        echo "appending it..."
        cat "$reference_file" >> "$out_file"
    fi
done


echo Appending pragma parameters and values from "$pragma_parameter_file"...
cat "$pragma_parameter_file" |sed -e "s/[[:space:]]\+/ /g"|grep -vi "//#pragma\|// #pragma"|grep "#pragma parameter" | while read line ; do
    FIELD=$(echo $line | cut -d " " -f 3)
    VALUE=$(echo $line | cut -d '"' -f 3|cut -d " " -f 2)
    echo $FIELD = \"$VALUE\" >> "$out_file"
done


echo "#reference" '"'"$reference_file"'"' > $out_file2

echo Removing duplicate fields, get field from pragma parameters file
cat "$pragma_parameter_file" |sed -e "s/[[:space:]]\+/ /g"|grep -vi "//#pragma\|// #pragma"|grep "#pragma parameter" | while read line ; do
        FIELD=$(echo $line | cut -d " " -f 3)
        #take only the first field and append it to dest file
        grep "$FIELD =" $out_file | head -n 1 |sed -e "s/[[:space:]]\+/ /g" >> "$out_file2"
done

IFS=$'\n'

echo creating defines
for l in $(cat $out_file2 | tr -d "=") ; do
    echo '#define' $l | xargs
done


echo "made $out_file2"

cd $OPWD

