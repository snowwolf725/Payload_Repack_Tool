# payload.bin repack tool

Using delta_generator to repack `payload.bin`.

### Requirements

- A compatible Linux system (x86_64/aarch64)
- git
- openjdk-jre
- python
- python-protobuf 
- zip
- unzip
- openssl
- openssl-tool
- xxd

### Linux X86-64 (Ubuntu)
```bash
sudo apt-get update 
sudo apt-get install git openssl openjdk-17-jre-headless python-protobuf python unzip zip
```

### Termux
```bash
pkg upgr
pkg install git openssl-tool zip unzip python openjdk-17 xxd
```

## Installation
```bash
git clone https://github.com/snowwolf725/Payload_Repack_Tool.git
cd Payload_Repack_Tool
pip install -r requirements.txt
```

## Usage

### repack `payload.bin`

```bash
cd Payload_Repack_Tool
#copy *.img into IMAGES folder
#cp -a *.img IMAGES
./repackPayload.sh
```

### repack `payload.bin` with dynamic partition info

```bash
cd Payload_Repack_Tool
#copy *.img into IMAGES folder
#cp -a *.img IMAGES
#modify META/dynamic_partitions_info.txt
#vi META/dynamic_partitions_info.txt
./repackPayload_withDpart.sh
```

### repack `OTA.zip`

```bash
cd Payload_Repack_Tool
#copy *.img into IMAGES folder
#cp -a *.img IMAGES
#modify META/*.txt SYSTEM/build.prop
#vi META/*.txt SYSTEM/build.prop
./repackZip.sh
```

## Demo
【Android payload.bin 打包-哔哩哔哩】 

https://b23.tv/W166gqz

## How to install a repackaged payload.bin
The payload.bin be signed by a private RSA key and the system will refuse to install it without the correct signature.
If you want to install a repacked payload.bin, you can use one of the following methods to install payload.bin.
### Method 1: TWRP (or other custom recovery)
### Method 2: Install Magisk module to replace system RSA key
Install [module-CustomOTA_CA.zip](https://github.com/snowwolf725/Payload_Repack_Tool/raw/refs/heads/main/module-CustomOTA_CA.zip) through the Magisk/KernelSU/APatch Manager App
