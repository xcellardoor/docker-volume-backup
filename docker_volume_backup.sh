#!/bin/bash

#compose_file_path=$1
project_name=${1,,}
backup_path=$2
backup_or_restore=$3
restore_date=$4

set -e

function backup_volume {
  volume_name=$1
  backup_destination=$2
  #date_suffix=$(date -I)
  date_suffix=$(date +%Y-%m-%d-%H-%M)

  docker run --rm -v $volume_name:/data -v $backup_destination:/backup ubuntu:latest tar -zcvpf /backup/$volume_name-$date_suffix.tar /data
}

function restore_volume {
  volume_name=$1
  backup_destination=$2
  date=$3

  docker run --rm -v $volume_name:/data ubuntu find /data -mindepth 1 -delete
  docker run --rm -v $volume_name:/data -v $backup_destination:/backup ubuntu tar --same-owner -xvf /backup/$volume_name-$date.tar -C .
}

function main {
#  echo "Stopping running containers"
#  docker-compose -f $compose_file_path -p $project_name stop

  echo "Mounting volumes and performing backup/restore..."
  volumes=($(docker volume ls -f name=$project_name | awk '{if (NR > 1) print $2}'))
  for v in "${volumes[@]}"
  do
    if [ "$backup_or_restore" == "backup" ]
    then
      echo "Perform backup"
      backup_volume $v $backup_path
    fi

    if [ "$backup_or_restore" == "restore" ]
    then
      echo "Restore from backup"
      restore_volume $v $backup_path $restore_date
    fi
  done

#  echo "Restarting containers"
#  docker-compose -f $compose_file_path -p $project_name start
}

main
