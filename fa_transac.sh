#!/bin/bash
#
##
## Followanalytics transactional pushes
## ------------------------------------
## 
## fa_transac.sh login USER -
##   login into FA SSO, retrieve your FA_TOKEN (password read from STDIN)
##
## fa_transac.sh csv2json CAMPAIGN_IDENTIFIER -
## fa_transac.sh csv2json CAMPAIGN_IDENTIFIER.csv
##   convert a CSV read from STDIN and CAMPAIGN_IDENTIFIER OR a csv named as campaign_identifier, to a ready to push json file
##   The CSV firsg line MUST be the varialbe key
##
## fa_transac.sh push TEMPLATE.JSON -
##   push transac messages defined in TEMPLATE.JSON to userId read from STDIN
##
## Note: commands needed in PATH: which, sed, curl


COMMAND="`echo $1 | tr '[:upper:]' '[:lower:]'`"

ARG2="`echo $2`"

CURL=`which curl`
SED=`which sed`

FA_API='https://api.follow-apps.com'
FA_LOGIN="$FA_API/api/login"

CAPTURE_TOKEN='s/^.*auth_token":"\([-_a-zA-Z0-9]*\).*$/\1/p'

function join_by { local IFS="$1"; shift; echo "$*"; }
function banner {
  echo "banner() / $0"
  echo "`grep -e '^##' $0 | sed -e s/##//g `"
}

function login_json {
  LOGIN_JSON="{\"email\": \"$FA_USER\", \"password\": \"$FA_PWD\"}"
  echo "$LOGIN_JSON"
}
function build_curl {
  JSON="`login_json`"
  echo "$CURL -s -H 'Accept: application/json' -H 'Content-Type: application/json' -d '$JSON' $FA_LOGIN | $SED -n '$CAPTURE_TOKEN'"
}

function csv2json {
  CAMPAIGN_IDENTIFIER="`echo $ARG2`"
  if [ -f $CAMPAIGN_IDENTIFIER ]; then
    CSVFILE=$CAMPAIGN_IDENTIFIER
    CAMPAIGN_IDENTIFIER=`echo $CAMPAIGN_IDENTIFIER | $SED -e 's/\.csv$//'`
    echo "CSVFILE: $CSVFILE"
    echo "CAMPAIGN_IDENTIFIER: $CAMPAIGN_IDENTIFIER"

    headers=( )
    items=( )
    OLD_IFS="$IFS"
    while IFS=',' read -r -a array; do
      if [ ${#headers[@]} -eq 0 ]; then
        echo "empty headers"
        for v in "${array[@]}"
        do
          echo "h:$v"
          headers+=( "$v" )
        done
      else
        for v in "${array[@]}"
        do
          echo "e:$v"
          items+=( "$v" )
        done 
      fi
      #  printf -v item '{"user":"%s","templateVars":{"%s": "%s"}}' "$lat" "$long" "$pos"
      #  items+=( "$item" )
      echo "------------"
    done <$CSVFILE
    IFS="$OLD_IFS"

    headers_count="${#headers[@]}"
    messages=( )
    line_items=( )
    for itemIndex in "${!items[@]}"; do
    # for headerIndex in "${!headers[@]}"; do 
    #   printf "%s\t%s\n" "$index" "${headers[$index]}"
    # done
      if ! ((itemIndex % $headers_count)) ; then
        if [ ${#line_items[@]} -gt 0 ]; then
          vars=( )
          echo "=================="
          for proutIndex in "${!line_items[@]}"; do
            echo "\"${headers[$proutIndex]}\":\"${line_items[$proutIndex]}\""
            vars+=( "\"${headers[$proutIndex]}\":\"${line_items[$proutIndex]}\"" )
          done
          fullVars="$(join_by , ${vars[@]})"
          echo "=================="
          printf -v msg "{\"user\":\"%s\",\"templateVars\":{%s}}" "gni" "$fullVars"
          messages+=( "$msg" )
          line_items=( )
        fi
      else
        line_items+=( "${items[$itemIndex]}" )
      fi
    done

    printf '{"campaignKey": [%s],"messages":[%s]}\n' "$CAMPAIGN_IDENTIFIER" "${messages[*]}"
    echo "=========================="
    echo "Here's the header"
    for h in "${headers[@]}"
    do
      echo "$h"
    done
  else
    echo "params"
  fi
}

function login {
  FA_USER="`echo $ARG2`"
  echo "Login into $FA_API"
  echo
  echo "Password for $FA_USER:"
  read -s FA_PWD
  echo
  echo "Your token:"
  
  CMD="`build_curl`"
  eval $CMD

  exit 0
}

if [ $COMMAND = "login" ]; then
  login
elif [ $COMMAND = 'csv2json' ]; then
  csv2json
else
  banner
fi
