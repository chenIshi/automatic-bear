#!/bin/bash

# configure
probe_timeout_in_second=300
tunneler_public_address="101.201.234.77"
tunneler_fwd_ports=(1234 1237)
tunneler_dest_size=${#tunneler_fwd_ports[@]}

err_log_name="reverseSSH_log"

declare -A tunneler_pids

declare -i tunneler_failure_times
failure_anomlies_threshold=20

declare -i connection_retrial_times
connection_maximum_failure=20

# reset(kill) old reverse SSH sessions (excluded the "grepping" process)
# TODO: only reset specific reverse SSH sessions created by this script
kill $(ps aux | grep 'ssh -fCNR' | grep -v 'grep'| awk '{print $2}')

# init reverse SSH sessions
for dest in $(seq 0 $((${tunneler_dest_size}-1)))
do 
  ssh -fCNR ${tunneler_public_address}:${tunneler_fwd_ports[$dest]}:localhost:22 root@${tunneler_public_address} -o ServerAliveInterval=60 & 
  # record the tunneler pid for latter liveness check
  tunneler_pids[${dest}]=$!
done 

while true
do
  sleep ${probe_timeout_in_second}
  for idx in ${!tunneler_pids[@]}
  do 
    # check if the tunneler process still persists
    if ps -p ${tunneler_pids[${idx}]} > /dev/null
    then
      # reset connection trial count
      connection_retrial_times=0
      tunneler_failure_times=0
    else
      # retry for a limited times
      # TODO: a budget-based retrial scheme that notify 
      # network operators once run out of retrial budgets 
      # currently as a work-around, we can temporarily 
      # try once per probing interval, considering that 
      # ali-cloud server failure could last for a while 
      # (so that there is no point retrying within a probing interval) 
      
      # first using ping to check network connection
      if ping -q -c 1 -W 1 ${tunneler_public_address} > /dev/null
      then
        if [ ${connection_retrial_times} -lt ${connection_maximum_failure} ]
        then
          ssh -fCNR ${tunneler_public_address}:${tunneler_fwd_ports[$idx]}:localhost:22 root@${tunneler_public_address} -o ServerAliveInterval=60 & 
          # record the tunneler pid for latter liveness check
          tunneler_pids[${idx}]=$!
          tunneler_failure_times=0
          connection_retrial_times+=1
        else
          errDate=`date`
          echo "20 sequential reconnection trials failed at " ${errDate} 1> ${err_log_name}
          exit 1
        fi
      else
        # ali-cloud server network failure
        # TODO:accmulate the network failure and notify 
        # operators on successive failures
        tunneler_failure_times+=1
        if [ ${tunneler_failure_times} -gt ${failure_anomlies_threshold} ]
        then
          errDate=`date`
          echo "20 sequential connection failures at " ${errDate} 1> ${err_log_name}
          exit 1
        fi
      fi
    fi
  done
  
done
