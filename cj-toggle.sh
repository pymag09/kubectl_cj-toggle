#!/usr/bin/bash

STATE_FILE=""
RESTORE=0
EXPLICIT_VAL=""
RED='\033[0;31m'
BLUE='\033[1;34m'
RST='\033[0m'

declare -A flip
flip["true"]=false
flip["false"]=true

usage_page(){
  cat <<EOF
Default behavior of $(basename $0) is inverting the 'spec.suspend' value of the cron job.
It is also possible to set 'spec.suspend' to True or False explicitly.
If you need to preserve previous state and revert it later, please use -f key. For example when some jobs are suspended, some are not.
Usage: $(basename $0)
    -A, --all-namespaces: If present, list the requested object(s) across all namespaces.
                          Namespace in current context is ignored even if specified with --namespace.
    -n, --namespace='':   If present, the namespace scope for this CLI request
    -h, --help:           This page
    -l, --selector='':    Selector (label query) to filter on, supports '=', '==', and '!='.(e.g. -l key1=value1,key2=value2)
    -r:                   Restore previous state from file. Works in conjunction with -f
    -f:                   Save current state to file.
    -s:                   Disable or enable cron job. Possible values [true|True|False|false].
EOF
exit 0
}

exit_with_error() {
  usage_page
  exit 1
}

data_source() {
    if [[ -f $STATE_FILE && $RESTORE == 1 ]]; then
      cat $STATE_FILE
    else
      kubectl get cronjob ${NAMESPACE:--n default} ${LABEL} -o custom-columns=':.metadata.namespace,:.metadata.name,:.spec.suspend'
    fi
}

while getopts ":n:f:s:l:-:Arh" args; do
  case "${args}" in
    -)
       case "${OPTARG}" in
         namespace)
             arg_value="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
             NAMESPACE="-n ${arg_value}"
             ;;
         namespace=*)
             arg_value=${OPTARG#*=}
             NAMESPACE="-n ${arg_value}"
             ;;
         selector)
             arg_value="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
             LABEL="-l ${arg_value}"
             ;;
         selector=*)
             arg_value=${OPTARG#*=}
             LABEL="-l ${arg_value}"
             ;;
         all-namespaces)
             NAMESPACE="-A"
             ;;
         help)
             usage_page
             ;;
       esac
       ;;
    A)
      NAMESPACE="-A"
      ;;
    s)
      EXPLICIT_VAL=$(echo ${OPTARG} | awk '{print tolower($0)}')
      if [[ $EXPLICIT_VAL -ne "false" || $EXPLICIT_VAL -ne "true" ]]; then
          echo -e "${RED}Warning!!!${RST} '${EXPLICIT_VAL}' is not allowed here. Possible values are [false|False|True|true]"
          exit 0
      fi
      ;;
    r)
      RESTORE=1
      ;;
    f)
      STATE_FILE=${OPTARG}
      ;;
    n)
      NAMESPACE="-n ${OPTARG}"
      ;;
    l)
      LABEL="-l ${OPTARG}"
      ;;
    h)
      usage_page
      ;;
    :)
      echo "Error: -${OPTARG} requires an argument."
      exit_with_error
      ;;
    *)
      exit_with_error
      ;;
  esac
done

if [[ $RESTORE -eq 1 && -z $STATE_FILE ]]; then
    echo -e "${RED}WARNING!!!${RST} Cannot proceed. -r requires -f option"
    exit 0
fi
if [[ $RESTORE -eq 1 && ! -f $STATE_FILE ]]; then
    echo -e "${RED}WARNING!!!${RST} Cannot proceed. ${STATE_FILE} does not exist."
    exit 0
fi

if [[ ! -f $STATE_FILE && ! -z $STATE_FILE ]]; then
    echo -e "${BLUE}Saving state:${RST}"
    kubectl get cronjob ${NAMESPACE:--n default} ${LABEL} -o custom-columns=':.metadata.namespace,:.metadata.name,:.spec.suspend' | sed '/^\s*$/d'| tee ${STATE_FILE}
    echo
fi
echo -e "${BLUE}Applying changes:${RST}"
while read cj; do
    if [[ -z $cj ]]; then continue; fi
    NS=$(echo $cj | awk '{print $1}')
    CJ=$(echo $cj | awk '{print $2}')
    SU=$(echo $cj | awk '{print $3}')
    if [[ $RESTORE -eq 1 ]]; then
        EXPLICIT_VAL=$(echo $cj | awk '{print $3}')
    fi
    invert_val=${flip[$SU]}
    kubectl -n ${NS} patch cronjob ${CJ} -p "{\"spec\" : {\"suspend\" : ${EXPLICIT_VAL:-$invert_val} }}";
done < <(data_source)
echo
echo -e "${BLUE}Current state:${RST}"
kubectl get cronjob ${NAMESPACE:--n default} ${LABEL} -o custom-columns=':.metadata.namespace,:.metadata.name,:.spec.suspend' | sed '/^\s*$/d'
echo