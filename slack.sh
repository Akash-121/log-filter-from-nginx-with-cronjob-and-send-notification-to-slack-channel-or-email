#!/bin/sh
newest=$(ls /mnt/sharedfolder_client/Log_result/ -Art | tail -n 0)
count=$(grep -o -c error /mnt/sharedfolder_client/Log_result/$newest)
sudo ./slack-upload.sh -f /mnt/sharedfolder_client/Log_result/$newest -c '#general' -s xoxp-xxxxxxxxxxx -x 'Total Error: '$count
