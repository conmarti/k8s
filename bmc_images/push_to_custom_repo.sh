#!/bin/bash
#Source repo details containers.bmc.com
SOURCE_REGISTRY_HOST="containers.bmc.com"
SOURCE_REGISTRY_USER="xxx"
SOURCE_REGISTRY_PASSWORD="7da19a80-71d9-43fc-b717-2571a8a76521"

#Target repo details
IMAGE_REGISTRY_HOST="mtr.devops.telekom.de"
IMAGE_REGISTRY_USERNAME="internal_wom+write"
IMAGE_REGISTRY_PASSWORD="NN0KMEIGH8TDUUSBBSJJGCLZ1NBNRTXP1T6640WLUJOJM5Q2MDSEGIAMQSPP8XB5"
IMAGE_REGISTRY_PROJECT="internal_wom/systemteam/bmc"
#IMAGE_REGISTRY_REPO=""
#if podman is used create a alias for docker
shopt -s expand_aliases
alias docker=nerdctl
docker login ${SOURCE_REGISTRY_HOST}  -u ${SOURCE_REGISTRY_USER} -p ${SOURCE_REGISTRY_PASSWORD}
[[ $? -ne 0 ]] && echo "please check credential for SOURCE_REGISTRY_HOST ${SOURCE_REGISTRY_HOST}" && exit 0
docker login ${IMAGE_REGISTRY_HOST}  -u ${IMAGE_REGISTRY_USERNAME} -p ${IMAGE_REGISTRY_PASSWORD}
[[ $? -ne 0 ]] && echo "please check credential for IMAGE_REGISTRY_HOST ${IMAGE_REGISTRY_HOST}" && exit 0
#set -x

rm -f error.log pull_skiped.txt push_skiped.txt

i_BACKGROUND_PROCESS_MAX_COUNT=1

append_pid_into_list_of_background_processes()
{
        if [ -n "$str_BACKGROUND_PROCESS_PIDS" ]
        then
                str_BACKGROUND_PROCESS_PIDS=`UNIX95=  ps -p "$str_BACKGROUND_PROCESS_PIDS,$1" -o pid | tail -n +2 | tr '\n' ','`
                str_BACKGROUND_PROCESS_PIDS=`echo "$str_BACKGROUND_PROCESS_PIDS" |sed -e 's/,$//' -e 's/^,//' -e 's/ //g'`
                if [ $i_BACKGROUND_PROCESS_MAX_COUNT -ne 0 ]
                then
                        wait_for_find_processes_to_exit `expr $i_BACKGROUND_PROCESS_MAX_COUNT`
                fi
        else
                str_BACKGROUND_PROCESS_PIDS="$1"
        fi
}

wait_for_find_processes_to_exit ()
{
        if [ -z "$1" ]
        then
                i_PROC_COUNT=1
        else
                i_PROC_COUNT="$1"
        fi
        if [ -n "$str_BACKGROUND_PROCESS_PIDS" ]
        then
                while [ `UNIX95=  ps -p "$str_BACKGROUND_PROCESS_PIDS" | grep -v defunct | wc -l` -gt "$i_PROC_COUNT" ]
                do
                        echo "===========================================waiting on $str_BACKGROUND_PROCESS_PIDS"
                        sleep 3
                done
        fi
}

IFS=$'\n'
for EACH_LINE in $(cat all_images.txt)
do
        ./dtr_pull_push.sh  "$EACH_LINE" "${IMAGE_REGISTRY_HOST}" "${IMAGE_REGISTRY_PROJECT}" &
                append_pid_into_list_of_background_processes "$!"
        echo "===========================================IMAGE=$EACH_LINE---starting on pids $str_BACKGROUND_PROCESS_PIDS"

done
wait_for_find_processes_to_exit
echo "===========================================done"
#docker logout ${SOURCE_REGISTRY_HOST}
#docker logout ${IMAGE_REGISTRY_HOST}
