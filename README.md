# payload.bin repack tool

Using delta_generator to repack `payload.bin`.

## Installation

### Requirements

- A compatible Linux system (x86_64/aarch64)
- openssl
```bash
sudo apt-get install openssl
```
- openssl-tool

```bash
pkg install openssl-tool
```

## Usage

### repack `payload.bin`

```bash
git clone https://github.com/snowwolf725/Payload_Repack_Tool.git
cd Payload_Repack_Tool
#copy *.img into images folder
#cp -a *.img images
./repack.sh
```
