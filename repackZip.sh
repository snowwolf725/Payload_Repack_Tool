#!/bin/bash

zip output/target-file.zip IMAGES/* META/* SYSTEM/*
./bin/ota_from_target_files.py output/target-file.zip output/OTA.zip