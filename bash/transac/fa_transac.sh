#!/bin/bash
#
##
## Followanalytics transactional pushes
## ------------------------------------
## 
## fa_transac.sh login USER_IDENTIFIER
##   login USER_IDENTIFIER into FA SSO, retrieve your AUTH_TOKEN (password read from STDIN)
##
## fa_transac.sh csv2json CAMPAIGN_IDENTIFIER.csv
##   convert csv named as campaign_identifier, to a ready to push json file
##   The CSV first line MUST be "user", then the variables keynames 
##
## fa_transac.sh push AUTH_TOKEN -
##   push transac messages defined in json on STDIN using AUTH_TOKEN as identification
##
## Note: commands needed in PATH: which, sed, curl


COMMAND="`echo $1 | tr '[:upper:]' '[:lower:]'`"

ARG2="`echo $2`"

CURL=`which curl`
SED=`which sed`

FA_API='https://api.follow-apps.com'
FA_LOGIN="$FA_API/api/login"
FA_PUSH="$FA_API/api/transac"

CAPTURE_TOKEN='s/^.*auth_token":"\([-_a-zA-Z0-9]*\).*$/\1/p'

function join_by { local IFS="$1"; shift; echo "$*"; }
function banner {
  echo "`grep -e '^##' $0 | sed -e s/##//g `"
}

function login_json {
  LOGIN_JSON="{\"email\": \"$FA_USER\", \"password\": \"$FA_PWD\"}"
  echo "$LOGIN_JSON"
}
function build_curl {
  JSON="$1"
  CURL_URL="$2"
  COMPLEMENT="$3"
  if [ -z $AUTH_TOKEN ]; then
    AUTH_HEADER=""
  else
    AUTH_HEADER=" -H 'Authorization: Token $AUTH_TOKEN'"
  fi
  # -w "\n" is here to force curl to output the json response, which doesn't have linefeed for now
  echo "$CURL -s -w \"\n\" -H 'Accept: application/json' -H 'Content-Type: application/json; charset=utf-8'$AUTH_HEADER -d '$JSON' $CURL_URL $COMPLEMENT"
}

function csv2json {
  CAMPAIGN_IDENTIFIER="`echo $ARG2`"
  if [ -f $CAMPAIGN_IDENTIFIER ]; then
    CSVFILE=$CAMPAIGN_IDENTIFIER
    CAMPAIGN_IDENTIFIER=`echo $CAMPAIGN_IDENTIFIER | $SED -e 's/\.csv$//'`

    headers=( )
    items=( )
    OLD_IFS="$IFS"
    while IFS=',' read -r -a array; do
      if [ ${#headers[@]} -eq 0 ]; then
        for v in "${array[@]}"
        do
          headers+=( "$v" )
        done
      else
        for v in "${array[@]}"
        do
          items+=( "$v" )
        done 
      fi
    done <$CSVFILE
    IFS="$OLD_IFS"

    headers_count="${#headers[@]}"
    messages=( )
    line_items=( )
    for itemIndex in "${!items[@]}"; do
      innerIndex=$((itemIndex % headers_count))
      if ! (( ((itemIndex + 1)) % $headers_count)) ; then
        if [ ${#line_items[@]} -gt 0 ]; then
          vars=( )
          line_items+=( "${items[itemIndex]}" )
          varCount=${#line_items[@]}
          for proutIndex in "${!line_items[@]}"; do
            if (( proutIndex < (varCount - 1) )); then
              vars+=( "\"${headers[proutIndex + 1]}\":\"${line_items[proutIndex+1]}\"" )
            fi
          done
          fullVars="$(join_by , "${vars[@]}")"
          printf -v msg "{\"user\":\"%s\",\"templateVars\":{%s}}" "${line_items[0]}" "$(join_by , "${fullVars[@]}")"
          messages+=( "$msg" )
          line_items=( )
        fi
      else
        line_items+=( "${items[itemIndex]}" )
      fi
    done

    printf '{"campaignKey":[\"%s\"],"messages":[%s]}\n' "$CAMPAIGN_IDENTIFIER" "$(join_by , "${messages[@]}")"
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
  
  ALTERATION="| $SED -n '$CAPTURE_TOKEN'"
  
  JSON="`login_json`"
  CMD="`build_curl "$JSON" "$FA_LOGIN" "$ALTERATION"`"
  echo
  echo "Executing:"
  echo "$CMD"
  echo
  echo "Your token:"
  eval $CMD

  exit 0
}

function push {
  AUTH_TOKEN="`echo $ARG2`"
  JSON=`cat /dev/stdin`
  CMD="`build_curl "$JSON" "$FA_PUSH"`"
  echo
  echo "Executing:"
  echo "$CMD"
  echo
  eval $CMD

  exit 0
}

if [ "$COMMAND" = "login" ]; then
  login
elif [ "$COMMAND" = 'csv2json' ]; then
  csv2json
elif [ "$COMMAND" = 'push' ]; then
  push
else
  banner
fi
