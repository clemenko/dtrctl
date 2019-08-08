#!/bin/bash
set -e

source ./conf.env 

######  NO MOAR EDITS #######
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
NORMAL=$(tput sgr0)
BLUE=$(tput setaf 4)

#better error checking
command -v curl >/dev/null 2>&1 || { echo "$RED" " ** Curl was not found. Please install before preceeding. ** " "$NORMAL" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "$RED" " ** Jq was not found. Please install before preceeding. ** " "$NORMAL" >&2; exit 1; }

getorgs () {
echo -- get --

if [ -d INFO ]; then
  echo "$RED" "Warning - orgList already detected..." 
  echo "$RED" " Please delete INFO/ if you want to start over." "$NORMAL"
  exit
else mkdir INFO
fi

#get ucp access token
 echo -n " getting an auth token "
 token=$(curl -sk -d '{"username":"'$SRC_USER'","password":"'$SRC_PASSWORD'"}' https://$SRC_UCP_URL/auth/login | jq -r .auth_token) > /dev/null 2>&1
 echo "$GREEN" "[ok]" "$NORMAL"

#get orgs
 echo -n " getting orgList "
 curl -skX GET "https://$SRC_UCP_URL/accounts/?filter=all&limit=10000" -H "accept: application/json" -H "Authorization: Bearer $token" | jq -rc '.accounts[] | select(.isOrg==true) | .name' | sed -e '/docker-datacenter/d' > INFO/orgList
 echo "$GREEN" "[ok]" "$NORMAL"

#get teams of orgs
 echo -n " getting teams of orgs "
 for i in $(cat INFO/orgList ); do 
     eval=$(curl -skX GET "https://$SRC_UCP_URL/accounts/$i/teams?filter=all&limit=10000" -H "accept: application/json" -H "Authorization: Bearer $token" | jq -rc '..|select(type == "array" and length > 0) | .[].name' | sed 's/ /%20/g')
    if [ ! -z "$eval" ]; then echo "$eval" > INFO/teams_"$i" ; fi 
 done
 echo "$GREEN" "[ok]" "$NORMAL"

#get memebrs of teams
 echo -n " getting users of teams "
 for i in $(ls INFO|grep teams|sed 's/teams_//g'); do 
   for j in $(cat INFO/teams_$i); do
    eval=$(curl -skX GET "https://$SRC_UCP_URL/accounts/$i/teams/$j/members?filter=all&limit=10000" -H "accept: application/json" -H "Authorization: Bearer $token" | jq -rc '..|select(type == "array" and length > 0) | .[].member.name') 
    if [ ! -z "$eval" ]; then echo "$eval" > INFO/members_"$i"ZZZ"$j" ; fi 
   done
 done
 echo "$GREEN" "[ok]" "$NORMAL"

}

pushorgs () {
echo -- push --

#get ucp access token
echo -n " getting an auth token "
 token=$(curl -sk -d '{"username":"'$DST_USER'","password":"'$DST_PASSWORD'"}' https://$DST_UCP_URL/auth/login | jq -r .auth_token) > /dev/null 2>&1
 echo "$GREEN" "[ok]" "$NORMAL"

#create orgs
 echo -n " creating orgs "
 for ORG in $(cat INFO/orgList ); do 
   curl -skX POST https://$DST_UCP_URL/accounts -H  "accept: application/json" -H  "Authorization: Bearer $token" -H  "content-type: application/json" -d '{  "fullName": "'$ORG'", "isActive": true,  "isAdmin": false,  "isOrg": true,  "name": "'$ORG'", "searchLDAP": false}'  > /dev/null 2>&1
 done
 echo "$GREEN" "[ok]" "$NORMAL"

#create teams and adding users
 echo -n " creating teams and adding users "
for ORG in $(cat INFO/orgList); do
  if [ -f INFO/teams_$ORG ]; then
    for TEAM in $(cat INFO/teams_$ORG); do 
      curl -skX POST https://$DST_UCP_URL/accounts/$ORG/teams -H "Authorization: Bearer $token" -H 'Accept: application/json, text/plain, */*' -H 'Accept-Language: en-US,en;q=0.5' --compressed -H 'Content-Type: application/json;charset=utf-8' -d '{ "description": "'$TEAM'", "name": "'$TEAM'"}'  > /dev/null 2>&1
      if [ -f INFO/members_$ORG"ZZZ"$TEAM ]; then
       for USER in $(cat INFO/members_$ORG"ZZZ"$TEAM); do
         curl -skX PUT https://$DST_UCP_URL/accounts/$ORG/teams/$TEAM/members/$USER -H  "accept: application/json" -H  "Authorization: Bearer $token" -H  "content-type: application/json" -d '{}' > /dev/null 2>&1
       done
      fi
    done
  fi
done
echo "$GREEN" "[ok]" "$NORMAL"
}

case "$1" in
        get) getorgs;;
        push) pushorgs;;
        *) echo "Usage: $0 {get|push}"; exit 1
esac