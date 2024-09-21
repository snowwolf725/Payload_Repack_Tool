# payload.bin repack tool

Using delta_generator to repack `payload.bin`.

### Requirements

- A compatible Linux system (x86_64/aarch64)
- git
- openssl
```bash
sudo apt-get install git openssl
```
- openssl-tool

```bash
pkg install git openssl-tool
```

## Installation
```bash
git clone https://github.com/snowwolf725/Payload_Repack_Tool.git
```

## Usage

### repack `payload.bin`

```bash
cd Payload_Repack_Tool
#copy *.img into images folder
#cp -a *.img images
./repack.sh
```

### repack `payload.bin` with dynamic partition info

```bash
cd Payload_Repack_Tool
#copy *.img into images folder
#cp -a *.img images
#modify dyn_part_info.txt
#vi dyn_part_info.txt
./repack_with_dpart.sh
```

## Demo
【Android payload.bin 打包-哔哩哔哩】 
https://b23.tv/W166gqz
