#!/bin/sh
#
##
## Followanalytics transactional pushes
## ------------------------------------
## 
## fa_transac.sh login USER -
##   login into FA SSO, retrieve your FA_TOKEN (password read from STDIN)
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

banner() {
  echo "banner() / $0"
  echo "`grep -e '^##' $0 | sed -e s/##//g `"
}

login_json() {
  LOGIN_JSON="{\"email\": \"$FA_USER\", \"password\": \"$FA_PWD\"}"
  echo "$LOGIN_JSON"
}
build_curl() {
  JSON="`login_json`"
  echo "$CURL -s -H 'Accept: application/json' -H 'Content-Type: application/json' -d '$JSON' $FA_LOGIN | $SED -n '$CAPTURE_TOKEN'"
}
login() {
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
else
  banner
fi
