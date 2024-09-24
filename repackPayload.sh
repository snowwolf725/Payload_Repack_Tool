#!/bin/bash

arch=$(uname -m)

if [ "$arch" = "x86_64" ]; then
  echo "Platform: x86_64"
elif [ "$arch" = "aarch64" ]; then
  echo "Platform: arm64"
else
  echo "Platform: $arch"
  arch="x86-64"
fi

folder="IMAGES"

if [ ! -d "$folder" ]; then
  echo "Floder not found：$folder"
  exit 1
fi

name_list=$(find "$folder" -type f -exec basename {} \; | sed 's/\.[^.]*$//' | paste -sd ":" -)

file_list=$(find "$folder" -type f | paste -sd ":" -)

./bin/delta_generator_$arch -out_file=output/unsigned-payload.bin -partition_names=$name_list -new_partitions=$file_list

./bin/delta_generator_$arch --in_file=output/unsigned-payload.bin -signature_size=256 -out_metadata_hash_file=output/sig_metadata.bin -out_hash_file=output/sig_hash.bin

openssl pkeyutl -sign -inkey key/testkey.key -pkeyopt digest:sha256 -in output/sig_hash.bin -out output/signed_hash.bin

openssl pkeyutl -sign -inkey key/testkey.key -pkeyopt digest:sha256 -in output/sig_metadata.bin -out output/signed_metadata.bin

./bin/delta_generator_$arch --in_file=output/unsigned-payload.bin --out_file=output/payload.bin --signature_size=256 --metadata_signature_file=output/signed_metadata.bin --payload_signature_file=output/signed_hash.bin

./bin/delta_generator_$arch --in_file=output/payload.bin --properties_file=output/payload_properties.txt
